# Dev A — Phone CLOSED (Outer Display)

You own **Act 1: Incubation** and **Act 4: Neglect**. That's everything the user sees on the 5.4" outer display while the phone is folded shut, plus the "welcome back" aftermath after the app was backgrounded.

Dev B owns everything shown while the phone is open. You never edit the same files, so you can both work at the same time without merge conflicts.

---

## Your files (only edit these)

| File | What it is | Status |
| --- | --- | --- |
| `MonsterInTheBox/Closed/ClosedGameView.swift` | Outer display: focus timer, Bite building, city, cats | Working baseline |
| `MonsterInTheBox/Closed/NeglectReportView.swift` | Sheet shown on return from background: acid rain + rusted city | Working baseline |
| `MonsterInTheBox/Closed/*.swift` | Any new file you add here is picked up automatically | — |

The project uses **folder-synced groups**, so adding a new `.swift` file to `Closed/` needs no project-file edits.

**Don't edit** `Engine/`, `Shared/`, or `App/RootView.swift` without telling Dev B. If you need a new engine value, add it in one small commit and tell your teammate.

---

## How your screen gets shown

`RootView` shows `ClosedGameView` whenever `engine.showsClosedExperience` is true (hinge `.closed` and not in split screen). It shows `NeglectReportView` as a sheet whenever `engine.neglectReport` is non-nil. You don't have to route anything yourself.

## Engine API you read (via `@Environment(KaijuEngine.self) private var engine`)

| Property | Type | Use it for |
| --- | --- | --- |
| `engine.state` | `GameState` | `.incubation` on your screen. `.monsterForm`, `.title`, `.subtitle`, `.symbolName` |
| `engine.buildings` | `[Building]` | Pass to `CitySkyline(buildings:tileSize:)` |
| `engine.focusSeconds` | `TimeInterval` | The focus timer (resets on rampage) |
| `engine.buildProgress` | `Double` 0…1 | Progress toward the next floor |
| `engine.floorsBuiltCount` | `Int` | Trigger for animations and `.sensoryFeedback` when a floor is added |
| `engine.lastChangedBuildingID` | `Int?` | Which tower just grew (for highlighting it or moving Bite to it) |
| `engine.cityHealth` | `Double` 0…100 | City health meter |
| `engine.totalFloors` | `Int` | "Your city has N floors" |
| `engine.neglectReport` | `NeglectReport?` | `secondsAway` and `healthLost` for the aftermath sheet |
| `building.rust` | `Double` 0…1 | Already rendered by `BuildingView` (brown tint and desaturation) |

## Shared building blocks (already built, just use them)

- `BiteView(form: .peaceful)`: the chibi, with bobbing and facing animations. `.sleeping` uses the Blue Drool sprite with a "zzz".
- `CitySkyline(buildings:tileSize:)`: towers made of Kenney tiles on a pavement street.
- `BuildingView(building:tileSize:)`: a single tower.
- `CatCrowd(isFleeing:catSize:)`: all six cat sheets walking along the street.
- `AnimatedSprite(sheet: .catBox)`: the cat popping out of a box (the logo, see below).
- `EffectsLayer(acidRain: 0...1)`: SpriteKit acid-rain particles.
- `PixelSprite(asset:)`, `CityTile(index:size:)`, `SpriteSheet`: raw sprite access.

---

## Tasks (in priority order, about 50 minutes)

### Must-have (first 25 minutes)
1. **Bite walks to the tower he's building.** When `floorsBuiltCount` changes, animate Bite's x-offset to the tower with `lastChangedBuildingID` (use `.bouncy`). Use `onGeometryChange` or evenly divided lot widths (`GameTuning.lotCount` lots).
2. **"Hammer" pop.** On each new floor, show a quick `hammer.fill` symbol with `.symbolEffect(.bounce)` or a small burst above that tower.
3. **Outer display layout check.** In the simulator, pick iPhone Duo and set Fold to Closed. Make sure the timer, city, and cats all fit in portrait and landscape. The system status bar sits in a vertical strip on the outer display, so keep content away from that edge.
4. **Title / focus start.** Show the cat-in-box logo (`AnimatedSprite(sheet: .catBox, framesPerSecond: 2)`) above the timer with the text "Keep the box closed".

### Should-have (next 15 minutes)
5. **Neglect sheet polish.** Count `healthLost` up from 0 with `.contentTransition(.numericText())`, and make the acid rain fade out after 3 seconds.
6. **Tower tiers.** Every 5 minutes of focus (or 15 seconds in demo mode), swap to a fancier style: map `focusSeconds` to `BuildingStyle` for new floors. This is the spec's "swap the city texture based on focus time". It needs a tiny engine change, so coordinate with Dev B.
7. **Day/night sky.** Tint the background gradient by `focusSeconds`.

### Stretch
8. Add parked cars and trees from the tilemap between towers (`CitySkyline.carTiles`, `treeTiles`, and check the indices against `assests/Pico-8 City Kenney/Preview.png`).
9. Use `SlimeNeutral` / `BatNeutral` / `RatNeutral` as friendly "construction crew" walking with Bite during incubation.

---

## How to test

- **Any simulator:** tap the State Visualizer HUD at the top to open the debug drawer. Turn on **Simulate hinge**, leave the angle at 0°, and you're in Incubation. Keep **Demo speed** on so floors build every 3 seconds instead of 5 minutes.
- **Neglect:** swipe home (or Cmd-Shift-H), wait about 10 seconds, then reopen. With demo speed on, the decay rate is 1 health per second, and the sheet appears.
- **iPhone Duo simulator:** use Bitrig's Fold control → Closed.

## Asset map (your side)

| Asset | Where it's used |
| --- | --- |
| `Bite` (Cute Monsters Big Belly Right) | Bite the architect |
| `BiteSleeping` (Cute Monsters Blue Drool) | Neglect sheet |
| `Cat0`–`Cat5` | Citizens walking the street |
| `CatBox` | Logo: the monster in the box (frame 0 = closed box). Dev B uses frame 1, the cat peeking out, when the phone opens |
| `CityTiles` | Every tower, rubble, and the street |
| `CitySample` | Optional title backdrop |
