import AppKit
import Combine

final class CaptureLayerView: NSView {
    private var cancellable: AnyCancellable?
    private var pendingImage: CGImage?

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

    override var wantsUpdateLayer: Bool { true }

    // Called by AppKit when needsDisplay is true — this flushes to the backing store.
    override func updateLayer() {
        layer?.contents = pendingImage
    }

    func bind(to framePublisher: PassthroughSubject<CGImage, Never>) {
        cancellable = framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cgImage in
                guard let self else { return }
                self.pendingImage = cgImage
                self.needsDisplay = true
                self.displayIfNeeded()
            }
    }
}
