import Carbon
import AppKit

@MainActor
final class HotkeyService {
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onToggle: (() -> Void)?

    // Default: Cmd + Shift + S
    private(set) var modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    private(set) var keyCode: UInt32 = UInt32(kVK_ANSI_S)

    private static var shared: HotkeyService?

    func register(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        HotkeyService.shared = self

        // Load saved hotkey
        if UserDefaults.standard.object(forKey: "hotkeyModifiers") != nil {
            modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
            keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotkeyKeyCode"))
        }

        registerHotkey()
    }

    func updateHotkey(modifiers: UInt32, keyCode: UInt32) {
        unregisterHotkey()
        self.modifiers = modifiers
        self.keyCode = keyCode

        UserDefaults.standard.set(Int(modifiers), forKey: "hotkeyModifiers")
        UserDefaults.standard.set(Int(keyCode), forKey: "hotkeyKeyCode")

        registerHotkey()
    }

    func unregister() {
        unregisterHotkey()
        onToggle = nil
        HotkeyService.shared = nil
    }

    private func registerHotkey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                Task { @MainActor in
                    HotkeyService.shared?.onToggle?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        let hotkeyID = EventHotKeyID(
            signature: OSType(0x5353_4B59), // "SSKY"
            id: 1
        )

        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if regStatus != noErr {
            print("Failed to register hotkey: \(regStatus)")
        }
    }

    private func unregisterHotkey() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    // MARK: - Display helpers

    var shortcutDisplayString: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    private func keyCodeToString(_ code: UInt32) -> String {
        switch Int(code) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        default: return "?"
        }
    }
}
