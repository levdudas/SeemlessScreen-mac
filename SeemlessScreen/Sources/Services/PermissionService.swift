import ScreenCaptureKit
import AppKit

final class PermissionService: Sendable {
    enum PermissionState: Sendable {
        case unknown
        case granted
        case denied
    }

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

    @MainActor
    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
