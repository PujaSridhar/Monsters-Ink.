# Dev B — Phone OPEN (Inner Display)

You own **Act 2: Provocation** (Warning and Agitation), **Act 3: Rampage**, and **Act 5: Multitasking Trap**. That's everything on the 7.6" inner display, from the first crack of the hinge to fully flat and split screen.

Dev A owns the closed outer display and the neglect aftermath. You never edit the same files, so you can both work at the same time without merge conflicts.

---

## Your files (only edit these)

| File | What it is | Status |
| --- | --- | --- |
| `MonsterInTheBox/Open/OpenGameView.swift` | `ArrangementView` root, sky color, fold glow, kaiju overlay | Working baseline |
| `MonsterInTheBox/Open/CityBoard.swift` | Primary pane: city under attack, fleeing cats, dust | Working baseline |
| `MonsterInTheBox/Open/MonsterNest.swift` | Secondary pane: the cat in the box (pleading, then annoyed) plus a minion | Working baseline |
| `MonsterInTheBox/Open/*.swift` | Any new file you add here is picked up automatically | — |

The project uses **folder-synced groups**, so adding a new `.swift` file needs no project-file edits.

**Don't edit** `Engine/`, `Shared/`, or `App/RootView.swift` without telling Dev A.

---

## How your screen gets shown

`RootView` shows `OpenGameView` whenever the hinge isn't `.closed`, or whenever the app is in split screen. States you'll see: `.warning`, `.agitation`, `.rampage`, `.multitasking`.

### The opening story (what the user sees)

| Hinge | State | On screen |
| --- | --- | --- |
| Cracked open (under 75°) | `.warning` | **The cat peeks out of the box** with a blue text-message bubble over its eyes, politely asking you not to open the phone ("Psst… close the phone?") |
| About 90° (75°+) | `.agitation` | **The cat is visibly annoyed**: red tint, violent shaking, a pulsing red bolt, and a red bubble snapping at you ("I SAID close it.") |
| 180° / fully open | `.rampage` | The box bursts. **Bite appears as the giant kaiju** and smashes the city across both halves |
| Split screen (any angle) | `.multitasking` | Same rampage as 180° |

The engine already implements every rule from the spec, so you only draw:
- The state comes from the hinge: closed → incubation, partially open under 75° → warning, 75° and up → agitation, fully open (or 178° and up) → rampage.
- Split screen = compact width **while open**. The closed outer display is also compact, so it's excluded.
- **Recovery:** when split screen ends, the state is re-derived from the current hinge (flat → rampage continues, cracked → warning, folded → incubation). This is already built into `engine.state`.
- Entering rampage or multitasking wipes `focusSeconds` and fires a heavy haptic slam.
- Haptics (`UIImpactFeedbackGenerator`) pulse from 15° and scale linearly to full at 179°. This is already running in the engine tick.

## Engine API you read (via `@Environment(KaijuEngine.self) private var engine`)

| Property | Type | Use it for |
| --- | --- | --- |
| `engine.state` | `GameState` | `.catMood` (`.pleading` / `.annoyed` / nil), `.monsterForm` (`.kaiju` for rampage), `.minion`, `.destructionPerSecond`, `.isDestructive`, `.subtitle` |
| `engine.hinge.angleDegrees` | `Double` 0…180 | Continuous effects: eye glow, shake, camera zoom |
| `engine.hapticIntensity` | `Double` 0…1 | Same curve as the haptics. Use it to drive the visuals so they match what the user feels |
| `engine.buildings` | `[Building]` | Towers losing floors |
| `engine.floorsDestroyedCount` | `Int` | Trigger for debris bursts, screen shake, and `.sensoryFeedback` |
| `engine.lastChangedBuildingID` | `Int?` | Which tower just got hit (aim the kaiju at it) |
| `engine.cityHealth` | `Double` 0…100 | Health bar |
| `engine.isMultitasking` | `Bool` | Split-screen banner |

## Shared building blocks (already built, just use them)

- `PeekingCatView(mood:annoyance:)`: the cat peeking out of the box (`CatBox` frame 1), with a `MessageBubble` whose tail points at its eyes. Lines rotate from `CatMood.lines` (edit the copy in `Engine/CatMood.swift`). `.annoyed` adds red tint, shake, and a pulsing bolt. Pass `annoyance: engine.hapticIntensity`. It's already used in `MonsterNest`.
- `BiteView(form: .kaiju)`: red-tinted, glowing, stomping kaiju. It's already used in the rampage overlay.
- `HingeGapGlow(intensity:)`: reads `ReservedRegion(.division)` and paints the fold as a red crack. It's already applied.
- `EffectsLayer(dust:burstTrigger:)`: SpriteKit dust plus a debris burst each time the trigger changes.
- `CitySkyline`, `BuildingView`, `CatCrowd(isFleeing: true)`, `PixelSprite`, `SpriteSheet`, `CityTile`.

---

## Tasks (in priority order, about 50 minutes)

### Must-have (first 25 minutes)
1. **Kaiju smashes the tower that fell.** In `rampageOverlay`, move the kaiju toward the tower with `lastChangedBuildingID` instead of the sine sweep. Add a stomp: on `floorsDestroyedCount` change, apply `.offset(y:)` screen shake to the whole `ArrangementView` for 0.2 seconds.
2. **Tune the cat's pleading → annoyed escalation.** The baseline already works. Make it land: grow the bubble with `engine.hapticIntensity`, fire `.sensoryFeedback(.warning, trigger: engine.state.catMood)` when it turns annoyed, and punch up the copy in `CatMood.lines`. Check that the bubble stays readable and isn't clipped in the narrow split pane.
3. **Split-screen banner.** When `engine.isMultitasking`, show a big red "CLOSE THE OTHER APP" banner. The pane is narrow here, so use a single column.
4. **Test all three Fold positions** in the iPhone Duo simulator (Closed, Partially Open, Fully Open), then drag the home indicator to one side for split screen.

### Should-have (next 15 minutes)
5. **Minion swarm.** During rampage, spawn 3–5 `SlimeAngry` sprites marching across the `CityBoard` (`engine.state.minion`). Switch them to `SlimeHurt` when `cityHealth == 0`.
6. **Health bar** across the top of `CityBoard`, turning red below 20.
7. **Box-burst transformation** when entering rampage: the cat's box shakes, flashes white, and Bite scales from the box's size to full kaiju with `.bouncy`, with "KAIJU UNLEASHED" huge on screen.

### Stretch
8. Use `.arrangementViewStyle(.overlay)` in rampage so the city sits behind a full-screen kaiju, and read `overlayArrangementZIndex` to change layout when folded.
9. Move rubble tiles into the `ReservedRegion` gap so the "crack" looks physically broken.

---

## How to test

- **Any simulator:** tap the State Visualizer HUD → **Simulate hinge**. Drag the angle: 10° = pleading cat, 90° = annoyed cat, 180° = kaiju rampage. Turn on **Simulate split screen** for the multitasking trap, then turn it off and watch the recovery pick up the current angle.
- **iPhone Duo simulator:** Bitrig's Fold controls: Partially Open shows the fold's `division` region (the red crack), Fully Open = rampage.
- **Haptics** only play on a real device.

## Asset map (your side)

| Asset | Where it's used |
| --- | --- |
| `CatBox` (frame 1) | The cat peeking out of the box: pleading, then annoyed |
| `Bite` | The kaiju that bursts out at 180° or in split screen (scaled and tinted) |
| `BatNeutral/Angry/Hurt` | Warning minion (peeking bat) |
| `RatNeutral/Angry/Hurt` | Agitation minion |
| `SlimeNeutral/Angry/Hurt` | Rampage and multitasking minion |
| `Cat0`–`Cat5` | Citizens fleeing (`CatCrowd(isFleeing: true)`) |
| `CityTiles` | Towers and rubble (rubble tiles 189–191) |

Credit line for the demo: monster sprites by Red Chan (CC BY-NC), city tiles by Kenney (CC0).
