# Monster in the Box

**A focus game for iPhone Duo that turns the hinge into a trap for your phone habit.**

Keep the phone folded shut and a little pixel cat builds you a city. Crack it open and the cat gets upset. Open it all the way, or snap another app into split screen, and the cat turns into a giant kaiju and flattens everything you built.

Built for **Bitrig Hacks** (iPhone Duo hackathon). Judges are looking for creative use of what's unique to the Duo: the two displays, the fold states, and side-by-side multitasking.

---

## The story

| Act | What the user does | What happens |
| --- | --- | --- |
| **1. Incubation** | Rests the phone closed to focus | On the outer display, the hero cat walks the roads of a top-down 8-bit town and builds towers floor by floor. When every tower is tall enough, a new district unlocks and the city spreads across the grass. |
| **2. Provocation** | Cracks the hinge open | The city fills the entire inner display, edge to edge across the fold, but it goes **dark**. The cat is hiding: **only its big red eyes** glow and blink out of the darkness. They only appear on the inner display, never on the closed phone's front screen. Opened sideways (vertical fold), they sit on the **right screen**, starting at its right edge and creeping toward the fold as the hinge opens. Opened upward (horizontal fold), they sit on the **bottom screen**, rising toward the fold. At 180° the eyes disappear and the city + kaiju take over. Nothing breaks yet. Haptics pulse, getting stronger the wider the hinge opens. |
| | Opens flat (180°) | The one cat turns into a **2× kaiju**. It hunts down and **eats the helper cats** that built the city ("CHOMP!") and smashes towers. The survivors flee. |
| **3. Rampage** | Opens flat (180°) | The kaiju destroys much faster, and the focus session is wiped. |
| **4. Neglect** | Sends the app to the background | The user never sees it happen, but acid rain falls while they're away. When they come back, the city has lost health and the buildings have rusted. |
| **5. Multitasking Trap** | Snaps another app into split screen | Instant kaiju rampage. Leaving split screen checks the hinge again: flat keeps the rampage going, cracked returns to warning, folded returns to building. |

### State table

| State | Hinge | Screen | Cat | City |
| --- | --- | --- | --- | --- |
| Incubation | Closed | Full screen | Builder cat walking the roads | Builds, then expands |
| Warning | Partially open (any angle < 180°) | Full screen | Hidden: only big red eyes in the dark | Untouched (a warning only) |
| Agitation | Currently unused (`agitationAngle` = 178°) | — | — | — |
| Rampage | 180° / fully open | Full screen | 2× kaiju, eating helper cats | Stomped rapidly |
| Neglect | Any | Background | Asleep (seen afterward) | Rusts and decays over time |
| Multitasking | Any (open) | Split screen | Kaiju cat | Stomped rapidly |

---

## How it works

- **Hinge:** `onHingeChange` → `DeviceHingeContext.hinge` (`status` + `angle`) → `KaijuEngine` decides the state.
- **Two displays:** closed = outer display (the builder game). Open = inner display, where the **city is stretched edge to edge** across both halves of the fold.
- **Fold region:** `ReservedRegion(.division)` moves the status banner to one side of the fold so its text never crosses the crease.
- **Split screen:** a compact horizontal size class *while the phone is open* means multitasking.
- **Background:** `scenePhase`. Decay is 1 health per 60 s away (1 per second in demo mode).
- **Haptics:** `UIImpactFeedbackGenerator` pulses from 15°, scaling linearly to full strength at 179°.
- **Effects:** SpriteKit particles (acid rain, dust, debris).

The world is a 19 × 19 tile grid (3 × 3 blocks). Roads run every 6th row and column, with 5 × 5 blocks between them. Cats move one tile at a time in 4 directions, only on roads, using BFS pathfinding. Towers stand on the bottom row of each block and grow upward. The city starts with the bottom-center block, which straddles the fold, and unlocks eight more.

---

## Running it

1. Open this folder in **Bitrig** (or `MonsterInTheBox.xcodeproj` with **Xcode 27.1**; it needs the iOS 27.1 SDK).
2. Build and run on the **iPhone Duo** simulator. Use the Fold controls (Closed / Partially Open / Fully Open), and drag the home indicator sideways for split screen.
3. **Debug drawer:** tap the status panel at the top of the screen.
   - **Simulate hinge:** a 0–180° slider, so you can test any state on any simulator.
   - **Simulate split screen**
   - **Demo speed:** on by default. Floors build every 2 s instead of 5 minutes, and decay runs every second.
   - **Reset City**
4. Haptics only play on a real device.

---

## Team split

Two people build in parallel without touching the same files:

| | Dev A: phone **closed** | Dev B: phone **open** |
| --- | --- | --- |
| Acts | 1 Incubation, 4 Neglect | 2 Provocation, 3 Rampage, 5 Multitasking |
| Folder | `MonsterInTheBox/Closed/` | `MonsterInTheBox/Open/` |
| Logic | `BuilderBrain` | `DestroyerBrain` |
| Plan | [docs/DEV_A_CLOSED.md](docs/DEV_A_CLOSED.md) | [docs/DEV_B_OPEN.md](docs/DEV_B_OPEN.md) |

`Engine/`, `Shared/`, and `App/` are shared, and nobody changes them during the sprint without telling the other person. See [CLAUDE.md](CLAUDE.md) for the full architecture and conventions.

## Project layout

```
MonsterInTheBox/
├── App/           Entry point + RootView (routing and hardware input)
├── Engine/Core/   KaijuEngine, GameState, GameTuning, hinge, haptics
├── Engine/World/  Grid, roads, lots, cats, pathfinding, brain protocol
├── Shared/        Rendering layers, sprites, effects, debug HUD
├── Closed/        Dev A: builder logic + closed-phone screens
├── Open/          Dev B: destroyer logic + open-phone screens
└── Assets.xcassets
assests/           Original art packs (the folder name is misspelled on purpose; don't rename it)
docs/              Per-developer plans
archive/removed/   Retired files kept for reference (not compiled)
```

## Art and credits

- **Cats** (`assests/cats`): all characters: the hero, citizens, and the kaiju (the hero scaled up).
- **City tiles:** [Kenney](https://kenney.nl) Pico-8 City, CC0.
- **Sprite Pack Monsters A** (bat, rat, slime) by **Red Chan / WithoutPenorPaper**, CC BY-NC 4.0. It's still in the asset catalog but **no longer shown**.
- The two "Cute Monsters" sprites were deliberately removed. There is no dungeon pack in the repo.
