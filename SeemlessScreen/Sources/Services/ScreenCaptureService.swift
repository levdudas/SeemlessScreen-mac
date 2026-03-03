import ScreenCaptureKit
import CoreMedia
import CoreImage
import Combine

final class ScreenCaptureService: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var currentFilter: SCContentFilter?
    private let videoQueue = DispatchQueue(
        label: "com.seemlessscreen.videoQueue",
        qos: .userInteractive
    )

    // Publish CGImage (guaranteed to render as CALayer.contents on macOS)
    let framePublisher = PassthroughSubject<CGImage, Never>()

    // GPU-accelerated image conversion
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

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
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30fps is plenty for screen sharing
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.queueDepth = 3
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

        // BUG FIX: Use String keys — the CF dictionary does NOT bridge to SCStreamFrameInfo keys
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer, createIfNecessary: false
        ) as? [[String: Any]],
              let statusRaw = attachmentsArray.first?[SCStreamFrameInfo.status.rawValue] as? Int,
              let status = SCFrameStatus(rawValue: statusRaw),
              status == .complete else {
            return
        }

        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }

        // BUG FIX: Convert to CGImage — IOSurface as CALayer.contents is unreliable on macOS.
        // CIContext uses GPU internally, so this is hardware-accelerated.
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        framePublisher.send(cgImage)
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
