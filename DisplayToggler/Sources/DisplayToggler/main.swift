import Cocoa

let app = NSApplication.shared
// Ensure the app is recognized as an accessory (menu bar) app
app.setActivationPolicy(.accessory)


let delegate = AppDelegate()
app.delegate = delegate
app.run()
