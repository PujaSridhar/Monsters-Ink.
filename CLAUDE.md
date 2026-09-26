# CLAUDE.md — Agent Guide for Monster in the Box

Read this before changing anything. It is the full context for continuing development. Read [README.md](README.md) for the story, and [docs/DEV_A_CLOSED.md](docs/DEV_A_CLOSED.md) / [docs/DEV_B_OPEN.md](docs/DEV_B_OPEN.md) for the per-developer task backlogs.

## 1. Goal and priorities

A SwiftUI game for **iPhone Duo** (Apple's foldable iPhone, Sept 2026) made for a hackathon. The phone's hinge controls the game: closed = a cat builds a city, open = the cat destroys it.

Priorities, in order:
1. **It works end to end and wows judges.** Judges reward creative use of Duo-specific APIs: hinge, two displays, fold region, split screen.
2. **Two developers can work in parallel without conflicts.**
3. Polish comes last. Don't spend time beautifying before the loop works.

## 2. Hard facts about this repo

- **The repo path ends in a period:** `/Users/Pujasridhar/Rutgers/Monsters-Ink.`. Quote it in shell commands.
- **The art folder is `assests/`** (misspelled). Don't rename it; the docs reference it.
- **Xcode 27.1 / iOS 27.1 SDK.** The deployment target is **iOS 27.1**, so Duo APIs need no availability guards.
- **The project uses synchronized folder groups** (`PBXFileSystemSynchronizedRootGroup`, objectVersion 77). Any file added under `MonsterInTheBox/` is compiled automatically. **Never hand-edit `project.pbxproj` to add files.**
- **Build settings:** Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency. Everything is MainActor by default. Protocol conformances used off the main actor (for example `Shape`) must be marked `nonisolated` (see `BubbleTail` in `Open/Views/MessageBubble.swift`).
- **`rm` may be blocked** by the sandbox. Retire files by moving them to `archive/removed/` (outside the target).
- **No git commits, branches, or pushes** unless the user explicitly asks.
- **Hinge debugging:** every real hinge change is logged (subsystem `com.monstersink.MonsterInTheBox`, category `Engine`) as `Hinge: <status> at <angle>° → <state>`. Read the simulator run log to see what the Fold controls actually report. The debug HUD also shows the angle and status live.
- **Building:** in Bitrig, use its build tool. Otherwise run `xcodebuild -project MonsterInTheBox.xcodeproj -scheme MonsterInTheBox -destination 'generic/platform=iOS Simulator' build`. Always build after changes.

## 3. Architecture

```
MonsterInTheBox/
├── App/
│   ├── MonsterInTheBoxApp.swift   WindowGroup { RootView() }
│   └── RootView.swift             owns KaijuEngine; routes Closed/Open; feeds onHingeChange,
│                                  horizontalSizeClass, scenePhase; presents NeglectReportView
├── Engine/                        MODEL: no SwiftUI views (except SwiftUI hinge types in HingeReading)
│   ├── Core/
│   │   ├── KaijuEngine.swift      @Observable single source of truth + 10 Hz game loop
│   │   ├── GameState.swift        6 states, title/subtitle/symbol, mode, destruction rate, isKaiju
│   │   ├── GameTuning.swift       ALL gameplay numbers (timers, speeds, thresholds)
│   │   ├── HingeReading.swift     DeviceHingeContext → plain value; HingeStatus enum
│   │   ├── HapticsController.swift UIImpactFeedbackGenerator; linear 15°→179° intensity
│   │   └── NeglectReport.swift
│   └── World/
│       ├── GridPoint.swift        cell + 4-way Direction
│       ├── CityLayout.swift       fixed 19×19 grid (3×3 blocks), roads every 6th row/col, BlockID, expansion order
│       ├── Lot.swift              tower plot (floors, rust, rubble) + BuildingStyle
│       ├── CityMap.swift          developed blocks, roads, lots; Ground; build/remove/rust/expand
│       ├── Pathfinder.swift       BFS
│       ├── CatActor.swift         a cat: position, path, facing, activity, stepDuration
│       ├── CityWorld.swift        CityActors (hero + citizens), CityWorld (map + actors + movement helpers)
│       └── CatBrain.swift         CatBrain protocol, BrainContext, WorldEvent
├── Shared/                        VIEWS used by both modes
│   ├── World/                     WorldStage (layers), GroundLayer (Canvas), BuildingLayer/TowerSprite,
│   │                              CatSprite/CatAnimation/ActorView, TileArt (tile indices), WorldMetrics
│   ├── Assets/                    GameAsset enum, SpriteSheet (cached cropping), PixelSprite/CityTile/AnimatedSprite
│   ├── Effects/                   EffectsScene/EffectsLayer (SpriteKit), HingeGapGlow (unused now; red fold line was removed)
│   └── HUD/StateVisualizer.swift  status HUD + debug drawer (simulate hinge/split, demo speed, reset)
├── Closed/                        DEV A: phone closed (building)
│   ├── Logic/BuilderBrain.swift
│   ├── Views/BuilderActorsLayer.swift, FocusHUD.swift, NeglectReportView.swift
│   └── ClosedGameView.swift
└── Open/                          DEV B: phone open (destroying)
    ├── Logic/DestroyerBrain.swift (hunt + eat cats, smash towers), CatMood.swift,
    │         GameState+Open.swift (catMood, showsOnlyEyes, heroScale)
    ├── Views/CityBoard.swift (WorldStage fillsScreen, edge to edge), DestroyerActorsLayer.swift
    │         (dark + HidingEyes at warning; 2× kaiju, citizens, CHOMP! pop, bubble otherwise),
    │         HidingEyes.swift, MessageBubble.swift, StatusBanner.swift (fold-aware via ReservedRegion)
    └── OpenGameView.swift         CityBoard + red mood tint + banner (hidden at warning)
```

### Data flow (one tick, 10 Hz)

```
RootView input → KaijuEngine.state (derived) → state.mode
   .building   → BuilderBrain.tick(world:&, context)   ─┐
   .destroying → DestroyerBrain.tick(world:&, context) ─┼→ [WorldEvent]
   .paused     → nothing (neglect)                      ─┘
CityWorld.tickCitizens (shared)
engine.map / engine.actors assigned ONLY if changed
engine.apply(events) → cityHealth, counters, lastChangedLot, haptics
Views observe engine.map (ground + towers) and engine.actors (cats) separately
```

### State rules (in `KaijuEngine.state`)

Checked in this order:
1. Backgrounded → `.neglect`
2. `isMultitasking` → `.multitasking`, where `isMultitasking` = compact width **and** hinge not closed. The closed outer display is also compact, so without that check, closing the phone would trigger a rampage.
3. Hinge closed (as reported by the system) → `.incubation`. The **outer display never shows the eyes**; it always shows the builder city. The eyes appear only on the inner display, from the first reported partial opening.
4. `.fullyOpen` or ≥ 178° → `.rampage` (kaiju at 2×, smashes at 3 floors/s)
5. ≥ `agitationAngle` → `.agitation`. This is **currently unreachable**, because `agitationAngle` = `rampageAngle` = 178°; the user wants the eyes for every partial angle.
6. Otherwise → `.warning`: the cat hides. Nothing is destroyed, every cat freezes (`GameState.freezesCitizens`), the city goes dark, and **only big red blinking eyes** (`HidingEyes`) are visible. `HidingEyesStage` moves them with the angle: with a vertical fold (opened sideways) they stay on the **right screen**, going from its right edge toward the fold. With a horizontal fold (opened upward) they stay on the **bottom screen**, going from its bottom edge toward the fold. They never cross the fold. The fold axis comes from `ReservedRegion(.division)`, falling back to the screen shape.

**One cat, one kaiju.** There's a single hero cat. On the open phone it becomes the kaiju (2×) and **hunts the citizen cats that helped build the city**:
- **Eating:** any citizen within `GameTuning.huntRadius` (7) is chased, and one within `eatRadius` (1) is eaten. That emits `WorldEvent.catEaten`; the engine then bumps `catsEatenCount` and `lastEatenPosition`, and fires a haptic slam.
- **Smashing:** with nobody to chase, it smashes the nearest tower.
- **Fleeing:** citizens flee to roads far from the kaiju (`tickCitizens(fleeingFrom:)`).
- **Replacements:** a city starts with `startingCitizens` (3) helpers, plus one per developed block. Eaten cats are **not** replaced otherwise (a possible Dev A task).

Entering a kaiju state wipes `focusSeconds` and fires a haptic slam. Every state change calls the incoming brain's `enter(_:world:)`, which also resets the build timer. Split-screen recovery needs no special code: the state is re-derived from the current hinge.

## 4. Invariants (don't break these)

1. **The engine is the single source of truth.** Views never mutate game state. Only `RootView` feeds input, and only `StateVisualizer` uses `simulate…` / `resetCity`.
2. **Brains mutate only `CityWorld`** (map + actors) and report what happened as `WorldEvent`s. Health, counters, and haptics are applied by the engine in `apply(_:)`.
3. **Map and actors stay separate.** They're separate engine properties, separate layers, and assigned back only when changed (`if world.map != map`), so the ground Canvas doesn't redraw on every cat step.
4. **Movement is on the grid.** One tile per step, 4-way, via `CatActor.walk(path)` + `advance(dt:)`. Re-routing mid-walk keeps the step timer, so chasing works. Normal cats use `WalkRule.roads`; only the smashing hero (flat or split screen) uses `.anywhere`. The view (`ActorView`) interpolates between tiles with `.linear(duration: stepDuration)`.
5. **Rendering layers go ground → buildings → actors** inside `WorldStage`. Each mode passes its own actors layer through the `WorldStage { metrics in … }` closure. New visual things belong in a new layer view, not in the engine.
6. **Pixel art is drawn with `.interpolation(.none)`** (`SpriteSheet.frame` and `PixelSprite` already do this). In SpriteKit, use `filteringMode = .nearest`.
7. **Every number goes in `GameTuning`.**
8. **Ownership:** Dev A edits `Closed/`, Dev B edits `Open/`. `Engine/`, `Shared/`, and `App/` change only in small, announced commits. When an agent works for one dev, it stays in that dev's folder unless told otherwise.

## 5. Verified iPhone Duo APIs (iOS 27.1 SDK, declared in the SwiftUICore interface)

The docs search may not index these yet. These signatures were read from the SDK:

- `View.onHingeChange(isEnabled: Bool = true, _ action: (DeviceHingeContext, DeviceHingeContext) -> Void)`
- `DeviceHingeContext.hinge: DeviceHinge?` (nil on devices without a hinge)
- `DeviceHinge.status: DeviceHinge.Status` and `DeviceHinge.angle: Angle`
- `DeviceHinge.Status` is a **struct** with `.closed`, `.partiallyOpen`, and `.fullyOpen`. It **can't be switched exhaustively**, so convert it with `HingeStatus(_:)`.
- `ArrangementView(primary:secondary:)` plus `.arrangementViewStyle(.split / .overlay)`, and the `overlayArrangementZIndex` environment value. **Not currently used:** the user wants the city to span the entire screen, so the open view is one full-screen `CityBoard` (`WorldStage(fillsScreen: true)` stretches tiles to fill; `WorldMetrics` has `tileWidth`/`tileHeight`, and sprites use the square `tileSize`). Put backgrounds on or behind the ArrangementView, never inside the panes. Never nest it inside `ScrollView`, `List`, or `NavigationSplitView`.
- `GeometryProxy.reservedRegions(kind: .division | .occlusion, options:, layoutDirectionBehavior:) -> [ReservedRegion]`. A `ReservedRegion` has `frame`, `margins`, and `isActive`. `.division` is the fold, and it's active only while partially folded.
- Hinge data is for **interactions and effects**. Layout uses size classes, `ArrangementView`, and reserved regions.

Duo facts:
- The outer display is 5.4" (compact width). The inner display is 7.6" (regular/regular).
- The status bar and toolbars sit in a vertical strip on the outer display.
- Split View on the inner display gives each app half the width (compact).
- Bitrig's simulator has Fold controls (Closed / Partially Open / Fully Open). Agents can't fold it; only the user can. Use the debug drawer's **Simulate hinge** instead.

## 6. Assets

The asset names are in `Shared/Assets/GameAsset.swift`, and the source files are in `assests/`.

| Asset | Format | Role |
| --- | --- | --- |
| `Cat0` | 32×128, 4 frames | idle (`CatAnimation.idle`) |
| `Cat1` | 32×224, 7 frames | sit → lie down (`.sleep`) |
| `Cat2` | 32×192, 6 frames | stepping, used as the walk cycle (`.walk`) |
| `Cat3` | 32×192, 6 frames | pounce, used for hammering and kaiju stomps (`.pounce`) |
| `Cat4` | 32×832, 26 frames | grooming (`.groom`) |
| `Cat5` | 32×96, 3 frames | icons: arrow, small paw, big paw |
| `CatBox` | 32×64, 2 frames | frame 0 = closed box (logo), frame 1 = cat peeking (unused since `PeekingCatView` was archived) |
| `CityTiles` | 192×120, 24×15 tiles of 8×8 | Kenney tilemap; index = row × 24 + col |
| `CitySample` | Kenney sample scene | optional backdrop |
| `Slime/Bat/Rat` + `Neutral/Angry/Hurt` | large painted PNGs | **unused**: the user asked for the rats and nest to be removed (CC BY-NC, credit Red Chan if used) |

- **Cat frames** are 32×32, stacked vertically. The cat only fills the middle of the frame, so `ActorView` draws it at 2.5× the tile size. All cats are the same white sprite, tinted per `CatLook`, and flipped when facing left.
- **Tile indices** are in `TileArt`:
  - grass 0/24/48, pavement 3/27, asphalt 291, bush 310, palm 263, cars 275/299/323
  - towers (roof/middle/base): purple 169/217/241, pink 174/222/246, white 179/227/251, gray 184/232/256
  - rubble 189–191
- **Removed on purpose:** the two "Cute Monsters" sprites, the right-side Monster Nest, the box cat (`PeekingCatView`), the minions, and the red fold line are all retired (in `archive/removed/` where applicable). Don't reintroduce them. There's no dungeon pack.
- **Red eyes:** `CatSprite(hasRedEyes:)` draws small glowing dots at about (17, 16) and (20, 16) of the 32×32 idle frame (only on `.idle`); the kaiju uses these. The warning state's big eyes are a separate view, `Open/Views/HidingEyes.swift`.

## 7. How to extend (recipes)

- **New behavior for the closed or open cat:** edit `BuilderBrain` or `DestroyerBrain`. Mutate `world`, and return `WorldEvent`s.
- **A new kind of event** (for example "citizen scared"): add a case to `WorldEvent`, handle it in `KaijuEngine.apply`, and expose a counter for views. This is a shared change, so announce it.
- **A new visual layer** (paw trail, props, rubble spray): create a view in `Closed/Views` or `Open/Views` that takes `WorldMetrics`, and add it inside that mode's `WorldStage { metrics in … }` closure. Use `metrics.rect(of:)` / `center(of:)` to position it.
- **A new tuning value:** add it to `GameTuning`.
- **Open-only per-state data:** add an extension on `GameState` in `Open/Logic/GameState+Open.swift`, and do the same in `Closed/Logic` for closed-only data.
- **A new cat animation:** add a case to `CatAnimation` (`Shared/World/CatSprite.swift`).
- **A new block layout or size:** change `CityLayout`. Everything derives from `blockSize`, `blockColumns`, `blockRows`, and `expansionOrder`.

## 8. Current status

**Done (builds cleanly):**
- The engine, all six states, hinge/size-class/scene-phase input, simulated input, demo mode, and haptics.
- The 2D grid world with roads, lots, towers, block expansion, BFS movement, and citizens.
- `BuilderBrain`: wander → walk to the shortest tower → hammer → floor → expand.
- `DestroyerBrain`: at warning the cat hides (everything freezes, no damage); when flat (180°) or in split screen the 2× kaiju hunts and eats citizen cats, and otherwise smashes the nearest tower.
- Closed screen: map, builder layer, focus HUD, and neglect sheet.
- Open screen: the city stretched edge to edge across the whole inner display. At warning, darkness with only big red blinking eyes. At 180° or in split screen, the 2× kaiju hunts and eats citizen cats ("CHOMP!") and smashes towers, with a red tint, a fold-aware status banner, and dust/debris.

**Not yet verified:** nobody has run it in the simulator after the 2D rewrite. First steps for the next agent:
1. Run it and check that the tile indices, cat frame alignment (`ActorView` y-offset `size * 0.3`), and kaiju scale look right.
2. Check that cats face the right direction; the sprite is assumed to face right.
3. Check the eye size and position at warning (`HidingEyes`, width = 5 tiles), that the kaiju catches cats (tune `kaijuStep`, `fleeStep`, `huntRadius`), and that the stretched tiles look acceptable on the inner display.

**Backlog:** see the task lists in `docs/DEV_A_CLOSED.md` and `docs/DEV_B_OPEN.md`.
- Highest value for the demo: stomp shake + debris at the lot, the kaiju transformation moment, the block-unlock banner, and the split-screen banner.

## 9. Code conventions

- SwiftUI + `@Observable`. Read the engine with `@Environment(KaijuEngine.self)`. No `ObservableObject`.
- One primary type per file (small private helpers are fine). Put the model in `Engine/`, not in views.
- Prefer `var` in structs, trailing closures, SF Symbols over emoji, spring animations (`.bouncy`, `.smooth`, `.snappy`), and `.sensoryFeedback` for UI haptics.
- Give interactive elements accessibility labels; hide decorative sprites (`accessibilityHidden`).
- Don't name types after framework types (no `Button`, `ProgressView`, and so on).
- No `#Preview` / `PreviewProvider`.
- If the type checker complains ("unable to type-check… in reasonable time"), split the view body into helper properties or functions. `RootView` already does this.
- Don't read and mutate the same dictionary in one expression (Swift exclusivity errors). Iterate over `(key, value)` instead.
