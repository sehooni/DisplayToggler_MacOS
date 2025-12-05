import Cocoa
import Carbon

@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    
    private init() {}
    
    func registerHotKey() {
        // Register Cmd + Option + Control + D
        // Cmd = cmdKey
        // Option = optionKey
        // Control = controlKey
        // D = 2 (Virtual key code for D)
        
        let modifiers = UInt32(cmdKey | optionKey | controlKey)
        let keyCode = UInt32(kVK_ANSI_D)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1163413075) // 'Disp'
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("Global Hotkey registered: Cmd + Option + Control + D")
            
            // Install event handler
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
                print("Hotkey pressed!")
                Task { @MainActor in
                    DisplayManager.shared.toggleMirroring()
                }
                return noErr
            }, 1, &eventType, nil, nil)
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }
}
