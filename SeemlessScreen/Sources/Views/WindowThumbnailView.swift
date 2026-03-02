import SwiftUI

struct WindowThumbnailView: View {
    let window: CaptureableWindow
    let isCurrentlySharing: Bool
    let onSelect: () -> Void

    @State private var thumbnail: NSImage?
    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Thumbnail
                ZStack {
                    Color.black

                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView()
                            .scaleEffect(0.6)
                    }

                    // "Sharing" badge
                    if isCurrentlySharing {
                        VStack {
                            HStack {
                                Spacer()
                                Text("Sharing")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isCurrentlySharing ? Color.green :
                                (isHovering ? Color.accentColor : Color.gray.opacity(0.3)),
                            lineWidth: isCurrentlySharing || isHovering ? 2 : 1
                        )
                )

                // Window info
                HStack(spacing: 4) {
                    if let icon = window.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(window.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(window.appName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let service = WindowEnumerationService()
        if let cgImage = await service.getThumbnail(for: window) {
            let size = NSSize(
                width: cgImage.width,
                height: cgImage.height
            )
            thumbnail = NSImage(cgImage: cgImage, size: size)
        }
    }
}
