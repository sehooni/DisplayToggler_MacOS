import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("DisplayToggler application started.")
        print("Attempting to create status item...")
        
        // Register Hotkey
        HotKeyManager.shared.registerHotKey()
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Force text first to ensure visibility
            button.title = "DisplayToggler"
            print("Status item created. Title set to 'DisplayToggler'.")
            
            // Try image
            let image = NSImage(systemSymbolName: "display", accessibilityDescription: "Display Toggler")
            if let img = image {
                button.image = img
                print("SF Symbol 'display' loaded successfully.")
            } else {
                print("Failed to load SF Symbol 'display'. Keeping text.")
            }
        } else {
            print("Failed to access statusItem.button")
        }
        
        constructMenu()
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        menu.addItem(NSMenuItem(title: "Status: Checking...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Mirror Displays", action: #selector(mirrorDisplays), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Extend Displays", action: #selector(extendDisplays), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        
        let arrangementMenu = NSMenu()
        arrangementMenu.addItem(NSMenuItem(title: "Left of Main", action: #selector(arrangeLeft), keyEquivalent: ""))
        arrangementMenu.addItem(NSMenuItem(title: "Right of Main", action: #selector(arrangeRight), keyEquivalent: ""))
        arrangementMenu.addItem(NSMenuItem(title: "Top of Main", action: #selector(arrangeTop), keyEquivalent: ""))
        arrangementMenu.addItem(NSMenuItem(title: "Bottom of Main", action: #selector(arrangeBottom), keyEquivalent: ""))
        
        let arrangementItem = NSMenuItem(title: "Arrangement", action: nil, keyEquivalent: "")
        arrangementItem.submenu = arrangementMenu
        menu.addItem(arrangementItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update status item
        if let item = menu.item(at: 0) {
            var displayCount: UInt32 = 0
            CGGetOnlineDisplayList(0, nil, &displayCount)
            item.title = "Status: \(displayCount) Display(s) Detected"
        }
    }
    
    @objc func mirrorDisplays() {
        print("Mirroring displays...")
        DisplayManager.shared.setMirroring(enabled: true)
    }
    
    @objc func extendDisplays() {
        print("Extending displays...")
        DisplayManager.shared.setMirroring(enabled: false)
    }
    
    @objc func arrangeLeft() {
        print("Arranging: Left")
        DisplayManager.shared.setArrangement(position: .left)
    }
    
    @objc func arrangeRight() {
        print("Arranging: Right")
        DisplayManager.shared.setArrangement(position: .right)
    }
    
    @objc func arrangeTop() {
        print("Arranging: Top")
        DisplayManager.shared.setArrangement(position: .top)
    }
    
    @objc func arrangeBottom() {
        print("Arranging: Bottom")
        DisplayManager.shared.setArrangement(position: .bottom)
    }
}
