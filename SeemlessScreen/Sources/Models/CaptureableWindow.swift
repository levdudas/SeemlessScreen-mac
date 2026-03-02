import ScreenCaptureKit
import AppKit

struct CaptureableWindow: Identifiable, Hashable {
    let id: CGWindowID
    let title: String
    let appName: String
    let appBundleID: String
    let appIcon: NSImage?
    let frame: CGRect
    let isOnScreen: Bool
    let scWindow: SCWindow

    var thumbnail: CGImage?

    init(from scWindow: SCWindow) {
        self.id = scWindow.windowID
        self.title = scWindow.title ?? "Untitled"
        self.appName = scWindow.owningApplication?.applicationName ?? "Unknown"
        self.appBundleID = scWindow.owningApplication?.bundleIdentifier ?? ""
        self.appIcon = scWindow.owningApplication.flatMap { app in
            NSRunningApplication(processIdentifier: app.processID)?.icon
        }
        self.frame = scWindow.frame
        self.isOnScreen = scWindow.isOnScreen
        self.scWindow = scWindow
    }

    static func == (lhs: CaptureableWindow, rhs: CaptureableWindow) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
