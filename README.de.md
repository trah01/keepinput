# InputLock

Standard-README: [简体中文](README.md)

Weitere Sprachen: [English](README.en.md) | [Français](README.fr.md) | Deutsch | [日本語](README.ja.md)

InputLock ist eine schlanke macOS-Menüleisten-App. Sie sperrt die aktuelle Eingabemethode und verhindert so versehentliche Wechsel beim Schreiben, Programmieren oder Wechseln zwischen Apps.

## Funktionen

- Sperrt die aktuelle Eingabemethode und stellt sie wieder her, wenn eine andere Quelle aktiv wird
- Wechselt vorübergehend zur gewählten Eingabe und stellt die Sperre nach 1–60 Sekunden Leerlauf wieder her, standardmäßig nach 5 Sekunden
- Unterstützt einzelne Tasten, Funktionstasten, Globe, Caps Lock, Shift, Option, Control, Command und deren Kombinationen
- Bietet ein eigenes Einstellungsfenster über das Menüleistenfenster, das Kontextmenü oder `Command + ,`
- Das Menüleistensymbol lässt sich ausblenden; erneutes Starten öffnet die Einstellungen
- Linksklick öffnet die Eingabequellenliste; Rechtsklick öffnet Schnellaktionen
- Unterstützt English, 简体中文, Français, Deutsch und 日本語
- Zeigt den tatsächlichen Systemstatus für den Start bei Anmeldung und stellt die letzte Sperre wieder her
- Pausiert die Sperre bei sicherer Passworteingabe
- Sucht Updates in GitHub Releases und lädt und installiert sie mit anschließendem Neustart

## Voraussetzungen

- macOS 12.0 Monterey oder neuer
- Start bei der Anmeldung erfordert macOS 13.0 oder neuer

## Installation

Empfohlene Installation über GitHub Releases:

1. Öffnen Sie die Seite [Releases](https://github.com/trah01/keepinput/releases).
2. Laden Sie die aktuelle Datei `InputLock-1.3.dmg` herunter.
3. Öffnen Sie die DMG-Datei und ziehen Sie `lockinput.app` in `Applications`.
4. Starten Sie InputLock aus `Applications`.

Die aktuelle Veröffentlichung ist nicht von Apple notarisiert. Wenn macOS den ersten Start blockiert, erlauben Sie die App unter Systemeinstellungen > Datenschutz & Sicherheit, oder klicken Sie mit gedrückter Control-Taste auf die App und wählen Sie Öffnen.

## Verwendung

- Linksklick auf das Schloss-Symbol in der Menüleiste: Hauptfenster öffnen
- Rechtsklick auf das Schloss-Symbol: Schnellaktionsmenü öffnen
- Klick auf eine Eingabemethode: direkt wechseln, wenn entsperrt, andernfalls vorübergehend wechseln
- Schaltfläche Sperren / Entsperren: aktuelle Quelle sperren oder Sperre aufheben
- Einstellungen unten im Hauptfenster oder mit `Command + ,` öffnen
- Kurzbefehl, Zieleingabe und Wartezeit einstellen. Erneutes Drücken stellt die Sperre sofort wieder her
- Zum Aufzeichnen eine Taste drücken oder eine Kombination aus Modifikatortasten loslassen. Erneut klicken zum Abbrechen, × zum Löschen. Escape und Delete sind ebenfalls möglich
- Bei Bedarf Zugriff auf Bedienungshilfen erlauben. Von macOS reservierte Kombinationen können zusätzlich ihre Systemaktion auslösen
- Menüleistensymbol in den Einstellungen ausblenden; erneutes Starten öffnet die Einstellungen wieder
- Unter Über nach Updates suchen und zum Installieren herunterladen und neu starten
- Sprache der Oberfläche in den Einstellungen wechseln
- Start bei der Anmeldung aktivieren: App unter macOS 13.0+ automatisch nach der Anmeldung starten
- Letzte Sperre nach Neustart wiederherstellen aktivieren: Beim nächsten App-Start wird die zuletzt gesperrte Eingabe wiederhergestellt

## Aus dem Quellcode ausführen

```bash
git clone https://github.com/trah01/keepinput.git
cd keepinput
open lockinput.xcodeproj
```

Wählen Sie in Xcode das Scheme `lockinput` aus und starten Sie die App.

## Release-Paket bauen

Wenn `xcodebuild` auf Command Line Tools zeigt, wechseln Sie zu vollständigem Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Release-App bauen:

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

DMG erstellen:

```bash
./scripts/create-dmg.sh
```

Die erzeugte Datei ist:

```text
InputLock-1.3.dmg
```

## Automatisch kompilieren und veröffentlichen

Der Workflow [.github/workflows/release.yml](.github/workflows/release.yml) startet beim Push eines Tags wie `v1.3` oder `v1.3.1` sowie über Actions → Build and Release → Run workflow. Manuelle Ausführungen akzeptieren Versionen mit oder ohne `v`. Ein vorhandener Tag muss zum ausgewählten Quellcode passen.

Er erstellt eine universelle App für Apple Silicon und Intel, signiert sie ad-hoc und veröffentlicht `InputLock-<Version>.dmg` und die `.sha256`-Prüfsumme in GitHub Releases. Die App-Version entspricht dem Tag ohne `v`; bei manuellen Veröffentlichungen wird der Tag bei Bedarf erstellt. Ein Apple-Zertifikat ist nicht erforderlich; das Paket ist nicht notarisiert.

## Projektstruktur

```text
lockinput/
├── lockinputApp.swift        # App-Einstieg und Menüleistenlogik
├── ContentView.swift         # Hauptoberfläche
├── SettingsView.swift        # Einstellungsfenster
├── InputMethodManager.swift  # Erkennung, Wechsel und Sperrung der Eingabequellen
├── InputSourceLockState.swift # Modell für den Sperrzustand
├── LanguageManager.swift     # Sprachwechsel zur Laufzeit
├── Info.plist                # App-Metadaten
├── Assets.xcassets/          # Symbole und Ressourcen
└── Resources/
    ├── en.lproj/             # Englisch
    ├── zh-Hans.lproj/        # Vereinfachtes Chinesisch
    ├── fr.lproj/             # Französisch
    ├── de.lproj/             # Deutsch
    └── ja.lproj/             # Japanisch
```

## Lokalisierung

So fügen Sie eine Sprache hinzu:

1. Erstellen Sie unter `lockinput/Resources/` einen neuen `.lproj`-Ordner.
2. Kopieren Sie eine vorhandene `Localizable.strings`-Datei und übersetzen Sie sie.
3. Fügen Sie den Sprachcode zu `knownRegions` in `lockinput.xcodeproj/project.pbxproj` hinzu.
4. Fügen Sie die Sprache zur Enumeration `AppLanguage` in `LanguageManager.swift` hinzu.

## Lizenz

Dieses Repository enthält derzeit keine separate `LICENSE`-Datei.
