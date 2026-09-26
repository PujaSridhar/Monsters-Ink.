# Dev B — Phone OPEN: The Destroyer Cat (Inner Display)

You own **Act 2: Provocation** (Warning and Agitation), **Act 3: Rampage**, and **Act 5: Multitasking Trap**. That's everything on the 7.6" inner display, from the first crack of the hinge to fully flat and split screen.

Dev A owns the closed phone (the cat building the city). **You never touch the same files.** Your logic and views live in `Open/`, theirs in `Closed/`.

---

## How the game is put together

```
MonsterInTheBox/
├── App/            RootView: routes closed ↔ open, feeds hinge/size/scene input      (shared, frozen)
├── Engine/
│   ├── Core/       KaijuEngine, GameState, GameTuning, haptics, hinge                (shared, frozen)
│   └── World/      Pure game model: grid, roads, lots, cats, pathfinding             (shared, frozen)
├── Shared/
│   ├── World/      WorldStage, GroundLayer, BuildingLayer, CatSprite (red eyes), ActorView (shared)
│   ├── Assets/     SpriteSheet, GameAsset, PixelSprite                               (shared)
│   ├── Effects/    SpriteKit dust / debris                                           (shared)
│   └── HUD/        State Visualizer + debug drawer                                   (shared)
├── Closed/         ◀── Dev A (BuilderBrain, BuilderActorsLayer, FocusHUD, …)
└── Open/           ◀── YOU
    ├── Logic/DestroyerBrain.swift        hide → hunt & eat helper cats → smash towers
    ├── Logic/CatMood.swift               bubble lines (annoyed, at 90°)
    ├── Logic/GameState+Open.swift        catMood, showsOnlyEyes, heroScale per state
    ├── Views/CityBoard.swift             the city stretched edge to edge + debris
    ├── Views/DestroyerActorsLayer.swift  dark + eyes at warning; 1.5× kaiju, citizens, CHOMP! pop
    ├── Views/HidingEyes.swift            big red slit-pupil eyes that pulse and blink
    ├── Views/MessageBubble.swift         iMessage-style bubble
    ├── Views/StatusBanner.swift          subtitle, kept off the fold via ReservedRegion
    └── OpenGameView.swift                CityBoard + mood tint + banner
```

**Separation rules:**
- **Logic vs. views.** `DestroyerBrain` decides *where the cat goes and what it smashes*. It mutates the model only. Views only draw the model.
- **Map vs. cats.** The city (`CityMap`) and the cats (`CityActors`) are separate engine properties and separate layers. The cat moving never redraws the map; only a floor falling does.
- **Shared layers are frozen during the sprint.** If you need a change in `Engine/` or `Shared/`, make it one small commit and tell Dev A.
- New files dropped into `Open/` are picked up automatically. No project-file edits needed.

## The world: one city across the entire screen

A 19 × 19 top-down tile grid (`CityLayout`, 3 × 3 blocks). `WorldStage(fillsScreen: true)` stretches the tiles (`WorldMetrics.tileWidth` ≠ `tileHeight`) so the city covers **the entire inner display, edge to edge**, ignoring safe areas, across both halves of the fold. Cats and effects use the square `metrics.tileSize`, so they never stretch. The first block is bottom-center, straddling the fold. Whatever Dev A's cat built while the phone was closed is what you destroy.

There is no right-side panel anymore. The Monster Nest, the box cat, the rat/bat/slime minions, and the red fold line were removed at the user's request (see `archive/removed/`).

## The opening story (current behavior)

| Hinge | State | What happens |
| --- | --- | --- |
| Cracked (< 75°) | `.warning` | **The cat hides.** The city goes dark (88% black) and every cat freezes. **Only a pair of big glowing red slit-pupil eyes** is visible at the cat's position; they pulse, glance, blink every ~3.4 s, and grow with the hinge angle. The banner is hidden. **Nothing is destroyed yet.** Haptics pulse. |
| 90° (≥ 75°) | `.agitation` | The one cat becomes a **1.5× kaiju** (`heroScale`). It ignores roads and **hunts the helper cats** (any within `huntRadius` 7). It **eats** any within `eatRadius` 1 ("CHOMP!" + haptic), and when nobody's near it smashes the nearest tower at 0.5 floors/s. Survivors flee to roads far away. A red bubble ("I SAID close it."). |
| 180° / flat | `.rampage` | Same 1.5× kaiju, smashing at 3 floors/s. The focus session is wiped. |
| Split screen | `.multitasking` | Same as rampage. |

The engine already handles:
- The state from the hinge, split-screen detection, and recovery (see `CLAUDE.md` §3).
- A rampage wipes `focusSeconds` and fires a heavy haptic slam. Each tower that collapses slams again.
- Haptic pulses start at 15° and scale linearly to 179°.

The tuning knobs:
- **`GameTuning`:** `agitationFloorsPerSecond`, `rampageFloorsPerSecond`, `kaijuStep` (0.24), `fleeStep` (0.28), `huntRadius`, `eatRadius`, `startingCitizens` (3), and `agitationAngle`.
- **`Open/Logic`:** `GameState.heroScale`.

Eaten cats are not replaced, except for one new helper per developed block. Topping them back up while closed would be a `BuilderBrain` (Dev A) change.

## Engine API you read (`@Environment(KaijuEngine.self) private var engine`)

| Property | Use it for |
| --- | --- |
| `engine.state` | `.showsOnlyEyes`, `.catMood`, `.heroScale`, `.isKaiju`, `.isDestructive`, `.floorsDestroyedPerSecond`, `.subtitle` |
| `engine.map` | Pass to `WorldStage(map:)`. Also `standingLots`, `totalFloors` |
| `engine.actors.hero` / `.citizens` | Position, `facing`, `activity` (`.stomping` when smashing), `isMoving` |
| `engine.destroyer.target` / `.preyID` | The tower being smashed / the cat being hunted |
| `engine.catsEatenCount`, `lastEatenPosition` | Chomp effects and haptics |
| `engine.hapticIntensity` | 0…1, same curve as the haptics. Use it to drive shake and redness |
| `engine.floorsDestroyedCount`, `lastChangedLot` | Debris bursts, screen shake, `.sensoryFeedback` |
| `engine.cityHealth`, `engine.isMultitasking` | Health bar, split-screen banner |

## Shared building blocks

- `WorldStage(map:fillsScreen:) { metrics in … }`: ground + towers + your actors layer.
- `ActorView(actor:metrics:scale:hasRedEyes:)`: places and animates a cat. Red eyes only render on the idle animation.
- `CatSprite(look:animation:facesLeft:hasRedEyes:)`: `.pounce` (Cat3) is the smash.
- `EffectsLayer(dust:burstTrigger:)`: SpriteKit dust plus a debris burst each time the trigger changes.
- `metrics.center(of:)`: aim effects at `lastChangedLot`.

---

## Tasks (priority order)

### Must-have
1. **Verify on the simulator:** the stretched tiles look OK, the eyes read well in the dark, and the kaiju actually catches cats. Tune `kaijuStep` / `fleeStep` / `huntRadius` if not.
2. **Eating juice.** On `catsEatenCount`, shake the board, burst debris at `lastEatenPosition` (`EffectsScene.burst(at:)`), and play the pounce frame bigger for a beat.
3. **Eyes → kaiju reveal.** When warning turns into agitation, have the eyes rush toward the viewer and flash before the 1.5× cat appears.
4. **Split-screen banner.** When `engine.isMultitasking`, show "CLOSE THE OTHER APP" in red.

### Should-have
5. **Score the carnage:** a "Cats eaten: N" and towers-lost counter in the banner area.
6. **Smarter hunting** (in `DestroyerBrain` only): prefer cats hiding near tall towers, or pounce (a 2-tile jump) when prey is exactly 2 away.
7. **Eyes that track:** move `HidingEyes` slowly toward the side of the fold the user touched last, or peek from behind the tallest tower.

### Stretch
8. Rubble spreading onto the road after a collapse (a new `Open/Views/RubbleLayer.swift` below the cats).
9. A camera zoom toward the kaiju during rampage (`scaleEffect` on `CityBoard` anchored at the hero).

---

## How to test

- **Any simulator:** tap the State Visualizer HUD → **Simulate hinge**.
  - **0°** for about 30 s: builds the city (demo speed).
  - **10°:** darkness, only the red eyes.
  - **90°:** 1.5× kaiju hunting and eating cats, smashing towers.
  - **180°:** the same kaiju, destroying faster.
  - **Simulate split screen** for the trap.
- **iPhone Duo simulator:** Fold → Partially Open (the banner moves off the fold), Fully Open (rampage).
- **Haptics** only play on a real device.

## Asset map (your side)

| Asset | Where it's used |
| --- | --- |
| `Cat0` | Idle cats (the kaiju's small red eyes are drawn over its eye pixels) |
| `Cat2` | Walking and fleeing |
| `Cat3` | Smashing (pounce) |
| `CityTiles` | Grass, roads, towers, rubble (tiles 189–191) |

Credit line for the demo: city tiles by Kenney (CC0).
