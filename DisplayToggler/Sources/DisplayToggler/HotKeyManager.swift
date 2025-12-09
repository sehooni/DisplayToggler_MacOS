import Cocoa
import Carbon

@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    
    // IDs
    private let kMirrorToggleID = UInt32(1)
    
    // Window Management IDs
    private let kWindowLeftID = UInt32(2)
    private let kWindowRightID = UInt32(3)
    private let kWindowTopID = UInt32(4)
    private let kWindowBottomID = UInt32(5)
    private let kWindowMaximizeID = UInt32(6)
    
    // Display Arrangement IDs
    private let kDisplay1MainID = UInt32(7)
    private let kDisplay2MainID = UInt32(8)

    private init() {}
    
    func registerHotKey() {
        // Register Cmd + Option + Control + D (Toggle Mirroring)
        register(keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(cmdKey | optionKey | controlKey), id: kMirrorToggleID)
        
        // Window Management: Ctrl + Option + Arrow Keys / Enter
        register(keyCode: UInt32(kVK_LeftArrow), modifiers: UInt32(controlKey | optionKey), id: kWindowLeftID)
        register(keyCode: UInt32(kVK_RightArrow), modifiers: UInt32(controlKey | optionKey), id: kWindowRightID)
        register(keyCode: UInt32(kVK_UpArrow), modifiers: UInt32(controlKey | optionKey), id: kWindowTopID)
        register(keyCode: UInt32(kVK_DownArrow), modifiers: UInt32(controlKey | optionKey), id: kWindowBottomID)
        register(keyCode: UInt32(kVK_Return), modifiers: UInt32(controlKey | optionKey), id: kWindowMaximizeID)
        
        // Display Arrangement: Cmd + Option + Control + 1/2
        register(keyCode: UInt32(kVK_ANSI_1), modifiers: UInt32(cmdKey | optionKey | controlKey), id: kDisplay1MainID)
        register(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(cmdKey | optionKey | controlKey), id: kDisplay2MainID)
        // Also support Arrow Keys (Left -> 1, Right -> 2)
        register(keyCode: UInt32(kVK_LeftArrow), modifiers: UInt32(cmdKey | optionKey | controlKey), id: kDisplay1MainID)
        register(keyCode: UInt32(kVK_RightArrow), modifiers: UInt32(cmdKey | optionKey | controlKey), id: kDisplay2MainID)
        
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr {
                Task { @MainActor in
                    HotKeyManager.shared.handleHotKey(id: hotKeyID.id)
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
    
    private func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1163413075) // 'Disp'
        hotKeyID.id = id
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            hotKeyRefs[id] = hotKeyRef
            print("Registered hotkey ID: \(id)")
        } else {
            print("Failed to register hotkey ID: \(id), status: \(status)")
        }
    }
    
    func handleHotKey(id: UInt32) {
        print("Handling Hotkey ID: \(id)")
        switch id {
        case kMirrorToggleID:
            DisplayManager.shared.toggleMirroring()
        case kWindowLeftID:
            WindowManager.shared.moveFocusedWindow(to: .leftHalf)
        case kWindowRightID:
            WindowManager.shared.moveFocusedWindow(to: .rightHalf)
        case kWindowTopID:
            WindowManager.shared.moveFocusedWindow(to: .topHalf)
        case kWindowBottomID:
            WindowManager.shared.moveFocusedWindow(to: .bottomHalf)
        case kWindowMaximizeID:
            WindowManager.shared.moveFocusedWindow(to: .maximize)
        case kDisplay1MainID:
            DisplayManager.shared.setMainDisplay(index: 0)
        case kDisplay2MainID:
            DisplayManager.shared.setMainDisplay(index: 1)
        default:
            break
        }
    }
}
