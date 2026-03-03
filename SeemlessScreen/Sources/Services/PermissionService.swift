import AppKit

final class PermissionService: Sendable {
    enum PermissionState: Sendable {
        case unknown
        case granted
        case denied
    }

    func checkPermission() async -> PermissionState {
        // CGPreflightScreenCaptureAccess (macOS 14+) directly checks the TCC database
        // without requiring windows to be open.
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        return .denied
    }

    @MainActor
    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
