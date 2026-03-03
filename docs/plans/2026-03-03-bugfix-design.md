# SeemlessScreen Bug Fix Design

## Problem

The app renders correctly on the local screen but Zoom/Teams/Meet capture a stale/frozen frame. Additionally, several smaller bugs affect usability.

## Root Cause

`CaptureLayerView` sets `CALayer.contents = cgImage` which updates via the GPU compositing path. Zoom and other screen-sharing apps capture the window's backing store from WindowServer, and GPU-only layer updates don't reliably flush to that backing store.

## Fixes

### Fix 1: CaptureLayerView — Force backing store flush (Critical)

**Problem:** `layer.contents = cgImage` doesn't trigger a window backing store update visible to Zoom.

**Solution:** After setting `layer.contents`, call `self.needsDisplay = true` followed by `self.displayIfNeeded()` to force the view to mark itself as dirty and flush to the backing store. Alternatively, override `updateLayer()` to set contents there, since the view already returns `wantsUpdateLayer = true`.

**File:** `CaptureLayerView.swift`

### Fix 2: showsCursor UserDefaults hookup

**Problem:** `SettingsView` writes `showCursor` to UserDefaults but `ScreenCaptureService.makeConfiguration` always hardcodes `config.showsCursor = true`.

**Solution:** Read `UserDefaults.standard.bool(forKey: "showCursor")` in `makeConfiguration`. Default to `true` when key is absent.

**File:** `ScreenCaptureService.swift`

### Fix 3: Window identity by CGWindowID

**Problem:** `WindowPickerView` compares `capturedWindowTitle == window.title` to show the "Sharing" badge. Two windows with the same title (e.g., two Chrome tabs) break this.

**Solution:** Store `capturedWindowID: CGWindowID?` on `AppState` instead of (or alongside) `capturedWindowTitle`. Compare by ID.

**Files:** `AppState.swift`, `WindowPickerView.swift`

### Fix 4: Shared thumbnail service

**Problem:** `WindowThumbnailView.loadThumbnail()` creates a new `WindowEnumerationService()` per cell.

**Solution:** Accept the service as a parameter from the parent view, using the shared instance from `AppState`.

**Files:** `WindowThumbnailView.swift`, `WindowPickerView.swift`

### Fix 5: Permission check robustness

**Problem:** `PermissionService.checkPermission()` returns `.denied` if the user has permission but zero windows are open.

**Solution:** Use `CGPreflightScreenCaptureAccess()` (macOS 14+) as the primary check, falling back to the current approach.

**File:** `PermissionService.swift`

### Fix 6: App termination cleanup

**Problem:** `cleanup()` is only called from the Quit menu button, not when the app is terminated externally.

**Solution:** Add an `NSApplication.willTerminateNotification` observer in `AppState.setup()`.

**File:** `AppState.swift`

### Fix 7: Version from bundle

**Problem:** Version is hardcoded as `"1.0.0"`.

**Solution:** Read from `Bundle.main.infoDictionary`.

**File:** `SettingsView.swift`
