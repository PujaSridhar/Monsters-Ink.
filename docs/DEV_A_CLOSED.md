# Dev A — Phone CLOSED: The Builder Cat (Outer Display)

You own **Act 1: Incubation** and **Act 4: Neglect**. That's the top-down 8-bit town on the 5.4" outer display, where the hero cat walks the roads and builds towers while the phone stays shut, plus the rusted aftermath after the app was backgrounded.

Dev B owns the open phone (the cat destroying the city). **You never touch the same files.** Your logic and views live in `Closed/`, theirs in `Open/`.

---

## How the game is put together

```
MonsterInTheBox/
├── App/            RootView: routes closed ↔ open, feeds hinge/size/scene input      (shared, frozen)
├── Engine/
│   ├── Core/       KaijuEngine, GameState, GameTuning, haptics, hinge                (shared, frozen)
│   └── World/      Pure game model: grid, roads, lots, cats, pathfinding             (shared, frozen)
├── Shared/
│   ├── World/      Rendering layers: WorldStage, GroundLayer, BuildingLayer, ActorView (shared)
│   ├── Assets/     SpriteSheet, GameAsset, PixelSprite                               (shared)
│   ├── Effects/    SpriteKit acid rain / dust, fold glow                             (shared)
│   └── HUD/        State Visualizer + debug drawer                                   (shared)
├── Closed/         ◀── YOU
│   ├── Logic/BuilderBrain.swift        what the cat does while closed
│   ├── Views/BuilderActorsLayer.swift  how builder cats are drawn
│   ├── Views/FocusHUD.swift            timer + progress + city size
│   ├── Views/NeglectReportView.swift   "while you were away" sheet
│   └── ClosedGameView.swift            composes the screen
└── Open/           ◀── Dev B (DestroyerBrain, DestroyerActorsLayer, MonsterNest, …)
```

**Separation rules:**
- **Logic vs. views.** `BuilderBrain` decides *where the cat goes and what it builds*. It mutates the model only. Views only draw the model.
- **Map vs. cats.** The city (`CityMap`: roads, lots, towers) and the cats (`CityActors`: hero plus citizens) are separate engine properties and separate layers. Drawing a cat never redraws the map.
- **Shared layers are frozen during the sprint.** If you need a change in `Engine/` or `Shared/`, make it one small commit and tell Dev B.
- New files dropped into `Closed/` are picked up automatically (folder-synced project). No project-file edits needed.

## The world (top-down, 8-bit, 2D grid)

`CityLayout` is a 13 × 19 tile grid. Roads run along every 6th row and column; between them are 5 × 5 blocks. Each block's bottom row is 5 lots facing the road. Towers stand on a lot and grow **upward** into the block (roof + middles + base), up to 4 floors, like buildings in Pokémon towns.

- **Movement is 2D and grid-restricted.** Cats move one tile at a time in 4 directions, only on developed road tiles (`CityWorld.WalkRule.roads`), using BFS pathfinding (`Pathfinder`). The view glides them between tiles.
- **The city expands.** It starts with one developed block surrounded by grass and trees. When every tower is at least `GameTuning.floorsToExpand` (2) floors, the next block in `CityLayout.expansionOrder` opens: new roads appear, 5 new lots appear, and a new citizen cat moves in. Six blocks in total.

## What `BuilderBrain` does now (working baseline)

1. **Wandering:** the hero cat strolls to random nearby road tiles while the build timer fills.
2. **Job:** when `buildInterval` elapses (2 s in demo mode, 5 min for real), it picks the shortest tower (nearest first) and paths to the road tile in front of it.
3. **Building:** it faces the lot, plays the pounce animation with a bouncing hammer for `GameTuning.buildDuration`, then adds a floor and emits `.floorBuilt`.
4. **Expanding:** if every tower has reached the threshold, it develops the next block and emits `.blockDeveloped`.

The engine turns those events into health, counters, and haptics. The brain never touches them directly.

## Engine API you read (`@Environment(KaijuEngine.self) private var engine`)

| Property | Use it for |
| --- | --- |
| `engine.map` | Pass to `WorldStage(map:)`. Also `totalFloors`, `developedBlocks`, `lots` |
| `engine.actors.hero` / `.citizens` | Positions, `facing`, `activity`, `isMoving` |
| `engine.builder.phase` / `.targetLot` | What the builder is doing and where it's heading |
| `engine.buildProgress` | 0…1 toward the next job |
| `engine.focusSeconds` | Focus timer (wiped by a rampage) |
| `engine.floorsBuiltCount`, `blocksDevelopedCount`, `lastChangedLot` | Animation and haptic triggers |
| `engine.neglectReport` | `secondsAway`, `healthLost` for the aftermath sheet |

## Shared building blocks

- `WorldStage(map:) { metrics in YourActorsLayer(metrics:) }`: ground + towers + your actors layer, scaled to fit.
- `ActorView(actor:metrics:scale:)`: places and animates any `CatActor` on the grid.
- `CatSprite(look:animation:facesLeft:)`: a bare cat. Animations: `.idle` (Cat0), `.sleep` (Cat1), `.walk` (Cat2), `.pounce` (Cat3), `.groom` (Cat4).
- `metrics.rect(of:)` / `metrics.center(of:)`: grid cell → points, for anything you overlay.
- `TileArt`: tile indices for grass, roads, pavement, bushes, palms, cars, and each tower style.
- `EffectsLayer(acidRain:)`: SpriteKit rain.

---

## Tasks (priority order)

### Must-have
1. **Construction juice.** When `floorsBuiltCount` changes, pop a dust puff or sparkle at `lastChangedLot` (use `metrics.center(of:)`). Make the new top floor "drop in" (in `BuilderActorsLayer`, overlay a tile that animates from above).
2. **Block-unlock moment.** On `blocksDevelopedCount` change, flash the new block's tiles and show a banner like "New district unlocked!" in `ClosedGameView`.
3. **Outer display layout pass.** In the iPhone Duo simulator, set Fold to Closed and check portrait and landscape. The status bar sits in a vertical strip on the outer display, so keep the HUD clear of that edge. Tune `WorldStage` padding if the map is too small.
4. **Paw-print trail.** Leave fading `Cat5` paw prints (frame 1) on the last few tiles the hero walked. Keep the trail in your actors layer, not the engine.

### Should-have
5. **Neglect sheet polish.** Count `healthLost` up with `.contentTransition(.numericText())`, and fade the rain out after 3 s.
6. **Parked cars and street life.** Draw `TileArt.cars` on some road tiles next to lots. Make it a new `Closed/Views/StreetPropsLayer.swift` and insert it into your `WorldStage` actors closure *below* the cats.
7. **Smarter builder** (in `BuilderBrain` only): chat with a citizen it passes (both stop, face each other, 1 s), or nap (`.sleeping`) if nothing's left to build.

### Stretch
8. A day/night tint driven by `focusSeconds`.
9. Tower tiers: newer blocks use a fancier `BuildingStyle`. This is the "swap the city texture based on focus time" idea from the spec, and it needs a one-line change in `CityMap.developNextBlock`, so tell Dev B.

---

## How to test

- **Any simulator:** tap the State Visualizer HUD to open the debug drawer. Turn on **Simulate hinge** and leave it at 0° for Incubation. **Demo speed** (on by default) builds every 2 seconds, so the first block fills in about a minute.
- **Neglect:** swipe home, wait about 10 s, and reopen. The decay is 1 health per second in demo mode.
- **iPhone Duo simulator:** Bitrig's Fold control → Closed.
- **Reset City** in the debug drawer starts over.

## Asset map (your side)

| Asset | Where it's used |
| --- | --- |
| `Cat0`, `Cat2`, `Cat3` | Hero cat idle / walking / hammering |
| `Cat1` | Sleeping cat in the neglect sheet |
| `Cat4` | Citizens grooming while idle |
| `Cat5` | Paw prints (target marker; trail is task 4) |
| `CityTiles` | Grass, roads, yards, towers, rubble, props |
| `CatBox` | Logo: the monster in the box (frame 0 = closed box) |
