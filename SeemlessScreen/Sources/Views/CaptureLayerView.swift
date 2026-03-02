import AppKit
import Combine

final class CaptureLayerView: NSView {
    private var cancellable: AnyCancellable?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsGravity = .resizeAspect
        layer?.backgroundColor = NSColor.black.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(to framePublisher: PassthroughSubject<IOSurface, Never>) {
        cancellable = framePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] surface in
                self?.layer?.contents = surface
            }
    }
}
