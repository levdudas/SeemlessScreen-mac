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

    // BUG FIX: Configure the layer here, not in init.
    // In init, wantsLayer=true hasn't created the layer yet, so layer? is nil.
    override func makeBackingLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = .resizeAspect
        layer.backgroundColor = NSColor.black.cgColor
        return layer
    }

    override var wantsUpdateLayer: Bool { true }

    func bind(to framePublisher: PassthroughSubject<CGImage, Never>) {
        cancellable = framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cgImage in
                guard let self else { return }
                self.layer?.contents = cgImage
            }
    }
}
