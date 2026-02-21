<div align="center">
    <img src="SSHTunnel/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="200" height="200">
    <h1>SSH Tunnel Manager</h1>
</div>

A lightweight macOS menu bar app for managing SSH tunnels. Create, connect, and organize port forwarding rules with a clean native interface.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
[![Download](https://img.shields.io/badge/download-latest-brightgreen?style=flat-square)](https://github.com/TypoStudio/ssh-tunnel-for-macos/releases)

## Install

### Manual Installation

Download the latest `.dmg` from the [Releases](https://github.com/TypoStudio/ssh-tunnel-for-macos/releases) page, open it, and drag `SSHTunnel.app` to your `Applications` folder.

### Build from Source

```sh
# Requires Xcode and XcodeGen
brew install xcodegen
xcodegen generate
xcodebuild -project SSHTunnel.xcodeproj -scheme SSHTunnel -configuration Release build
```

## Features

### Tunnel Management
- [x] Create and manage multiple SSH tunnel configurations
- [x] Local (`-L`), Remote (`-R`), and Dynamic (`-D`) port forwarding
- [x] Multiple forwarding rules per tunnel
- [x] Connect / disconnect with a single click
- [x] Auto-connect on launch per tunnel
- [x] Disconnect on quit per tunnel
- [x] Port conflict detection before connecting
- [x] Connection log viewer

### SSH Config Integration
- [x] Browse and edit `~/.ssh/config` hosts
- [x] Load SSH Config hosts into tunnel configurations
- [x] Open config files in external editor
- [x] Raw text editing mode for SSH config entries

### Authentication
- [x] Identity file (private key) selection
- [x] Password stored securely in macOS Keychain
- [x] Additional SSH arguments support

### Share & Import
- [x] Share tunnel configs as `sshtunnel://` URLs
- [x] Import configs from share strings
- [x] Copy equivalent CLI command (`ssh -L ...`)
- [x] URL scheme handler for one-click import

### Menu Bar
- [x] Quick connect / disconnect from the menu bar
- [x] Monitor running SSH processes
- [x] Open Manager window from menu bar
- [x] Settings with launch at login option

### Localization
- [x] English
- [x] Korean (한국어)

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘I` | Import from share string |
| `⌘V` | Paste share string to import |
| `⌘M` | Open Manager from menu bar |
| `⌘,` | Open Settings |
| `⌘Q` | Quit application |
| `Esc` | Close dialog |

## Requirements

- macOS 14.0 (Sonoma) or later
- SSH client (pre-installed on macOS)

## License

SSH Tunnel Manager is available under the [MIT License](LICENSE).

<a href="https://www.buymeacoffee.com/typ0s2d10" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/arial-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
