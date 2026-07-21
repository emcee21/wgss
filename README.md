# wigs

A minimal macOS ScreenSaver implementation that recreates the *WarGames* escalation sequence:

1. Simulated tic-tac-toe rounds
2. Escalation to global thermonuclear war scenarios
3. Final conclusion that the game is unwinnable and gives up

## Files

- `/home/runner/work/wigs/wigs/WarGamesScreenSaver/WarGamesScreenSaverView.swift`

## Build/use on macOS

1. Create a new **Screen Saver Extension** target in Xcode.
2. Replace the generated `ScreenSaverView` class with `WarGamesScreenSaverView.swift` from this repo.
3. Build the `.saver` bundle and install it in `~/Library/Screen Savers/`.
4. Enable it in **System Settings → Screen Saver**.

The saver renders green terminal text on black and continuously replays the scenario.
