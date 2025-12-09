# DisplayToggler
A menu bar application that allows you to toggle between "Mirror" and "Extend" display modes in Mac OS.

# How to Run
Navigate to the project directory:

cd ./DisplayToggler
Launch the App: You can now simply double-click DisplayToggler.app in Finder.

Or run from terminal:

open DisplayToggler.app

# Initial Setup (Important!)
This app requires **Accessibility Permissions** to manage windows.
1. When you first launch the app, you will see a prompt if permissions are missing.
2. Go to **System Settings > Privacy & Security > Accessibility**.
3. Enable **DisplayToggler**.

# Features
*   **Menu Bar Icon**: Access all controls from the menu bar.
*   **Mirror/Extend**: Toggle between mirroring and extending displays.
*   **Window Management**: Quickly resize and move windows.
*   **Display Arrangement**: Set your main display layout instantly.
*   **Global Hotkey**: Toggle mirroring visibility with `Cmd + Option + Ctrl + D`.

## Hotkeys

### Window Management
*   `Ctrl + Option + Result`
*   `←` : Left Half
*   `→` : Right Half
*   `↑` : Top Half
*   `↓` : Bottom Half
*   `Enter` : Maximize

### Display Arrangement (Set Main Display)
*   `Cmd + Option + Ctrl + 1` (or `←`): Set **Left** Display as Main
*   `Cmd + Option + Ctrl + 2` (or `→`): Set **Right** Display as Main

# Notes
The app uses native macOS APIs (CoreGraphics & Accessibility).
Changes take effect immediately.

# Build
To build a release version:
```bash
swift build -c release
```
The binary will be at `.build/release/DisplayToggler`.