import AppKit
import ScreenCaptureKit

@MainActor
final class ActiveWindowTracker {
    private var observation: NSObjectProtocol?
    var onActiveWindowChanged: ((NSRunningApplication) -> Void)?

    func start() {
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else { return }

            // Ignore our own app
            guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }

            MainActor.assumeIsolated {
                self?.onActiveWindowChanged?(app)
            }
        }
    }

    func stop() {
        if let observation {
            NSWorkspace.shared.notificationCenter.removeObserver(observation)
        }
        observation = nil
    }

    func frontmostWindow(of app: NSRunningApplication) async -> SCWindow? {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(
            true, onScreenWindowsOnly: true
        ) else {
            return nil
        }

        return content.windows.first { window in
            window.owningApplication?.processID == app.processIdentifier &&
            window.windowLayer == 0 &&
            window.isOnScreen
        }
    }
}
