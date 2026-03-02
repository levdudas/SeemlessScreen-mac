import AppKit
import Combine

@MainActor
final class SharedSurfaceWindowController: NSWindowController {
    let captureView: CaptureLayerView

    init(framePublisher: PassthroughSubject<IOSurface, Never>) {
        let captureView = CaptureLayerView(frame: .zero)
        self.captureView = captureView

        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1280, height: 720),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "SeemlessScreen - Shared Surface"
        window.isReleasedWhenClosed = false
        window.contentView = captureView
        window.backgroundColor = .black
        window.minSize = NSSize(width: 320, height: 240)
        window.level = .normal
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        super.init(window: window)

        captureView.bind(to: framePublisher)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func resizeToFit(_ sourceSize: CGSize) {
        guard let window, sourceSize.width > 0 && sourceSize.height > 0 else { return }

        let aspectRatio = sourceSize.width / sourceSize.height
        let currentFrame = window.frame
        let newHeight = currentFrame.width / aspectRatio

        var newFrame = currentFrame
        newFrame.size.height = newHeight + (window.frame.height - (window.contentView?.frame.height ?? 0))
        window.setFrame(newFrame, display: true, animate: true)
        window.contentAspectRatio = sourceSize
    }
}
