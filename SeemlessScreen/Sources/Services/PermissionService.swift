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
    func requestAccess() {
        // Triggers the native macOS permission dialog on first call.
        // On subsequent calls (if already denied), opens System Settings.
        CGRequestScreenCaptureAccess()
    }
}
