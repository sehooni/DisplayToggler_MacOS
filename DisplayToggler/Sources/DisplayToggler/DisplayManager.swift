import Cocoa
import CoreGraphics

@MainActor
class DisplayManager {
    static let shared = DisplayManager()
    
    private init() {}
    
    func setMirroring(enabled: Bool) {
        var configRef: CGDisplayConfigRef?
        let error = CGBeginDisplayConfiguration(&configRef)
        
        guard error == .success, let config = configRef else {
            print("Error beginning display configuration: \(error)")
            return
        }
        
        if enabled {
            // Mirroring Mode
            // Get the main display
            let mainDisplay = CGMainDisplayID()
            
            // Get all online displays
            var displayCount: UInt32 = 0
            CGGetOnlineDisplayList(0, nil, &displayCount)
            
            var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
            CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
            
            for display in displays {
                if display != mainDisplay {
                    // Mirror this display to the main display
                    CGConfigureDisplayMirrorOfDisplay(config, display, mainDisplay)
                }
            }
        } else {
            // Extended Mode (Disable Mirroring)
            // Get all online displays
            var displayCount: UInt32 = 0
            CGGetOnlineDisplayList(0, nil, &displayCount)
            
            var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
            CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
            
            // We need to arrange them. A simple way is to place them side-by-side.
            // Main display at (0,0).
            // Secondary displays to the right.
            
            var currentX: Int32 = 0
            
            // Sort displays to have a consistent order, maybe by ID or just use the list
            // Ensure main display is processed first or handled specifically
            let mainDisplay = CGMainDisplayID()
            
            // Configure main display first at 0,0
            CGConfigureDisplayOrigin(config, mainDisplay, 0, 0)
            CGConfigureDisplayMirrorOfDisplay(config, mainDisplay, CGDirectDisplayID(0)) // Stop mirroring
            
            currentX += Int32(CGDisplayPixelsWide(mainDisplay))
            
            for display in displays {
                if display != mainDisplay {
                    CGConfigureDisplayMirrorOfDisplay(config, display, CGDirectDisplayID(0)) // Stop mirroring
                    CGConfigureDisplayOrigin(config, display, currentX, 0)
                    currentX += Int32(CGDisplayPixelsWide(display))
                }
            }
        }
        
        let completeError = CGCompleteDisplayConfiguration(config, .permanently)
        if completeError != .success {
            print("Error completing display configuration: \(completeError)")
        }
    }
    
    enum DisplayPosition {
        case left, right, top, bottom
    }
    
    func setArrangement(position: DisplayPosition) {
        var configRef: CGDisplayConfigRef?
        let error = CGBeginDisplayConfiguration(&configRef)
        
        guard error == .success, let config = configRef else {
            print("Error beginning display configuration: \(error)")
            return
        }
        
        // Get main display
        let mainDisplay = CGMainDisplayID()
        let mainWidth = Int32(CGDisplayPixelsWide(mainDisplay))
        let mainHeight = Int32(CGDisplayPixelsHigh(mainDisplay))
        
        // Get all online displays
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)
        
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
        
        // Configure main display at (0,0)
        CGConfigureDisplayOrigin(config, mainDisplay, 0, 0)
        CGConfigureDisplayMirrorOfDisplay(config, mainDisplay, CGDirectDisplayID(0)) // Stop mirroring
        
        for display in displays {
            if display != mainDisplay {
                CGConfigureDisplayMirrorOfDisplay(config, display, CGDirectDisplayID(0)) // Stop mirroring
                
                let secondaryWidth = Int32(CGDisplayPixelsWide(display))
                let secondaryHeight = Int32(CGDisplayPixelsHigh(display))
                
                var x: Int32 = 0
                var y: Int32 = 0
                
                switch position {
                case .left:
                    x = -secondaryWidth
                    y = 0 // Align tops
                case .right:
                    x = mainWidth
                    y = 0 // Align tops
                case .top:
                    x = 0 // Align lefts
                    y = -secondaryHeight
                case .bottom:
                    x = 0 // Align lefts
                    y = mainHeight
                }
                
                CGConfigureDisplayOrigin(config, display, x, y)
            }
        }
        
        let completeError = CGCompleteDisplayConfiguration(config, .permanently)
        if completeError != .success {
            print("Error completing display configuration: \(completeError)")
        }
    }
    
    func setMainDisplay(index: Int) {
        var configRef: CGDisplayConfigRef?
        let error = CGBeginDisplayConfiguration(&configRef)
        
        guard error == .success, let config = configRef else {
            print("Error beginning display configuration: \(error)")
            return
        }
        
        // Get all displays
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
        
        guard displays.count > 1 else {
            print("Not enough displays to swap main display.")
            CGCancelDisplayConfiguration(config)
            return
        }
        
        // Sort displays by X position to map index 1, 2...
        // Index 0 in argument = First display (Left-most)
        let sortedDisplays = displays.sorted(by: { CGDisplayBounds($0).minX < CGDisplayBounds($1).minX })
        
        guard index >= 0 && index < sortedDisplays.count else {
            print("Display index out of bounds.")
            CGCancelDisplayConfiguration(config)
            return
        }
        
        let newMain = sortedDisplays[index]
        
        // If the target is already main (0,0), do nothing.
        if newMain == CGMainDisplayID() {
            print("Target is already main.")
            CGCancelDisplayConfiguration(config)
            return
        }
        
        // Reconfigure logic similar to before
        let targetBounds = CGDisplayBounds(newMain)
        let shiftX = -targetBounds.origin.x
        let shiftY = -targetBounds.origin.y
        
        for display in displays {
            let bounds = CGDisplayBounds(display)
            let newX = Int32(bounds.origin.x + shiftX)
            let newY = Int32(bounds.origin.y + shiftY)
            
            CGConfigureDisplayOrigin(config, display, newX, newY)
        }
        
        let completeError = CGCompleteDisplayConfiguration(config, .permanently)
        if completeError != .success {
            print("Error completing display configuration to set main: \(completeError)")
        } else {
            print("Main display swapped successfully to index \(index).")
        }
    }
    
    func toggleMirroring() {
        // Check if currently mirroring
        // A simple check: if secondary display is mirroring main
        var isMirroring = false
        
        let mainDisplay = CGMainDisplayID()
        var displayCount: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &displayCount)
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetOnlineDisplayList(displayCount, &displays, &displayCount)
        
        for display in displays {
            if display != mainDisplay {
                if CGDisplayMirrorsDisplay(display) == mainDisplay {
                    isMirroring = true
                    break
                }
            }
        }
        
        print("Toggling mirroring. Current state: \(isMirroring ? "Mirrored" : "Extended")")
        setMirroring(enabled: !isMirroring)
    }
}
