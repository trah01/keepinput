# KeepInput

README par défaut : [简体中文](README.md)

Autres langues : [English](README.en.md) | Français | [Deutsch](README.de.md) | [日本語](README.ja.md)

InputLock est une application légère pour la barre de menus de macOS. Elle verrouille la méthode de saisie active afin de limiter les changements accidentels lors de la rédaction, du développement ou du passage d'une application à l'autre.

## Fonctionnalités

- Verrouille la méthode de saisie active et la rétablit si une autre source devient active
- Bascule temporairement vers la saisie choisie et rétablit le verrouillage après 1 à 60 s d’inactivité, 5 s par défaut
- Accepte les touches seules, les touches de fonction, Globe, Caps Lock, Shift, Option, Control, Command et leurs combinaisons
- Fournit une fenêtre de réglages accessible depuis le panneau de barre de menus, le menu contextuel ou `Command + ,`
- Permet de masquer l’icône de la barre de menus ; relancer l’app ouvre les réglages
- Clic gauche pour ouvrir le panneau des méthodes de saisie ; clic droit pour les actions rapides
- Prend en charge English, 简体中文, Français, Deutsch et 日本語
- Affiche l’état réel du lancement à l’ouverture de session et restaure le verrouillage après redémarrage
- Suspend le verrouillage pendant la saisie sécurisée d’un mot de passe
- Recherche les mises à jour GitHub Releases, puis les télécharge et redémarre pour les installer

## Prérequis

- macOS 12.0 Monterey ou version ultérieure
- Le lancement à l'ouverture de session nécessite macOS 13.0 ou version ultérieure

## Installation

Installation recommandée depuis GitHub Releases :

1. Ouvrez la page [Releases](https://github.com/trah01/keepinput/releases).
2. Téléchargez le dernier fichier `InputLock-1.3.dmg`.
3. Ouvrez le DMG et faites glisser `lockinput.app` vers `Applications`.
4. Lancez InputLock depuis `Applications`.

Les paquets utilisent une signature locale ad-hoc, sans notarisation Apple. Si macOS bloque le premier lancement, autorisez l’app dans Réglages Système > Confidentialité et sécurité. Après avoir vérifié que le paquet provient des Releases de ce projet et déplacé l’app dans Applications, vous pouvez aussi exécuter :

```bash
xattr -dr com.apple.quarantine /Applications/lockinput.app
```

Ouvrez ensuite l’app. Adaptez le chemin si nécessaire ; ajoutez `sudo` uniquement en cas de refus d’accès.

## Utilisation

- Clic gauche sur l'icône de verrouillage dans la barre de menus : ouvrir le panneau principal
- Clic droit sur l'icône : ouvrir le menu d'actions rapides
- Clic sur une méthode de saisie : basculer directement sans verrouillage actif, ou temporairement si le verrouillage est actif
- Bouton Verrouiller / Déverrouiller : verrouiller la source active ou libérer le verrou
- Ouvrez les réglages depuis le bas du panneau principal ou avec `Command + ,`
- Choisissez le raccourci, la saisie cible et le délai d’inactivité. Appuyez à nouveau sur le raccourci pour rétablir immédiatement le verrouillage
- Pour enregistrer, appuyez sur une touche ou relâchez une combinaison de modificateurs. Cliquez à nouveau pour annuler, sur × pour effacer. Escape et Delete sont acceptés
- Autorisez l’accès Accessibilité si demandé. Les combinaisons réservées par macOS peuvent aussi déclencher leur action système
- Masquez l’icône de la barre de menus dans les réglages ; relancez l’app pour les rouvrir
- Recherchez les mises à jour dans À propos, puis téléchargez et redémarrez pour installer
- Changez la langue de l'interface dans les réglages
- Option de lancement à l'ouverture de session : démarrer l'application automatiquement sous macOS 13.0+
- Option de restauration après redémarrage : restaurer la dernière saisie verrouillée au prochain lancement

## Exécuter depuis le code source

```bash
git clone https://github.com/trah01/keepinput.git
cd keepinput
open lockinput.xcodeproj
```

Sélectionnez le scheme `lockinput` dans Xcode, puis lancez l'application.

## Construire un paquet de publication

Si `xcodebuild` pointe vers Command Line Tools, basculez vers Xcode complet :

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Construisez l'application Release :

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

Créez le DMG :

```bash
./scripts/create-dmg.sh
```

Le fichier généré est :

```text
InputLock-1.3.dmg
```

## Compilation et publication automatiques

Le workflow [.github/workflows/release.yml](.github/workflows/release.yml) se lance lors de l’envoi d’un tag `v1.3` ou `v1.3.1`, ou depuis Actions → Build and Release → Run workflow. Le lancement manuel accepte un numéro avec ou sans `v`. Pour une version existante, le workflow récupère automatiquement le code du tag pour reconstruire et téléverser le paquet.

Il compile une app universelle Apple Silicon et Intel, applique une signature ad-hoc et publie `InputLock-<version>.dmg` et son fichier `.sha256` dans GitHub Releases. La version de l’app suit le tag sans `v` ; le lancement manuel crée le tag si nécessaire. Aucun certificat Apple n’est requis ; le paquet n’est pas notarié.

## Structure du projet

```text
lockinput/
├── lockinputApp.swift        # Point d'entrée et barre de menus
├── ContentView.swift         # Interface du panneau principal
├── SettingsView.swift        # Interface des réglages
├── InputMethodManager.swift  # Détection, changement et verrouillage des sources de saisie
├── InputSourceLockState.swift # Modèle d'état du verrouillage
├── LanguageManager.swift     # Changement de langue à l'exécution
├── Info.plist                # Métadonnées de l'application
├── Assets.xcassets/          # Icônes et ressources
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # Chinois simplifié
    ├── fr.lproj/             # Français
    ├── de.lproj/             # Allemand
    └── ja.lproj/             # Japonais
```

## Localisation

Pour ajouter une langue :

1. Créez un nouveau dossier `.lproj` dans `lockinput/Resources/`.
2. Copiez un fichier `Localizable.strings` existant et traduisez-le.
3. Ajoutez le code de langue à `knownRegions` dans `lockinput.xcodeproj/project.pbxproj`.
4. Ajoutez la langue à l'énumération `AppLanguage` dans `LanguageManager.swift`.

## Licence

Ce dépôt ne contient pas actuellement de fichier `LICENSE` séparé.
