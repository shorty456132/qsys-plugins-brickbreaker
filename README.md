# Brick Breaker (Q-SYS plugin)

Brick Breaker drawn as an SVG that looks like a touch panel main page, so the ball breaks the panel's buttons and AV controls. No device or network connection is involved.

The playfield shows a touch panel main page of 29 bricks: a header row, six source buttons, six room buttons, a volume strip and System Off. Tap the playfield to launch the ball, keep it up with the paddle, and break the panel one button at a time for 10 points each. The ball speeds up as the panel empties, ending 50% faster than it started. Clear the panel to win; run out of lives and the game is over. Either way, tap the playfield (or press New Game) to play again. Score, best score and lives are drawn along the bottom of the playfield, so `Screen` and `Paddle` are all a UCI needs.

## How it works

Every frame the plugin builds an SVG string, base64-encodes it and sets it as the `Screen` button's `Legend` (`DrawChrome = false`, `IconData = <base64>`). The game logic and renderer are pure Lua (`game.lua`, `level.lua`, `render.lua`) so they can be tested outside Q-SYS. The brick layer is cached and only rebuilt when a brick breaks. The bricks themselves are defined in `level.lua`.

## Properties

| Property | Type | Default | Purpose |
|---|---|---|---|
| Frame Rate | integer, 10 to 30 | 20 | Frames drawn per second |
| Lives | integer, 1 to 9 | 3 | Balls per game |

## Controls

| Control | Type | Purpose |
|---|---|---|
| Screen | Button (Trigger) | The playfield; tap it to launch the ball, or to start a new game after a win or loss. Logical size 1280x800; shown at 640x400 in the plugin panel |
| Paddle | Knob (0 to 1), shown as a horizontal fader | Drag to move the paddle; 0 is the left wall, 1 the right |
| Left, Right | Button (Momentary) | Paddle moves while held; the fader follows |
| Start | Button (Trigger) | New game: all bricks back, score cleared, lives refilled |
| Pause | Button (Toggle) | Freezes the game; ignored once the game is over |
| Score | Text indicator | 10 points per brick |
| HighScore | Text indicator | Best score so far; kept across New Game |
| GameState | Text indicator | Ready, Playing, Paused, You win or Game over |
| Lives | Text indicator | Balls remaining |
| Fps | Text indicator | Frames the Core drew in the last second, and the SVG size per frame |

## Setup

1. Compile, then double-click `Brick-Breaker.qplug` (or copy it to `Documents\QSC\Q-SYS Designer\Plugins`).
2. Drag the plugin into a design.
3. Drag `Screen` onto a UCI page and stretch it to fill the page (1280x800 on a 7 or 8 inch TSC). Put `Paddle` along the bottom at the same width, wider than it is tall, or use `Left` and `Right`.
4. Run on a Core (or emulate) and open the UCI on the panel.

## Pages

- **Game**: the playfield, the game controls and a diagnostics readout.

## Development

```
python tests/run_tests.py
python "C:/Workbench/av-module-maker/scripts/qsys/compile.py" . --bump=development
python tests/smoke_qplug.py
```

- `run_tests.py` runs the Lua specs in `tests/` against the pure game files, then `check_names.py`, which checks that control, property and page names agree across the source files.
- `smoke_qplug.py` plays the compiled `.qplug` against stubbed Q-SYS calls. It is a stand-in for Designer, not a replacement.
- The tests need Python with `lupa` installed.

Tuning lives at the top of `game.lua`: `LaunchVx` and `LaunchVy` (starting speed and angle), `MaxSpeedUp`, `PaddleSpeed`, `MaxBounceAngle` and `BrickPoints`.
