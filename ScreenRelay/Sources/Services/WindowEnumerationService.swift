import ScreenCaptureKit

final class WindowEnumerationService: Sendable {
    func getCapturableWindows() async throws -> [CaptureableWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true, onScreenWindowsOnly: true
        )

        let ownBundleID = Bundle.main.bundleIdentifier ?? ""

        let windows = content.windows.compactMap { scWindow -> CaptureableWindow? in
            // Exclude our own app
            guard scWindow.owningApplication?.bundleIdentifier != ownBundleID else {
                return nil
            }
            // Must have a title
            guard let title = scWindow.title, !title.isEmpty else { return nil }
            // Filter tiny windows
            guard scWindow.frame.width > 50 && scWindow.frame.height > 50 else { return nil }
            // Only standard layer windows
            guard scWindow.windowLayer == 0 else { return nil }

            return CaptureableWindow(from: scWindow)
        }

        // Sort by window area (largest first)
        return windows.sorted { $0.frame.width * $0.frame.height > $1.frame.width * $1.frame.height }
    }

    func getThumbnail(
        for window: CaptureableWindow,
        size: CGSize = CGSize(width: 240, height: 160)
    ) async -> CGImage? {
        let filter = SCContentFilter(desktopIndependentWindow: window.scWindow)
        let config = SCStreamConfiguration()
        config.width = Int(size.width * 2)
        config.height = Int(size.height * 2)
        config.scalesToFit = true
        config.preservesAspectRatio = true
        config.showsCursor = false
        config.shouldBeOpaque = true

        do {
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return image
        } catch {
            return nil
        }
    }
}
