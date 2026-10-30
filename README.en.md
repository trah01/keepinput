# InputLock

Default README: [简体中文](README.md)

Other languages: English | [Français](README.fr.md) | [Deutsch](README.de.md) | [日本語](README.ja.md)

InputLock is a lightweight macOS menu bar app that locks the current input method and helps prevent accidental input source switching while writing, coding, or moving between apps.

## Features

- Locks the current input method and switches back if another source becomes active
- Temporarily switches to a selected input source and restores the lock after 1–60 seconds of idle time (default: 5 seconds)
- Supports plain keys, function keys, Globe, Caps Lock, Shift, Option, Control, Command, modifier-only chords, and modified key combinations
- Provides a dedicated settings window from the menu bar panel, context menu, or `Command + ,`
- Can hide the menu bar icon; launching the app again opens Settings
- Left-click opens the input source panel; right-click opens quick actions
- Supports English, 简体中文, Français, Deutsch, and 日本語
- Reads the actual system login-item status and restores the last lock after restart
- Pauses enforcement during secure password input and resumes afterward
- Checks GitHub Releases for updates and downloads, installs, and restarts from Settings

## Requirements

- macOS 12.0 Monterey or later
- Launch at login requires macOS 13.0 or later

## Installation

Install from GitHub Releases:

1. Open the [Releases](https://github.com/trah01/keepinput/releases) page.
2. Download the latest `InputLock-1.3.dmg`.
3. Open the DMG and drag `lockinput.app` to `Applications`.
4. Launch InputLock from `Applications`.

The current release is not Apple-notarized. If macOS blocks the first launch, allow it in System Settings > Privacy & Security, or Control-click the app and choose Open.

## Usage

- Left-click the menu bar lock icon to open the main panel
- Right-click the menu bar lock icon to open the quick actions menu
- Click an input method to switch directly when unlocked, or temporarily when locked
- Use the Lock / Unlock button to lock the current source or release the lock
- Open Settings from the panel or context menu, or press `Command + ,` while the app is active
- Set the temporary shortcut, target input source, and idle interval in Settings. The shortcut requires an active lock; an unspecified target falls back to an ABC/US-style keyboard layout. Typing delays restoration; pressing the shortcut again restores the lock immediately
- Press a regular key to record it, or hold a modifier chord and release it to save. Caps Lock saves on its toggle. Click the recording button again to cancel, or × to clear. Escape and Delete can also be recorded
- Shortcuts that need Accessibility access show an authorization button. System-reserved combinations remain subject to macOS restrictions and may also perform their system action
- Enable Hide Menu Bar Icon to hide the top-bar icon. Launch the app again to open Settings and restore it
- Check for updates in the About section and choose Download and Restart when an update is available. Move the app out of the DMG into a writable Applications folder first
- Change the interface language in Settings
- Enable Launch at Login on macOS 13.0+. Its switch reflects the system status; if approval is required, use the button to open Login Items settings
- Enable Restore Last Lock After Restart to restore the previously locked input source when the app starts again

## Project Origin

This repository continues development from [bigccc/inputlock](https://github.com/bigccc/inputlock).

## Run From Source

```bash
git clone https://github.com/trah01/keepinput.git
cd keepinput
open lockinput.xcodeproj
```

Select the `lockinput` scheme in Xcode, then run the app.

## Build a Release Package

If `xcodebuild` points to Command Line Tools, switch to full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Build the Release app:

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

Create the DMG:

```bash
./scripts/create-dmg.sh
```

The generated file is:

```text
InputLock-1.3.dmg
```

## Automated Builds and Releases

[.github/workflows/release.yml](.github/workflows/release.yml) runs when you push a version tag such as `v1.3` or `v1.3.1`, or choose Actions → Build and Release → Run workflow. Manual runs accept versions with or without `v`; existing tags must point to the selected source.

The workflow builds a universal Apple Silicon and Intel app, applies ad-hoc signing, and publishes `InputLock-<version>.dmg` and its `.sha256` checksum to the matching GitHub Release. The app version follows the tag without its `v` prefix. Manual releases create the tag if necessary. No Apple developer certificate is required; packages are not notarized.

## Project Structure

```text
lockinput/
├── lockinputApp.swift        # App entry point and menu bar setup
├── ContentView.swift         # Main panel UI
├── SettingsView.swift        # Settings window UI
├── InputMethodManager.swift  # Input source discovery, switching, and lock enforcement
├── InputSourceLockState.swift # Lock state model
├── GlobalShortcutManager.swift # Shortcut recording and global activation
├── ApplicationSettings.swift # Menu bar visibility and system login items
├── UpdateManager.swift       # Update checks, downloads, and restart installation
├── LanguageManager.swift     # Runtime language switching
├── Info.plist                # App metadata
├── Assets.xcassets/          # Icons and assets
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # Simplified Chinese
    ├── fr.lproj/             # French
    ├── de.lproj/             # German
    └── ja.lproj/             # Japanese
```

## Localization

To add a language:

1. Create a new `.lproj` folder under `lockinput/Resources/`.
2. Copy an existing `Localizable.strings` file and translate it.
3. Add the language code to `knownRegions` in `lockinput.xcodeproj/project.pbxproj`.
4. Add the language to the `AppLanguage` enum in `LanguageManager.swift`.

## License

This repository does not currently include a separate `LICENSE` file.
