# SeemlessScreen for macOS

Seamlessly switch which window is shared during video calls — without stopping your screen share.

## How It Works

SeemlessScreen creates a persistent **Shared Surface** window. You share *this window* in Zoom, Teams, or any video call app. Then use the floating picker to instantly switch which application is mirrored inside it.

## Features

- **Seamless Switching** — Swap the shared app instantly. No screen share interruption.
- **Global Hotkey** — Press `Cmd + Shift + S` to toggle the window picker.
- **Active Window Mode** — Automatically follow whichever app is in the foreground.
- **Menu Bar App** — Lives in the menu bar. No Dock icon clutter.
- **Privacy** — The picker UI never appears in the captured output.
- **High Performance** — Uses ScreenCaptureKit with zero-copy IOSurface rendering.

## Requirements

- **macOS 14.0** (Sonoma) or later
- **Xcode 15+** (to build)
- **Screen Recording permission** (prompted on first launch)

## How to Build

1. Open the project in Xcode:
   ```bash
   cd SeemlessScreen-mac
   open Package.swift
   ```

2. Select the `SeemlessScreen` scheme and press `Cmd + R` to build and run.

   Or build from the command line:
   ```bash
   xcodebuild -scheme SeemlessScreen -destination 'platform=macOS' build
   ```

## How to Use

1. **Launch** — The app appears as an icon in the menu bar (no Dock icon).
2. **Share the Surface** — In your video call, share the "SeemlessScreen - Shared Surface" window.
3. **Pick a Window** — Press `Cmd + Shift + S` or click the menu bar icon > "Show Switcher".
4. **Click a window thumbnail** to start mirroring it.
5. **Switch apps** — Open the picker again and click a different window. The transition is seamless.
6. **Active Window Mode** — Toggle this to automatically share whichever app you're using.

## Architecture

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI + AppKit |
| Window Capture | ScreenCaptureKit (SCStream) |
| Frame Rendering | IOSurface via CALayer (zero-copy GPU) |
| Global Hotkeys | KeyboardShortcuts (Carbon wrapper) |
| Menu Bar | SwiftUI MenuBarExtra |
| Settings | @AppStorage / UserDefaults |
