import AppKit

extension NSImage {
    convenience init?(cgImage: CGImage) {
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        self.init(cgImage: cgImage, size: size)
    }
}
