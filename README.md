# ScreenRelay for macOS

Seamlessly switch which window is shared during video calls — without stopping your screen share.

## The Problem

In Zoom, Teams, or Google Meet, sharing your entire screen might be inconvenient, and sharing a specific window locks you into it. Want to show something else? You have to stop sharing, pick a new window, and reshare. CLUNKY... Your audience sees the disruption, their screen is disrupted again if they started multitasking;)

## How ScreenRelay Solves It

ScreenRelay creates a **Shared Surface** window that acts as a mirror. You share this single window in your video call. Then use the floating picker (or a hotkey) to instantly switch which app is mirrored inside it. Your audience sees a smooth, instant transition — no "stopped sharing" interruption.

```
Your Windows              ScreenRelay               Video Call
                          Shared Surface
Chrome      ──pick──►   ┌──────────────┐
                        │ Chrome       │──share──►  Audience sees Chrome
                        └──────────────┘
                             ↓ switch
VS Code     ──pick──►   ┌──────────────┐
                        │ VS Code      │──share──►  Audience sees VS Code
                        └──────────────┘
```

## Features

- **Seamless Switching** — Swap the shared app instantly. No screen share interruption.
- **Global Hotkey** — Press `Cmd + Shift + S` to toggle the window picker.
- **Active Window Mode** — Automatically follow whichever app is in the foreground.
- **Menu Bar App** — Lives in the menu bar. No Dock icon clutter.
- **Privacy** — The picker UI never appears in the captured output.
- **High Performance** — Uses ScreenCaptureKit with GPU-accelerated rendering.

## Requirements

- A Mac running **macOS 14.0 (Sonoma)** or later
- **Xcode 15+** (free from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) — needed to build the app)

## Installation

### 1. Clone this repository

Open **Terminal** (search for "Terminal" in Spotlight) and run:

```bash
git clone https://github.com/levdudas/SeemlessScreen-mac.git
cd SeemlessScreen-mac
```

### 2. Open in Xcode

```bash
open Package.swift
```

Wait a moment for Xcode to finish loading and indexing.

### 3. Build and Run

1. At the top of the Xcode window, make sure the scheme says **ScreenRelay** and the destination says **My Mac**.
2. Press **Cmd + R** (or click the play button).
3. The app has **no Dock icon** — look for a small rectangle icon in your **menu bar** (top-right of your screen, near the clock).

**Alternative — build from the command line:**
```bash
xcodebuild -scheme ScreenRelay -destination 'platform=macOS' build
```

### 4. Grant Screen Recording Permission

On first launch, macOS will show a permission dialog:

1. Click **Allow** to grant Screen Recording access.
2. If you've previously denied it, you'll be taken to **System Settings > Privacy & Security > Screen Recording**. Toggle the switch next to **ScreenRelay**.
3. **Quit and relaunch the app** — macOS requires a restart after granting this permission.

### Running the app later

- **From Xcode:** Open the project (`open Package.swift`) and press **Cmd + R**.
- **From Finder:** In Xcode, go to **Product > Show Build Folder in Finder**, find the `ScreenRelay` executable, and run it directly. You can also copy it somewhere convenient.

## How to Use

### Step 1: Start a video call

Open Zoom, Teams, Google Meet, or any video call app and join a meeting.

### Step 2: Share the Shared Surface

In your video call, click **Share Screen**, choose **Window**, and select the window titled **"ScreenRelay - Shared Surface"**.

> **Important:** Share the Shared Surface window — not your actual app windows. This is the key to seamless switching.

### Step 3: Pick a window to mirror

Press **Cmd + Shift + S** (or click the menu bar icon > **Show Switcher**). A floating grid of all your open windows appears with live thumbnails. Click any window to start mirroring it.

### Step 4: Switch between apps

Press **Cmd + Shift + S** again and pick a different window. Your call participants see an instant, smooth transition.

### Active Window Mode

Toggle **Active Window Mode** from the menu bar to automatically mirror whichever app is currently in the foreground. No manual switching needed — just use your Mac normally and ScreenRelay follows along.

### Stop Mirroring

Click the menu bar icon > **Stop Mirroring**, or quit the app.

## Settings

Open **Settings** from the menu bar icon to:

- **Change the hotkey** — Click "Record" and press your preferred key combination.
- **Toggle cursor visibility** in the captured output.
- **Enable/disable Active Window Mode.**

## Architecture

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI + AppKit |
| Window Capture | ScreenCaptureKit (SCStream) |
| Frame Rendering | CGImage via CALayer + CIContext (GPU) |
| Global Hotkeys | Carbon RegisterEventHotKey |
| Menu Bar | SwiftUI MenuBarExtra |
| Settings | UserDefaults |
