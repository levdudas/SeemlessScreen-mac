# SeemlessScreen for macOS

Seamlessly switch which window is shared during video calls — without stopping your screen share.

## How It Works

SeemlessScreen creates a persistent **Shared Surface** window. You share *this window* in Zoom, Teams, or any video call app. Then use the floating picker to instantly switch which application is mirrored inside it. Your participants see a smooth transition — no "stopped sharing" interruption.

## Features

- **Seamless Switching** — Swap the shared app instantly. No screen share interruption.
- **Global Hotkey** — Press `Cmd + Shift + S` to toggle the window picker.
- **Active Window Mode** — Automatically follow whichever app is in the foreground.
- **Menu Bar App** — Lives in the menu bar. No Dock icon clutter.
- **Privacy** — The picker UI never appears in the captured output.
- **High Performance** — Uses ScreenCaptureKit with zero-copy IOSurface rendering.

## Requirements

- A Mac running **macOS 14.0 (Sonoma)** or later
- **Xcode 15+** (free from the Mac App Store — needed to build the app)

## Getting Started

### 1. Install Xcode

If you don't already have Xcode installed, download it for free from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835). It's around 7 GB and may take a while to download.

After installing, open Xcode once and accept the license agreement if prompted.

### 2. Clone this repository

Open **Terminal** (search for "Terminal" in Spotlight) and run:

```bash
git clone https://github.com/levdudas/SeemlessScreen-mac.git
```

### 3. Open in Xcode

```bash
cd SeemlessScreen-mac
open Package.swift
```

This opens the project in Xcode. Wait a moment for Xcode to finish loading and indexing the project.

### 4. Build and Run

1. At the top of the Xcode window, make sure the scheme says **SeemlessScreen** and the destination says **My Mac**.
2. Press **Cmd + R** (or click the play button in the top-left).
3. Xcode will compile the app and launch it.

**Alternative — build from the command line:**
```bash
xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build
```

### 5. Grant Screen Recording Permission

On first launch, macOS will ask you to grant **Screen Recording** permission:

1. You'll be directed to **System Settings > Privacy & Security > Screen Recording**.
2. Toggle the switch next to **SeemlessScreen** to enable it.
3. You may need to quit and relaunch the app for the permission to take effect.

## How to Use

1. **Find the app** — After launching, look for a small rectangle icon in your **menu bar** (top-right of your screen, near the clock). There's no Dock icon — that's by design.
2. **Share the Surface** — In your Zoom/Teams/Google Meet call, click "Share Screen", choose **Window**, and select the **"SeemlessScreen - Shared Surface"** window.
3. **Pick a window to share** — Press **Cmd + Shift + S** (or click the menu bar icon > "Show Switcher"). A floating grid of all your open windows will appear with live thumbnails.
4. **Click a window** to start mirroring it into the Shared Surface.
5. **Switch apps** — Press **Cmd + Shift + S** again and pick a different window. Your call participants see a smooth transition with no interruption.
6. **Active Window Mode** — Toggle this in the menu or the picker to automatically share whichever app you're currently using. No manual switching needed.
7. **Stop Sharing** — Click the menu bar icon > "Stop Sharing", or just quit the app.

## Customization

Open **Settings** from the menu bar icon to:
- **Change the hotkey** — Click "Record" and press your preferred key combination.
- **Toggle cursor visibility** in the captured output.
- **Enable/disable Active Window Mode.**

## Architecture

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI + AppKit |
| Window Capture | ScreenCaptureKit (SCStream) |
| Frame Rendering | IOSurface via CALayer (zero-copy GPU) |
| Global Hotkeys | Carbon RegisterEventHotKey |
| Menu Bar | SwiftUI MenuBarExtra |
| Settings | UserDefaults |
