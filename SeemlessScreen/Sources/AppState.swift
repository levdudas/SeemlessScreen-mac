import SwiftUI
import ScreenCaptureKit
import Combine

@Observable
@MainActor
final class AppState {
    // Services
    let captureService = ScreenCaptureService()
    let windowEnumerationService = WindowEnumerationService()
    let hotkeyService = HotkeyService()
    let activeWindowTracker = ActiveWindowTracker()
    let permissionService = PermissionService()

    // State
    var isCapturing = false
    var isPickerVisible = false
    var activeWindowMode = false
    var capturedWindowTitle = ""
    var availableWindows: [CaptureableWindow] = []
    var permissionState: PermissionService.PermissionState = .unknown

    // Windows
    private var sharedSurfaceController: SharedSurfaceWindowController?
    private var pickerPanel: WindowPickerPanel?
    private var cancellables = Set<AnyCancellable>()

    init() {
        SingleInstanceGuard.check()
        setup()
    }

    private func setup() {
        Task {
            permissionState = await permissionService.checkPermission()
            if permissionState == .granted {
                initializeUI()
            }
        }
    }

    private func initializeUI() {
        // Create shared surface window
        sharedSurfaceController = SharedSurfaceWindowController(
            framePublisher: captureService.framePublisher
        )
        sharedSurfaceController?.showWindow()

        // Create picker panel
        pickerPanel = WindowPickerPanel(appState: self)

        // Register hotkey
        hotkeyService.register { [weak self] in
            Task { @MainActor in
                self?.togglePicker()
            }
        }

        // Active window tracker
        activeWindowTracker.onActiveWindowChanged = { [weak self] app in
            guard let self, self.activeWindowMode else { return }
            Task { @MainActor in
                await self.handleActiveWindowChanged(app)
            }
        }
    }

    func togglePicker() {
        guard permissionState == .granted else {
            permissionService.openScreenRecordingSettings()
            return
        }

        if pickerPanel == nil {
            initializeUI()
        }

        if isPickerVisible {
            hidePicker()
        } else {
            showPicker()
        }
    }

    private func showPicker() {
        Task {
            await refreshWindows()
            pickerPanel?.makeKeyAndOrderFront(nil)
            pickerPanel?.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            isPickerVisible = true
        }
    }

    private func hidePicker() {
        pickerPanel?.orderOut(nil)
        isPickerVisible = false
    }

    func selectWindow(_ window: CaptureableWindow) {
        // Disable active window mode when manually selecting
        if activeWindowMode {
            activeWindowMode = false
            activeWindowTracker.stop()
        }

        startCapturing(window)
        hidePicker()
    }

    private func startCapturing(_ window: CaptureableWindow) {
        Task {
            do {
                if isCapturing {
                    try await captureService.switchWindow(window)
                } else {
                    try await captureService.startCapture(window: window)
                }
                isCapturing = true
                capturedWindowTitle = window.title

                sharedSurfaceController?.resizeToFit(window.frame.size)
            } catch {
                print("Capture error: \(error)")
            }
        }
    }

    func stopCapture() {
        Task {
            await captureService.stopCapture()
            isCapturing = false
            capturedWindowTitle = ""
        }
    }

    func showSharedSurface() {
        if sharedSurfaceController == nil {
            initializeUI()
        }
        sharedSurfaceController?.showWindow()
    }

    func setActiveWindowMode(_ enabled: Bool) {
        activeWindowMode = enabled
        if enabled {
            activeWindowTracker.start()
        } else {
            activeWindowTracker.stop()
        }
    }

    func refreshWindows() async {
        do {
            let windows = try await windowEnumerationService.getCapturableWindows()
            availableWindows = windows
        } catch {
            print("Failed to enumerate windows: \(error)")
        }
    }

    private func handleActiveWindowChanged(_ app: NSRunningApplication) async {
        // BUG FIX: removed `guard isCapturing` — Active Window Mode should start
        // capturing automatically, even if no window was manually selected first.
        guard let scWindow = await activeWindowTracker.frontmostWindow(of: app) else { return }
        let window = CaptureableWindow(from: scWindow)
        do {
            if isCapturing {
                try await captureService.switchWindow(window)
            } else {
                try await captureService.startCapture(window: window)
            }
            isCapturing = true
            capturedWindowTitle = window.title
            sharedSurfaceController?.resizeToFit(window.frame.size)
        } catch {
            print("Active window switch error: \(error)")
        }
    }

    func cleanup() {
        hotkeyService.unregister()
        activeWindowTracker.stop()
        Task {
            await captureService.stopCapture()
        }
        sharedSurfaceController?.close()
        pickerPanel?.close()
    }
}
