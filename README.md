# DisplayToggler
A menu bar application that allows you to toggle between "Mirror" and "Extend" display modes in Mac OS.

# How to Run
Navigate to the project directory:

cd ./DisplayToggler
Launch the App: You can now simply double-click DisplayToggler.app in Finder.

Or run from terminal:

open DisplayToggler.app

# Features
Menu Bar Icon: A display icon appears in your menu bar.
Status: Shows the number of detected displays.
Mirror Displays: Select this to mirror your secondary display to your main display.
Extend Displays: Select this to extend your desktop (stops mirroring).
Arrangement: Submenu to position the secondary display relative to the main display (Left, Right, Top, Bottom).
Global Hotkey: Press Cmd + Option + D to toggle mirroring instantly, even if the menu icon is hidden.
Quit: Exits the application.

# Notes
The app uses native macOS APIs (CoreGraphics) to configure displays.
Changes take effect immediately.
If you want to build a release version (optimized):
swift build -c release
The binary will be at .build/release/DisplayToggler.

# Verification Results
Build Status: Success (Swift 6.2)
Functionality: Verified logic for Mirror/Extend toggling using CoreGraphics.