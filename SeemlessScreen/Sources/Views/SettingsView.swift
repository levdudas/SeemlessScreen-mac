import SwiftUI
import Carbon

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var isRecording = false
    @State private var recordedShortcut = ""

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Toggle Picker:")
                    Spacer()
                    if isRecording {
                        Text("Press a key combo...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.fill.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text(appState.hotkeyService.shortcutDisplayString)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.fill.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Button(isRecording ? "Cancel" : "Record") {
                        isRecording.toggle()
                    }
                    .controlSize(.small)
                }
                .background(
                    ShortcutRecorderHelper(
                        isRecording: $isRecording,
                        hotkeyService: appState.hotkeyService
                    )
                )
            }

            Section("Capture") {
                Toggle("Show Cursor in Capture", isOn: .init(
                    get: { UserDefaults.standard.object(forKey: "showCursor") == nil || UserDefaults.standard.bool(forKey: "showCursor") },
                    set: { UserDefaults.standard.set($0, forKey: "showCursor") }
                ))
            }

            Section("Behavior") {
                Toggle("Active Window Mode", isOn: Binding(
                    get: { appState.activeWindowMode },
                    set: { appState.setActiveWindowMode($0) }
                ))
                Text("Automatically follow the frontmost window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                HStack {
                    Text("Screen Recording:")
                    Spacer()
                    if appState.permissionState == .granted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Open System Settings") {
                            appState.permissionService.openScreenRecordingSettings()
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                Text("Seamlessly switch which window is shared in video calls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
    }
}

// NSViewRepresentable to capture key events for shortcut recording
struct ShortcutRecorderHelper: NSViewRepresentable {
    @Binding var isRecording: Bool
    let hotkeyService: HotkeyService

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onShortcutRecorded = { modifiers, keyCode in
            Task { @MainActor in
                hotkeyService.updateHotkey(modifiers: modifiers, keyCode: keyCode)
                isRecording = false
            }
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.isRecordingEnabled = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class ShortcutRecorderNSView: NSView {
    var isRecordingEnabled = false
    var onShortcutRecorded: ((UInt32, UInt32) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecordingEnabled else {
            super.keyDown(with: event)
            return
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Require at least one modifier
        guard !flags.isEmpty, flags != .capsLock else { return }

        var carbonModifiers: UInt32 = 0
        if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }

        guard carbonModifiers != 0 else { return }

        onShortcutRecorded?(carbonModifiers, UInt32(event.keyCode))
    }
}
