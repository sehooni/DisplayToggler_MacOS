import Cocoa
import Carbon

@MainActor
class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    private init() {}
    
    func registerHotKey() {
        // Remove existing monitors if any
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        
        logger.log("HotKeyManager: Registering NSEvent monitors.")
        
        // Global Monitor (When app is in background)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
        }
        
        // Local Monitor (When app is in foreground)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        // Check Modifiers: Cmd + Option + Control
        // NSEvent.ModifierFlags contains the flags. 
        // We want strict match or at least these three.
        // Usually hotkeys allow extra flags (like CapsLock), but let's check for containing these 3.
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let displayModifiers: NSEvent.ModifierFlags = [.command, .option, .control]
        let windowModifiers: NSEvent.ModifierFlags = [.control, .option]
        
        if flags.contains(displayModifiers) {
            // Display Management (Cmd + Opt + Ctrl)
            switch event.keyCode {
            case 2: // D
                 logger.log("HotKeyManager: Hotkey D (Mirror) detected.")
                 DisplayManager.shared.toggleMirroring()
                 
            case 18, 123: // 1 or Left Arrow
                 logger.log("HotKeyManager: Hotkey 1/Left (Display 1 Main) detected.")
                 DisplayManager.shared.setMainDisplay(index: 0)
                 
            case 19, 124: // 2 or Right Arrow
                 logger.log("HotKeyManager: Hotkey 2/Right (Display 2 Main) detected.")
                 DisplayManager.shared.setMainDisplay(index: 1)
                 
            default:
                 break
            }
        } else if flags.contains(windowModifiers) && !flags.contains(.command) {
            // Window Management (Ctrl + Opt, NO Cmd)
             switch event.keyCode {
             case 123: // Left
                 WindowManager.shared.moveFocusedWindow(to: .leftHalf)
             case 124: // Right
                 WindowManager.shared.moveFocusedWindow(to: .rightHalf)
             case 126: // Up
                 WindowManager.shared.moveFocusedWindow(to: .topHalf)
             case 125: // Down
                 WindowManager.shared.moveFocusedWindow(to: .bottomHalf)
             case 36: // Return
                 WindowManager.shared.moveFocusedWindow(to: .maximize)
             default:
                 break
             }
        }
    }
}
