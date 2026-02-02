import Cocoa

@MainActor
class OverlayManager {
    static let shared = OverlayManager()
    
    // Keep strong references to windows so they don't deallocate immediately
    private var overlayWindows: [NSPanel] = []
    
    // Track the current showing task to cancel it if needed
    private var showTask: Task<Void, Never>?
    
    private init() {}
    
    func showDisplayIdentification() {
        logger.log("OverlayManager: showDisplayIdentification called.")
        
        // Cancel previous task if running
        showTask?.cancel()
        showTask = nil
        
        print("OverlayManager: Requested to show display identification.")
        // Remove any existing overlays first
        removeOverlays()
        
        // Schedule new task
        showTask = Task { @MainActor in
            // Check cancellation before sleep
            if Task.isCancelled { return }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if Task.isCancelled { 
                logger.log("OverlayManager: Task cancelled after sleep.")
                return 
            }
            
            logger.log("OverlayManager: Executing delayed show.")
            print("OverlayManager: Executing delayed show.")
            self.createAndShowOverlays()
        }
    }
    
    private func createAndShowOverlays() {
        logger.log("OverlayManager: createAndShowOverlays running.")
        let screens = NSScreen.screens
        // Map screens to sort them left-to-right to give them logical numbers
        let sortedScreens = screens.sorted { $0.frame.minX < $1.frame.minX }
        
        guard !sortedScreens.isEmpty else {
            logger.log("OverlayManager: No screens found!")
            print("OverlayManager: No screens found via NSScreen.screens.")
            return
        }
        logger.log("OverlayManager: Found \(sortedScreens.count) screens")
        
        print("OverlayManager: Found \(sortedScreens.count) screens. Creating overlays...")
        
        for (index, screen) in sortedScreens.enumerated() {
            let isMain = (screen == NSScreen.main)
            let number = index + 1
            
            // Safety check for frame validity
            let window = createOverlayWindow(for: screen, number: number, isMain: isMain)
            overlayWindows.append(window)
            // Use orderFront instead of makeKeyAndOrderFront to avoid stealing focus
            window.orderFront(nil)
        }
        
        // Auto-close after 3 seconds
        logger.log("OverlayManager: Scheduling auto-close in 3.0s")
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self?.fadeOutAndRemoveOverlays()
        }
    }

    
    private func removeOverlays() {
        logger.log("OverlayManager: removeOverlays() called. Count: \(overlayWindows.count)")
        overlayWindows.forEach { 
            $0.orderOut(nil)
            $0.close() 
        }
        overlayWindows.removeAll()
        logger.log("OverlayManager: removeOverlays() finished")
    }
    
    private func fadeOutAndRemoveOverlays() {
        print("OverlayManager: Fading out overlays.")
        logger.log("OverlayManager: fadeOutAndRemoveOverlays() called")
        guard !overlayWindows.isEmpty else { 
             logger.log("OverlayManager: No windows to fade out")
             return 
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            for window in overlayWindows {
                window.animator().alphaValue = 0
            }
        } completionHandler: {
             Task { @MainActor [weak self] in
                logger.log("OverlayManager: Fade out complete. Removing overlays.")
                self?.removeOverlays()
            }
        }
    }
    
    private func createOverlayWindow(for screen: NSScreen, number: Int, isMain: Bool) -> NSPanel {
        let window = NSPanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow, .borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver // High level ensuring visibility
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true // Click-through
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isFloatingPanel = true
        
        logger.log("OverlayManager: Window properties set")
        
        // Better: Make the window the size of the overlay view and center it on screen.
        let overlaySize = NSSize(width: 300, height: 200)
        let screenRect = screen.frame
        let centeredOrigin = NSPoint(
            x: screenRect.midX - overlaySize.width / 2,
            y: screenRect.midY - overlaySize.height / 2
        )
        
        window.setFrame(NSRect(origin: centeredOrigin, size: overlaySize), display: true)
        
        let contentView = OverlayView(frame: NSRect(origin: .zero, size: overlaySize))
        contentView.number = number
        contentView.isMain = isMain
        window.contentView = contentView
        
        return window
    }
}

class OverlayView: NSView {
    var number: Int = 0
    var isMain: Bool = false
    
    deinit {
        // Log deallocation to verify cleanup
        // Note: Logger might need to be thread-safe or this should be safe if on main thread
        // logger.log("OverlayView: deinit") 
        // Cannot easily log from deinit if logger struct isn't actor-safe, but let's assume it is okay for now or just print
        print("OverlayView: deinit")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        logger.log("OverlayView: draw() called for number \(number)")
        // Draw rounded rectangle background
        let cornerRadius: CGFloat = 20
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor(white: 0.1, alpha: 0.8).setFill()
        bgPath.fill()
        
        // Helper for text drawing
        func drawText(_ text: String, font: NSFont, yOffset: CGFloat) {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let size = text.size(withAttributes: attrs)
            let x = (bounds.width - size.width) / 2
            let y = (bounds.height - size.height) / 2 + yOffset
            text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
        }
        
        // Draw Number
        let numberFont = NSFont.systemFont(ofSize: 80, weight: .bold)
        drawText("\(number)", font: numberFont, yOffset: isMain ? 20 : 0)
        
        // Draw "Main Display" if applicable
        if isMain {
            let labelFont = NSFont.systemFont(ofSize: 24, weight: .medium)
            drawText("Main Display", font: labelFont, yOffset: -40)
        }
    }
}
