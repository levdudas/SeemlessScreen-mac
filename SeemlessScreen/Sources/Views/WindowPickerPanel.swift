import AppKit
import SwiftUI

@MainActor
final class WindowPickerPanel: NSPanel {
    init(appState: AppState) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        title = "SeemlessScreen - Window Picker"
        isFloatingPanel = true
        level = .floating
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        minSize = NSSize(width: 400, height: 300)

        center()

        let hostingView = NSHostingView(
            rootView: WindowPickerView(appState: appState)
        )
        contentView = hostingView
    }

    var windowID: CGWindowID {
        CGWindowID(windowNumber)
    }
}
