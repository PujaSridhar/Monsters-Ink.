# Devpost Submission — Monster, Ink.

## Project name
**Monster, Ink.**

## Tagline (≤ 200 characters)
A focus game for iPhone Duo where the hinge is the trap: keep your phone folded and a pixel cat builds you a city; open it and a kaiju cat wakes up and eats it.

---

## Inspiration

Monster, Ink. is inspired by **Focus Friend by Hank Green**, the focus app where a cozy little companion works away while you stay off your phone. We loved how it turns "not using your phone" into caring for a character. We wanted to push that idea onto new hardware and give it teeth.

Every focus app asks you to be disciplined. We wanted one that makes breaking focus *feel* like breaking something.

The iPhone Duo gave us the perfect trigger: the fold. On most phones, "picking up your phone" is invisible. On the Duo it's a physical act: you have to open it. So we built a game where that single motion is the whole story. A closed phone is a safe box. Opening it lets the monster out.

## What it does

**Monster, Ink.** is a top-down, 8-bit city builder that you play by *not* playing.

**1. Phone closed: the cat builds.** On the outer display, a little pixel cat walks the roads of a Pokémon-style town. Every few minutes it walks to the shortest tower, hammers away, and adds a floor. Helper cats wander the streets. When every tower is tall enough, a new district unlocks and roads spread across the grass. The longer you stay focused, the bigger your city gets.

**2. Phone starts opening: something is watching.** The moment the hinge cracks open, the inner display goes dark. All you see are two huge, glowing red cat eyes with slit pupils, blinking at you from the shadows.
- Open it sideways and they sit on the right screen, creeping from the edge toward the fold as you open further.
- Open it upward and they rise from the bottom screen instead.
- The phone pulses with haptics that grow stronger the wider you open it.

It's a warning: *close me*.

**3. Phone fully open (180°): KAIJU CAT.** The lights come back on, and the city you built is spread edge to edge across both halves of the display. But the cat is now a 2× kaiju.
- It ignores the roads and stomps straight through blocks.
- It hunts down and **eats the helper cats** that built the city ("CHOMP!").
- It smashes towers floor by floor into rubble while the survivors flee.
- Your focus session is wiped.

**4. Split-screen trap.** Snap another app next to ours and the kaiju wakes instantly. Leave split screen and the game checks the hinge again: flat keeps the rampage going, cracked brings back the eyes, and folded sends the cat back to building.

**5. Neglect.** Swipe the app away and acid rain falls on your city while you're gone. When you come back, your buildings have rusted and the city has lost health.

## How we built it

- **Swift + SwiftUI** on the **iOS 27.1 SDK**, built and run in **Bitrig** on the iPhone Duo simulator.
- **iPhone Duo APIs**
  - `onHingeChange` and `DeviceHingeContext` read the live hinge status and angle, which drive the entire game state.
  - `ReservedRegion(.division)` finds the fold. It tells us whether the phone is opening sideways or upward, so the eyes know which screen to hide on. It also keeps UI text from crossing the crease.
  - Horizontal size class and scene phase detect the split-screen trap and background neglect.
- **Haptics:** `UIImpactFeedbackGenerator` pulses that scale linearly from 15° to 179°, plus a heavy slam when a tower falls or a cat gets eaten.
- **A real 2D tile world:** a 19 × 19 grid of roads and blocks. Cats move tile by tile in four directions using BFS pathfinding; normal cats stay on roads, while the kaiju cuts straight through. Towers are stacked from **Kenney's Pico-8 City** tiles, and every cat is animated from a pixel-art cat sprite pack.
- **SpriteKit** particles for acid rain, dust, and debris.
- **Architecture built for two people in two hours:**
  - A single `@Observable` game engine derives the state from the hardware.
  - Two separate "brains" hold the logic, a `BuilderBrain` for the closed phone and a `DestroyerBrain` for the open phone.
  - Rendering is layered: ground, then buildings, then cats.
  - One teammate owned the closed-phone experience and the other owned the open-phone experience, in separate folders, with no merge conflicts.

## Challenges we ran into

- **Brand-new hardware, brand-new APIs.** The Duo's hinge and reserved-region APIs are new in iOS 27.1, so we read the SDK interfaces directly to learn their exact shapes. For example, the hinge status is a struct, not an enum, so it can't be `switch`ed on.
- **"Compact" doesn't always mean split screen.** The closed outer display reports a compact size class too, so a naive check woke the kaiju every time you closed your phone. Split screen only counts when the phone is actually open.
- **Tuning the angles.** Our first version started the rampage at 75°, but a naturally half-open phone sits past that, so users never saw the scary eyes. We made every partially open angle belong to the eyes and saved the kaiju for fully flat.
- **Filling a folding screen.** A square city left empty bars around the edges, so we render the grid so it fills the whole inner display, edge to edge across the fold.
- **Making a chase work on a grid.** The kaiju kept stalling while re-routing toward moving prey until we preserved its step timing mid-walk.

## Accomplishments that we're proud of

- The hinge isn't a gimmick in our game; **it *is* the controller.** Every state comes from how far, and in which direction, you open the phone.
- The **hiding eyes** moment: a dark screen and two red eyes that follow the fold is genuinely unsettling.
- A complete loop: build, get warned, destroy, recover, plus the split-screen and background traps, all in a hackathon.
- A clean, modular codebase that two developers could build in parallel without stepping on each other.

## What we learned

- Designing for a foldable means designing for *poses and motion*, not just screen sizes.
- Physical interactions carry emotional weight. Opening a phone slowly while eyes stare back at you *feels* different from tapping a button.
- Separating the game model from the rendering made fast iteration possible: we rewrote the whole visual style twice without touching the rules.

## What's next for Monster, Ink.

- A box-burst transformation animation as the eyes turn into the kaiju.
- Rebuilding lost helper cats, and a streak system that rewards long focus sessions with new districts and building styles.
- Screen shake, debris, and a "cats eaten" score for extra-dramatic rampages.
- Testing and tuning haptics on real iPhone Duo hardware.
- Focus Mode and Screen Time integration, so the monster guards your real focus hours.

## Built with
`swift` · `swiftui` · `spritekit` · `ios-27` · `iphone-duo` · `devicehinge` · `reservedregion` · `uikit-haptics` · `observation` · `bitrig` · `xcode` · `pixel-art`

## Credits
- Inspiration: **Focus Friend** by Hank Green.
- City tiles: **Kenney**, Pico-8 City (CC0).
- Cat sprites: the pixel-art cat pack in `assests/cats`.

---

# Demo Video Script (~2 minutes)

**[0:00–0:12] Hook**
*(Close-up of a closed iPhone Duo on a desk.)*
"This is the most dangerous thing on my desk. Not because of what's on it, but because of what happens when I open it."

**[0:12–0:35] Act 1: The cat builds**
*(Outer display: the pixel cat walking the roads, hammering; towers rising; a new district unlocking.)*
"Meet the cat. While my phone stays folded, it builds me a city: one floor at a time, with a little help from its friends. Stay focused, and a new district unlocks. This is Monster, Ink."

**[0:35–1:00] Act 2: The eyes**
*(Slowly crack the phone open sideways. The inner display is dark; red eyes appear on the right screen.)*
"But the moment I start to open it…"
*(Pause on the eyes blinking. Open a little more; the eyes creep toward the fold.)*
"…something wakes up. It's hiding. Only the eyes. The wider I open, the closer they come, and the phone pulses in my hand. Open it upward instead, and they rise from the bottom."

**[1:00–1:30] Act 3: Kaiju cat**
*(Open fully flat. The city appears across the whole screen; the 2× kaiju stomps through blocks and eats a fleeing cat: "CHOMP!")*
"Open it all the way, and it's too late. The cat is now a kaiju. It ignores the roads, eats the helper cats that built my city, and smashes every tower I earned. My focus session is gone."

**[1:30–1:45] The traps**
*(Drag another app into split screen; the rampage continues. Then show the acid rain and rusted city after returning from the background.)*
"Try to sneak another app in with split screen? Kaiju. Swipe the app away? Acid rain rusts your city while you're gone."

**[1:45–2:00] Close**
*(Fold the phone shut. The outer display: the cat, calm again, picking up its hammer.)*
"Fold it back up, and the cat goes back to work. Monster, Ink. turns the iPhone Duo's hinge into the thing that keeps you focused, because now, opening your phone has consequences."
*(Title card: Monster, Ink. — Built for Bitrig Hacks.)*
