import SwiftUI

struct WindowPickerView: View {
    @Bindable var appState: AppState
    @State private var searchText = ""

    private var filteredWindows: [CaptureableWindow] {
        if searchText.isEmpty {
            return appState.availableWindows
        }
        return appState.availableWindows.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.appName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search windows...", text: $searchText)
                    .textFieldStyle(.plain)

                Spacer()

                Button {
                    Task { await appState.refreshWindows() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh window list")
            }
            .padding(10)

            Divider()

            // Status bar
            HStack {
                if appState.isCapturing {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Mirroring: \(appState.capturedWindowTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Circle()
                        .fill(.gray)
                        .frame(width: 8, height: 8)
                    Text("Not mirroring")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(filteredWindows.count) windows")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            // Window grid
            if filteredWindows.isEmpty {
                ContentUnavailableView(
                    "No Windows Found",
                    systemImage: "macwindow",
                    description: Text(searchText.isEmpty
                        ? "Open some windows to get started."
                        : "No windows match your search.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 280))
                    ], spacing: 12) {
                        ForEach(filteredWindows) { window in
                            WindowThumbnailView(
                                window: window,
                                isCurrentlySharing: appState.capturedWindowID == window.id,
                                onSelect: { appState.selectWindow(window) },
                                windowEnumerationService: appState.windowEnumerationService
                            )
                        }
                    }
                    .padding(12)
                }
            }

            // Footer
            Divider()

            HStack {
                Toggle("Active Window Mode", isOn: Binding(
                    get: { appState.activeWindowMode },
                    set: { appState.setActiveWindowMode($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer()

                if appState.isCapturing {
                    Button("Stop Mirroring") {
                        appState.stopCapture()
                    }
                    .controlSize(.small)
                }
            }
            .padding(10)
        }
        .frame(minWidth: 500, minHeight: 300)
        .task {
            await appState.refreshWindows()
        }
    }
}
