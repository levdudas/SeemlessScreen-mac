import AppKit

enum SingleInstanceGuard {
    @MainActor
    static func check() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.screenrelay.app"
        let runningApps = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleID
        )

        if runningApps.count > 1 {
            let otherInstance = runningApps.first { $0 != .current }
            otherInstance?.activate()
            NSApplication.shared.terminate(nil)
        }
    }
}
