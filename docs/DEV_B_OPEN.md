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
│   ├── World/      Rendering layers: WorldStage, GroundLayer, BuildingLayer, ActorView (shared)
│   ├── Assets/     SpriteSheet, GameAsset, PixelSprite                               (shared)
│   ├── Effects/    SpriteKit dust / debris, HingeGapGlow (fold)                      (shared)
│   └── HUD/        State Visualizer + debug drawer                                   (shared)
├── Closed/         ◀── Dev A (BuilderBrain, BuilderActorsLayer, FocusHUD, …)
└── Open/           ◀── YOU
    ├── Logic/DestroyerBrain.swift        what the cat does while open
    ├── Logic/CatMood.swift               pleading / annoyed lines
    ├── Logic/GameState+Open.swift        catMood + minion per state
    ├── Logic/Minion.swift                bat / rat / slime moods
    ├── Views/DestroyerActorsLayer.swift  how destroyer cats are drawn (kaiju = scaled hero)
    ├── Views/CityBoard.swift             map pane (WorldStage + your actors + debris)
    ├── Views/MonsterNest.swift           nest pane (cat in the box, minion, health)
    ├── Views/PeekingCatView.swift        cat in the box with a message bubble over its eyes
    └── OpenGameView.swift                ArrangementView: CityBoard | MonsterNest
```

**Separation rules:**
- **Logic vs. views.** `DestroyerBrain` decides *where the cat goes and what it smashes*. It mutates the model only. Views only draw the model.
- **Map vs. cats.** The city (`CityMap`) and the cats (`CityActors`) are separate engine properties and separate layers. The kaiju moving never redraws the map; only a floor falling does.
- **Shared layers are frozen during the sprint.** If you need a change in `Engine/` or `Shared/`, make it one small commit and tell Dev A.
- New files dropped into `Open/` are picked up automatically. No project-file edits needed.

## The world (same map as the closed phone)

A 13 × 19 top-down tile grid (`CityLayout`). Roads run every 6th row and column, with 5 × 5 blocks between them. Towers stand on each block's bottom row and grow upward. Whatever Dev A's cat built while the phone was closed is what you destroy.

## The opening story (what `DestroyerBrain` + your views do now)

| Hinge | State | Map (CityBoard) | Nest (MonsterNest) |
| --- | --- | --- | --- |
| Cracked (< 75°) | `.warning` | Hero cat freezes on the road and stares; tremors knock a floor off a random tower now and then | Cat peeks out of the box with a **blue message bubble over its eyes**, pleading "Psst… close the phone?" |
| ~90° (75°+) | `.agitation` | Hero cat **paces erratically** (fast, short random walks on the roads) with a red glow; tremors speed up | Cat is **visibly annoyed**: red tint, shaking, pulsing bolt, red bubble ("I SAID close it.") |
| 180° / flat | `.rampage` | Hero cat becomes the **kaiju: the same cat scaled 4×** (`DestroyerActorsLayer.kaijuScale`). It ignores roads, marches to the nearest tower, and stomps it floor by floor. Citizens sprint away | "KAIJU CAT UNLEASHED" + draining health gauge |
| Split screen | `.multitasking` | Same as rampage | Same as rampage |

The engine already handles:
- The state from the hinge: closed → incubation, under 75° → warning, 75°+ → agitation, fully open or 178°+ → rampage.
- Split screen = compact width **while open**. The closed outer display is also compact, so it's excluded.
- **Recovery:** leaving split screen re-derives the state from the current hinge (flat → rampage continues, cracked → warning, folded → incubation, where Dev A's brain snaps the cat back onto a road).
- A rampage wipes `focusSeconds` and fires a heavy haptic slam. Each tower that collapses slams again.
- Haptic pulses start at 15° and scale linearly to 179°.

## Engine API you read (`@Environment(KaijuEngine.self) private var engine`)

| Property | Use it for |
| --- | --- |
| `engine.state` | `.catMood`, `.minion`, `.isKaiju`, `.floorsDestroyedPerSecond`, `.subtitle` |
| `engine.map` | Pass to `WorldStage(map:)`. Also `standingLots`, `totalFloors` |
| `engine.actors.hero` / `.citizens` | Position, `facing`, `activity` (`.stomping` when smashing), `isMoving` |
| `engine.destroyer.target` | The tower the kaiju is heading for |
| `engine.hapticIntensity` | 0…1, same curve as the haptics. Use it to drive shake and redness |
| `engine.floorsDestroyedCount`, `lastChangedLot` | Debris bursts, screen shake, `.sensoryFeedback` |
| `engine.cityHealth`, `engine.isMultitasking` | Health bar, split-screen banner |

## Shared building blocks

- `WorldStage(map:) { metrics in DestroyerActorsLayer(metrics:) }`: ground + towers + your actors layer, scaled to fit.
- `ActorView(actor:metrics:scale:)`: places and animates any `CatActor`. `scale` is how the kaiju is made.
- `CatSprite(look:animation:facesLeft:)`: `.pounce` (Cat3) doubles as the kaiju stomp.
- `HingeGapGlow(intensity:)`: reads `ReservedRegion(.division)` and paints the fold red.
- `EffectsLayer(dust:burstTrigger:)`: SpriteKit dust plus a debris burst each time the trigger changes.
- `metrics.center(of:)`: aim effects at `lastChangedLot`.

---

## Tasks (priority order)

### Must-have
1. **Stomp impact.** On `floorsDestroyedCount` change, shake `CityBoard` (a quick `.offset` keyframe) and burst debris *at* `lastChangedLot`. This needs a small `EffectsScene.burst(at:)` coordinate hookup; the method already takes a point.
2. **Transformation moment.** When `engine.state.isKaiju` turns on, flash white, pop the hero from 1× to `kaijuScale` with `.bouncy`, and show "KAIJU CAT UNLEASHED" huge for 1 s.
3. **Split-screen banner.** When `engine.isMultitasking`, show "CLOSE THE OTHER APP" in red. The pane is narrow, so use a single column.
4. **Test every pose** in the iPhone Duo simulator: Fold → Partially Open (red crack at the fold), Fully Open (rampage), then drag the home indicator to one side for split screen.

### Should-have
5. **Smarter kaiju** (in `DestroyerBrain` only): target the *tallest* tower instead of the nearest, or a tower near a fleeing citizen.
6. **Citizens flee away** from the kaiju instead of randomly. Pick the road tile farthest from `hero.position`. This lives in `CityWorld.tickCitizens`, which is shared, so coordinate with Dev A or override it from your brain.
7. **Cat-in-box escalation.** Grow the message bubble with `hapticIntensity`, fire `.sensoryFeedback(.warning, trigger: engine.state.catMood)`, and punch up the copy in `CatMood.lines`.

### Stretch
8. `.arrangementViewStyle(.overlay)` during rampage so the map fills the screen and the nest floats over it.
9. Rubble spreading: when a tower collapses, draw rubble tiles on the neighboring road for a few seconds (a new `Open/Views/RubbleLayer.swift` below your cats).

---

## How to test

- **Any simulator:** tap the State Visualizer HUD → **Simulate hinge**. Drag the angle: 10° = staring cat + pleading box, 90° = pacing cat + annoyed box, 180° = kaiju. Turn on **Simulate split screen** for the trap, then turn it off and watch recovery pick up the current angle.
- Build the city first: leave the angle at 0° for ~30 s (demo speed) so there's something to smash.
- **Haptics** only play on a real device.

## Asset map (your side)

| Asset | Where it's used |
| --- | --- |
| `Cat0`, `Cat2`, `Cat3` | Hero cat staring / pacing / kaiju stomping (scaled 4×) |
| `Cat4` | Citizens (they sprint using the walk cycle when fleeing) |
| `CatBox` (frame 1) | The cat peeking out of the box: pleading, then annoyed |
| `BatNeutral`, `RatAngry`, `SlimeAngry` | Minion in the Monster Nest per state |
| `CityTiles` | Towers and rubble (tiles 189–191) |

Credit line for the demo: monster sprites by Red Chan (CC BY-NC), city tiles by Kenney (CC0).
