# SeemlessScreen Bug Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the critical rendering bug that prevents Zoom/Teams from seeing frame updates, plus 6 smaller bugs.

**Architecture:** All fixes are localized edits to existing files. No new files, no new dependencies. The critical fix changes how `CaptureLayerView` pushes frames to ensure the window backing store is flushed for WindowServer capture.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, ScreenCaptureKit, macOS 14+

---

### Task 1: Fix CaptureLayerView backing store flush (Critical)

**Files:**
- Modify: `SeemlessScreen/Sources/Views/CaptureLayerView.swift`

**Why:** `CALayer.contents = cgImage` updates via GPU compositing but doesn't flush to the window backing store. Zoom/Teams read the backing store via WindowServer, so they see stale frames.

**Step 1: Modify the frame sink to store pending image and trigger display cycle**

Replace the entire `CaptureLayerView.swift` with:

```swift
import AppKit
import Combine

final class CaptureLayerView: NSView {
    private var cancellable: AnyCancellable?
    private var pendingImage: CGImage?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }

    override var wantsUpdateLayer: Bool { true }

    // Called by AppKit when needsDisplay is true — this flushes to the backing store.
    override func updateLayer() {
        layer?.contents = pendingImage
    }

    func bind(to framePublisher: PassthroughSubject<CGImage, Never>) {
        cancellable = framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cgImage in
                guard let self else { return }
                self.pendingImage = cgImage
                self.needsDisplay = true
                self.displayIfNeeded()
            }
    }
}
```

The key change: instead of setting `layer.contents` directly, we store the image in `pendingImage`, mark the view as needing display, and force it to display. AppKit calls `updateLayer()` which sets `layer.contents` as part of the display cycle, ensuring the backing store is flushed and WindowServer sees the update.

**Step 2: Build to verify compilation**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/Views/CaptureLayerView.swift
git commit -m "fix: force backing store flush so Zoom/Teams see frame updates

Use updateLayer() display cycle instead of directly setting layer.contents,
ensuring WindowServer backing store is flushed for screen-sharing apps."
```

---

### Task 2: Wire showsCursor UserDefaults to stream config

**Files:**
- Modify: `SeemlessScreen/Sources/Services/ScreenCaptureService.swift:70`

**Why:** The Settings toggle writes `showCursor` to UserDefaults but `makeConfiguration` always hardcodes `showsCursor = true`.

**Step 1: Replace the hardcoded line**

In `ScreenCaptureService.swift`, change line 70:

```swift
// OLD:
config.showsCursor = true

// NEW:
let showCursor = UserDefaults.standard.object(forKey: "showCursor") as? Bool ?? true
config.showsCursor = showCursor
```

**Step 2: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/Services/ScreenCaptureService.swift
git commit -m "fix: wire showsCursor toggle to stream configuration

Read showCursor from UserDefaults instead of hardcoding true."
```

---

### Task 3: Use CGWindowID for sharing badge instead of title

**Files:**
- Modify: `SeemlessScreen/Sources/AppState.swift:19,120,133,174`
- Modify: `SeemlessScreen/Sources/Views/WindowPickerView.swift:86`

**Why:** Comparing by window title breaks when two windows have the same title (e.g., two Chrome tabs).

**Step 1: Add capturedWindowID to AppState**

In `AppState.swift`, after line 19 (`var capturedWindowTitle = ""`), add:

```swift
var capturedWindowID: CGWindowID?
```

**Step 2: Set capturedWindowID in startCapturing**

In `AppState.swift`, in `startCapturing(_:)`, after line 120 (`capturedWindowTitle = window.title`), add:

```swift
capturedWindowID = window.id
```

**Step 3: Clear capturedWindowID in stopCapture**

In `AppState.swift`, in `stopCapture()`, after line 133 (`capturedWindowTitle = ""`), add:

```swift
capturedWindowID = nil
```

**Step 4: Set capturedWindowID in handleActiveWindowChanged**

In `AppState.swift`, in `handleActiveWindowChanged(_:)`, after line 174 (`capturedWindowTitle = window.title`), add:

```swift
capturedWindowID = window.id
```

**Step 5: Update WindowPickerView to compare by ID**

In `WindowPickerView.swift`, change line 86:

```swift
// OLD:
isCurrentlySharing: appState.capturedWindowTitle == window.title

// NEW:
isCurrentlySharing: appState.capturedWindowID == window.id
```

**Step 6: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 7: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/AppState.swift SeemlessScreen/Sources/Views/WindowPickerView.swift
git commit -m "fix: identify shared window by CGWindowID instead of title

Prevents false matches when two windows have identical titles."
```

---

### Task 4: Use shared WindowEnumerationService for thumbnails

**Files:**
- Modify: `SeemlessScreen/Sources/Views/WindowThumbnailView.swift:3,6,87-88`
- Modify: `SeemlessScreen/Sources/Views/WindowPickerView.swift:84-88`

**Why:** Each thumbnail cell creates a new `WindowEnumerationService` instance. With 20 windows open, that's 20 concurrent `SCScreenshotManager.captureImage` calls.

**Step 1: Add windowEnumerationService property to WindowThumbnailView**

In `WindowThumbnailView.swift`, add a new property after `let onSelect: () -> Void` (line 6):

```swift
let windowEnumerationService: WindowEnumerationService
```

**Step 2: Update loadThumbnail to use the shared service**

In `WindowThumbnailView.swift`, replace the `loadThumbnail()` method (lines 87-96):

```swift
// OLD:
private func loadThumbnail() async {
    let service = WindowEnumerationService()
    if let cgImage = await service.getThumbnail(for: window) {
        let size = NSSize(
            width: cgImage.width,
            height: cgImage.height
        )
        thumbnail = NSImage(cgImage: cgImage, size: size)
    }
}

// NEW:
private func loadThumbnail() async {
    if let cgImage = await windowEnumerationService.getThumbnail(for: window) {
        let size = NSSize(
            width: cgImage.width,
            height: cgImage.height
        )
        thumbnail = NSImage(cgImage: cgImage, size: size)
    }
}
```

**Step 3: Pass windowEnumerationService from WindowPickerView**

In `WindowPickerView.swift`, update the `WindowThumbnailView` initializer (lines 84-89):

```swift
// OLD:
WindowThumbnailView(
    window: window,
    isCurrentlySharing: appState.capturedWindowID == window.id
) {
    appState.selectWindow(window)
}

// NEW:
WindowThumbnailView(
    window: window,
    isCurrentlySharing: appState.capturedWindowID == window.id,
    onSelect: { appState.selectWindow(window) },
    windowEnumerationService: appState.windowEnumerationService
)
```

**Step 4: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 5: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/Views/WindowThumbnailView.swift SeemlessScreen/Sources/Views/WindowPickerView.swift
git commit -m "fix: share single WindowEnumerationService across thumbnails

Avoids creating one service instance per thumbnail cell."
```

---

### Task 5: Use CGPreflightScreenCaptureAccess for permission check

**Files:**
- Modify: `SeemlessScreen/Sources/Services/PermissionService.swift:11-19`

**Why:** The current check returns `.denied` if the user has permission but zero windows are open, because it uses `content.windows.isEmpty` as a proxy.

**Step 1: Replace checkPermission implementation**

In `PermissionService.swift`, replace the `checkPermission()` method (lines 11-19):

```swift
// OLD:
func checkPermission() async -> PermissionState {
    do {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true, onScreenWindowsOnly: false
        )
        return content.windows.isEmpty ? .denied : .granted
    } catch {
        return .denied
    }
}

// NEW:
func checkPermission() async -> PermissionState {
    // CGPreflightScreenCaptureAccess (macOS 14+) directly checks the TCC database
    // without requiring windows to be open.
    if CGPreflightScreenCaptureAccess() {
        return .granted
    }
    return .denied
}
```

**Step 2: Clean up unused import**

In `PermissionService.swift`, remove `import ScreenCaptureKit` (line 1) since we no longer use `SCShareableContent`. Keep `import AppKit` (line 2) since `CGPreflightScreenCaptureAccess` comes from CoreGraphics which is re-exported by AppKit.

**Step 3: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 4: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/Services/PermissionService.swift
git commit -m "fix: use CGPreflightScreenCaptureAccess for permission check

The previous approach used window count as a proxy, which false-negatives
when the user has permission but no windows are open."
```

---

### Task 6: Hook cleanup into app termination

**Files:**
- Modify: `SeemlessScreen/Sources/AppState.swift:33-40`

**Why:** `cleanup()` only runs from the Quit menu button. If the app is terminated externally (Activity Monitor, `kill`, etc.), no cleanup runs.

**Step 1: Add termination observer in setup()**

In `AppState.swift`, add the observer at the beginning of `setup()`, before the existing Task:

```swift
private func setup() {
    // Ensure cleanup runs even if the app is terminated externally
    NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        self?.cleanup()
    }

    Task {
        permissionState = await permissionService.checkPermission()
        if permissionState == .granted {
            initializeUI()
        }
    }
}
```

**Step 2: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/AppState.swift
git commit -m "fix: hook cleanup into willTerminateNotification

Ensures resources are released when the app is killed externally."
```

---

### Task 7: Read version from bundle instead of hardcoding

**Files:**
- Modify: `SeemlessScreen/Sources/Views/SettingsView.swift:75`

**Why:** Version is hardcoded as `"1.0.0"`. Should read from the bundle.

**Step 1: Replace hardcoded version**

In `SettingsView.swift`, change line 75:

```swift
// OLD:
LabeledContent("Version", value: "1.0.0")

// NEW:
LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
```

**Step 2: Build to verify**

Run: `cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
cd /tmp/SeemlessScreen-mac
git add SeemlessScreen/Sources/Views/SettingsView.swift
git commit -m "fix: read version from bundle info dictionary

Replaces hardcoded '1.0.0' string."
```

---

## Verification

After all 7 tasks, do a clean build:

```bash
cd /tmp/SeemlessScreen-mac && xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' clean build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`

Then manually test:
1. Launch the app (Cmd+R in Xcode or run the built binary)
2. Start a Zoom call, share the "SeemlessScreen - Shared Surface" window
3. Pick a window from the picker — verify it appears in Zoom
4. Switch to a different window — verify Zoom updates
5. Toggle Active Window Mode — verify it follows foreground app
6. Toggle "Show Cursor" in Settings, verify cursor appears/disappears
7. Stop Mirroring — verify it stops in Zoom
