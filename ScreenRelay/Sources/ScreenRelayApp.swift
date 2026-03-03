import SwiftUI

@main
struct ScreenRelayApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("ScreenRelay", systemImage: appState.isCapturing ? "rectangle.on.rectangle.fill" : "rectangle.on.rectangle") {
            MenuBarMenu(appState: appState)
        }

        Settings {
            SettingsView(appState: appState)
        }
    }
}

struct MenuBarMenu: View {
    @Bindable var appState: AppState

    var body: some View {
        if appState.permissionState == .denied {
            Button("Grant Screen Recording Permission...") {
                appState.permissionService.requestAccess()
            }
            Divider()
        }

        Button(appState.isPickerVisible ? "Hide Switcher" : "Show Switcher") {
            appState.togglePicker()
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])

        Divider()

        Toggle("Active Window Mode", isOn: Binding(
            get: { appState.activeWindowMode },
            set: { appState.setActiveWindowMode($0) }
        ))

        Divider()

        if appState.isCapturing {
            Text("Mirroring: \(appState.capturedWindowTitle)")
                .disabled(true)

            Button("Stop Mirroring") {
                appState.stopCapture()
            }

            Divider()
        }

        Button("Show Shared Surface") {
            appState.showSharedSurface()
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }

        Button("Quit") {
            appState.cleanup()
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
