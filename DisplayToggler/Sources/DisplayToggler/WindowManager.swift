import Cocoa
import ApplicationServices

enum WindowAction {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case maximize
}

@MainActor
class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    func moveFocusedWindow(to action: WindowAction) {
        guard let appElement = getFocusedApplicationElement() else {
            print("No focused application found.")
            return
        }
        
        guard let windowElement = getFocusedWindowElement(for: appElement) else {
            print("No focused window found.")
            return
        }
        
        // Get current frame of the window
        guard let currentWindowFrame = getWindowFrame(windowElement) else {
            print("Could not get window frame.")
            return
        }
        
        // Find the screen containing this window
        guard let currentScreen = getScreen(containing: currentWindowFrame) else {
            print("Could not determine current screen.")
            return
        }
        
        // Use visibleFrame to account for Dock and Menu Bar
        let visibleFrame = currentScreen.visibleFrame
        var newFrame = visibleFrame
        
        switch action {
        case .leftHalf:
            newFrame.size.width = visibleFrame.width / 2
            newFrame.origin.x = visibleFrame.minX
            newFrame.origin.y = visibleFrame.minY
            newFrame.size.height = visibleFrame.height
            
        case .rightHalf:
            newFrame.size.width = visibleFrame.width / 2
            newFrame.origin.x = visibleFrame.minX + (visibleFrame.width / 2)
            newFrame.origin.y = visibleFrame.minY
            newFrame.size.height = visibleFrame.height
            
        case .topHalf:
            newFrame.size.height = visibleFrame.height / 2
            newFrame.origin.y = visibleFrame.minY + (visibleFrame.height / 2)
            newFrame.origin.x = visibleFrame.minX
            newFrame.size.width = visibleFrame.width
            
        case .bottomHalf:
            newFrame.size.height = visibleFrame.height / 2
            newFrame.origin.y = visibleFrame.minY
            newFrame.origin.x = visibleFrame.minX
            newFrame.size.width = visibleFrame.width
            
        case .maximize:
            newFrame = visibleFrame
        }
        
        // Apply
        setWindowFrame(windowElement, to: newFrame)
    }
    
    private func getFocusedApplicationElement() -> AXUIElement? {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            // print("Frontmost App: \(frontApp.localizedName ?? "Unknown") (PID: \(frontApp.processIdentifier))")
            return AXUIElementCreateApplication(frontApp.processIdentifier)
        } else {
            print("Could not determine frontmost application via NSWorkspace.")
            return nil
        }
    }
    
    private func getFocusedWindowElement(for app: AXUIElement) -> AXUIElement? {
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if result == .success {
            return (focusedWindow as! AXUIElement)
        } else {
            print("Error getting focused window from app element: \(result.rawValue). This usually means the app does not expose an accessible window or permissions are denied.")
            return nil
        }
    }

    private func isRoughlyEqual(_ r1: CGRect, _ r2: CGRect, threshold: CGFloat = 50) -> Bool {
        // Debug prints to help diagnose sticky windows
        // print("Comparing: \(r1) with \(r2)")
        return abs(r1.origin.x - r2.origin.x) < threshold &&
               abs(r1.origin.y - r2.origin.y) < threshold &&
               abs(r1.width - r2.width) < threshold &&
               abs(r1.height - r2.height) < threshold
    }
    
    private func getScreen(containing rect: CGRect) -> NSScreen? {
        // Find screen with largest intersection
        var bestScreen: NSScreen?
        var maxArea: CGFloat = 0
        
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(rect)
            let area = intersection.width * intersection.height
            if area > maxArea {
                maxArea = area
                bestScreen = screen
            }
        }
        return bestScreen
    }
    
    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        if let posVal = positionValue {
            AXValueGetValue(posVal as! AXValue, .cgPoint, &position)
        }
        if let sizeVal = sizeValue {
            AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        }
        
        // AX Coordinates are Top-Left logic (Quartz Global).
        // NSScreen coordinates are Bottom-Left logic (Cocoa).
        // To compare with NSScreen.frame, we should convert AX Rect to Cocoa Rect.
        
        guard let primaryScreenHeight = NSScreen.screens.first?.frame.height else { return nil }
        
        // Cocoa Y = PrimaryScreenHeight - (AX_Y + Height)
        let cocoaY = primaryScreenHeight - (position.y + size.height)
        
        return CGRect(x: position.x, y: cocoaY, width: size.width, height: size.height)
    }
    
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) {
        // Frame is in Cocoa coordinates. Convert to AX (Quartz Global).
        guard let primaryScreenHeight = NSScreen.screens.first?.frame.height else { return }
        
        let axX = frame.origin.x
        let axY = primaryScreenHeight - (frame.origin.y + frame.height)
        
        var position = CGPoint(x: axX, y: axY)
        var size = frame.size
        
        guard let positionValue = AXValueCreate(.cgPoint, &position) else { return }
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        
        guard let sizeValue = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }
}
