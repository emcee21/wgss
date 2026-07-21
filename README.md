# wgss

A minimal macOS ScreenSaver implementation that recreates the *WarGames* escalation sequence with both text **and visuals**:

1. Simulated tic-tac-toe rounds with an animated board
2. Escalation to global thermonuclear war scenarios with map/target visuals
3. Final conclusion that the game is unwinnable and gives up

## Source

- `WarGamesScreenSaver/WarGamesScreenSaverView.swift` contains the animation.
- `WarGamesScreenSaver/wgss/wgss.xcodeproj` builds the installable `wgss.saver` bundle.

## Install locally

Requires macOS 13 or newer and Xcode with the macOS SDK installed.

```sh
./scripts/install-local.sh
```

The script builds an ad-hoc-signed release bundle, installs it at
`~/Library/Screen Savers/wgss.saver`, and verifies its signature. Then select
**wgss** in **System Settings → Screen Saver**.

To build without installing:

```sh
xcodebuild \
  -project WarGamesScreenSaver/wgss/wgss.xcodeproj \
  -scheme wgss \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY=- \
  build
```

The bundle will be written to `build/Build/Products/Release/wgss.saver`.

The saver renders green terminal text on black, animates scenario visuals, and continuously replays the sequence.
