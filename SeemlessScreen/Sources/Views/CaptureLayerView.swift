import AppKit
import Combine

final class CaptureLayerView: NSView {
    private var cancellable: AnyCancellable?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }

    func bind(to framePublisher: PassthroughSubject<CGImage, Never>) {
        cancellable = framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cgImage in
                guard let self, let layer = self.layer else { return }
                layer.contents = cgImage
                // Force the window to flush its backing store so WindowServer
                // (and thus Zoom/Teams) sees the updated content.
                self.window?.displayIfNeeded()
            }
    }
}
