import ScreenCaptureKit
import CoreMedia
import Combine

final class ScreenCaptureService: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var currentFilter: SCContentFilter?
    private let videoQueue = DispatchQueue(
        label: "com.seemlessscreen.videoQueue",
        qos: .userInteractive
    )

    let framePublisher = PassthroughSubject<IOSurface, Never>()

    private(set) var capturedWindow: CaptureableWindow?

    func startCapture(window: CaptureableWindow) async throws {
        await stopCapture()

        let filter = SCContentFilter(desktopIndependentWindow: window.scWindow)
        let config = makeConfiguration(for: window.frame.size)

        let newStream = SCStream(filter: filter, configuration: config, delegate: self)
        try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: videoQueue)
        try await newStream.startCapture()

        self.stream = newStream
        self.currentFilter = filter
        self.capturedWindow = window
    }

    func switchWindow(_ window: CaptureableWindow) async throws {
        guard let stream = self.stream else {
            try await startCapture(window: window)
            return
        }

        let newFilter = SCContentFilter(desktopIndependentWindow: window.scWindow)
        try await stream.updateContentFilter(newFilter)

        let config = makeConfiguration(for: window.frame.size)
        try await stream.updateConfiguration(config)

        self.currentFilter = newFilter
        self.capturedWindow = window
    }

    func stopCapture() async {
        if let stream = self.stream {
            try? await stream.stopCapture()
        }
        self.stream = nil
        self.currentFilter = nil
        self.capturedWindow = nil
    }

    private func makeConfiguration(for size: CGSize) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        let scale: CGFloat = 2.0 // Retina
        config.width = Int(max(size.width, 320) * scale)
        config.height = Int(max(size.height, 240) * scale)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.queueDepth = 5
        config.showsCursor = true
        config.scalesToFit = true
        config.preservesAspectRatio = true
        config.shouldBeOpaque = true
        return config
    }
}

// MARK: - SCStreamOutput

extension ScreenCaptureService: SCStreamOutput {
    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }

        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer, createIfNecessary: false
        ) as? [[SCStreamFrameInfo: Any]],
              let statusRaw = attachmentsArray.first?[.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRaw),
              status == .complete else {
            return
        }

        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer) else { return }
        let surface = unsafeBitCast(surfaceRef, to: IOSurface.self)

        framePublisher.send(surface)
    }
}

// MARK: - SCStreamDelegate

extension ScreenCaptureService: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("SCStream stopped with error: \(error.localizedDescription)")
        Task { @MainActor in
            self.stream = nil
            self.currentFilter = nil
            self.capturedWindow = nil
        }
    }
}
