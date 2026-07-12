# Roblox Minesweeper

A **multiplayer Minesweeper game** for Roblox with matchmaking, round-based gameplay, and leaderboards.

## Systems

- **Match Management** — Server-authoritative match lifecycle: countdown, playing, finished. Difficulty selection with configurable grid sizes (width, height, mine count).
- **Board Generation** — Procedural mine placement with number calculation. Guaranteed solvable first click.
- **Reveal System** — Flood-fill reveal for empty cells. Server-validated cell interactions.
- **Flag System** — Right-click to flag/unflag suspected mines. Visual indicator.
- **Win Checking** — Real-time win condition detection (all non-mine cells revealed).
- **Timer** — Per-round match timer tracking completion time.
- **Leaderboard** — Persistent leaderboard tracking best times per difficulty.
- **Client-Side Rendering** — Board renderer with cell factory, themes, and animations.
- **Achievements** — Stat tracking and achievement system.

## Architecture

| Module | Role |
|---|---|
| `MatchManager` | Match state machine (Idle → Countdown → Playing → Finished) |
| `GameRoundManager` | Round lifecycle: board operations, reveal, flag, win check |
| `BoardManager` | Board data structure and cell management |
| `MineGenerator` | Procedural mine placement algorithm |
| `NumberCalculator` | Adjacent mine count calculation |
| `BoardSerializer` | Board serialization for client-server transfer |
| `RoundFlowController` | Server-side round orchestrator |
| `ServerLobbyController` | Player lobby and matchmaking |
| `ClientBoardSync` | Client board state synchronization |
| `BoardRenderer` | Client-side visual board rendering |

## Tech

- **Language:** Luau
- **Engine:** Roblox
- **Build:** Rojo (`default.project.json`)
- **Pattern:** Modular service architecture, server-authoritative
