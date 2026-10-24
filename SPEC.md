# Hawserrun — Game Specification

**One-line positioning:** Tap and hold to hop gaps on a heeling ferry deck.

| Field | Value |
| --- | --- |
| Product name | Hawserrun |
| Bundle identifier | `com.hawserrun.deck` |
| Domain | https://hawserrun-deck.pro |
| Contact URL | https://hawserrun-deck.pro/contact-us |
| Category | `public.app-category.games` |
| Devices | iPhone (portrait, landscape left, landscape right) and iPad (all orientations) |
| Playfield | landscape, horizontal |
| Interface style | Dark |
| Asset prefix | `hsr_` |

This is a SpriteKit game. Ignore any utility, food, scanner, or catalog rule that conflicts with this document.

---

## 1. Non-negotiable constraints

1. No CocoaPods and no shared code with other apps.
2. English identifiers and player-facing copy.
3. No WebView shell, no remote config, no camera permission.
4. Offline. No wagering, deposits, cash-out, or gambling ads.
5. The playfield is the product. A ledger of marks is a failed build.

---

## 2. Product core

The player taps through a continuous runner and reaches the next chapter. Scene: Ferry.

Collecting adds weight and cuts jump velocity by 22 percent. The shortest gap stays reachable when heavy. The longest gap is reachable only while light.

### 2.1 User flow

1. Launch straight into the full-bleed deck playfield with the first gap already in hop range
2. Tap for a short hop or hold and release for a charged jump across the next mooring gap
3. Collect a rope-side cargo crate and feel jump velocity drop from the weight tradeoff
4. Miss a gap or hit a refused impossible beat and restart the run immediately on the deck
5. Cross the chapter horn line and carry best score and highest chapter to Records
6. Open Pause from the top glyph or Settings from a sheet without leaving the deck scene

### 2.2 Essential behaviour

- SpriteKit landscape playfield at 60 fps with pooled MooringChunk segments (max 400 nodes)
- One-touch input: tap hop or hold-charge release jump at gravity 2200, run 280, jump 900
- Cargo pickups increment burden and scale jump velocity by 0.78 per the 22% tradeoff
- GameSimulation with fixedSeed clears opening chunks and rejects beats outside the reachable gap envelope
- Three parallax layers plus foreground spray; articulated chicken hero with body, limb, face, separate shadow
- HUD limited to thin heel/cargo gauge, chapter buoy, and pause glyph—no bottom Hop button
- Four chapters with instant fail-restart; local best score and highest chapter persistence

---

## 3. Uniqueness assignment for Hawserrun

The portfolio axes stay in the table so this app remains unique. The playfield follows the archetype, not a dashboard DNA.

| Axis | Assigned value |
| --- | --- |
| architecture | Heel-sway runner simulation (HeroNode runs at 280 px/s; tap applies 900 px/s jump impulse, hold charges release jump; each CargoCrate increments burden and scales jump velocity by 0.78; MooringChunk pool spawns gaps between 70 and 160 px with deck-heel offset applied to landing windows; GameSimulation with fixedSeed rejects layouts where max_gap exceeds the reachable envelope at current burden and heel phase; fail reloads FerryScene; RunRecord persists best chapter and score locally) |
| ui | SwiftUI UIKit mix via UIViewRepresentable · realitykit-lite |
| naming | Hawserrun / mooring-deck lexicon (FerryScene, MooringChunk, HawserLayer, CargoCrate, HeelGauge, HornCue, HeroNode, ChunkSpawner, GameSimulation, RunRecord, ChapterBuoy, SprayLayer) |
| organization | By mooring role (FerryScene, DeckLane, HawserLayer, HeroNode, ChunkSpawner, HUD, GameSimulation, RunRecord, Settings) |
| dependencies | None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only |
| design | theverge · folio · high-contrast |
| typography | Hoefler Text |
| navigation | Wake-locked chrome (the SpriteKit ferry deck lane never leaves; Records and Settings arrive as sheets; tap and hold-release fuse on Play; no tab bar) |
| art | Cyberpunk digital art · illustration |
| twist | Cargo-then-clearance (each crate cuts jump 22%; longest gap needs light load; fixedSeed refuses impossible gaps; opening gesture live on frame one) |
| persistence | UserDefaults+Codable · one RunRecord root holding bestScore, highestChapter, and peakCargo, encoded under a single key with debounced save after each run end |
| screens | Play-root ferry deck (Play is the full-bleed SpriteKit deck lane with heel gauge and chapter buoy; Pause and Chapter are overlays; Records and Settings are sheets; no TabView) |
| scanner | no scanner |
| search_api | none |
| daykey | Int in YYYYMMDD form |
| reference_id | theverge |
| reference_sha | 094db6e7a6369bef4539f7319b5bca116ed1b8e8784c51f8f36be84e566b46ce |

### 3.1 Architecture contract

A SpriteKit scene runs update(currentTime:) at 60 fps for a runner on the horizontal axis. Physics: gravity 2200 px/s^2, run 280 px/s, jump velocity 900 px/s, gaps 70...160 px. The chunk spawner reads the current tradeoff and refuses a beat the hero cannot clear. Collision is explicit. Fail restarts the same scene. Best chapter and score persist. Unit tests drive GameSimulation with fixedSeed and never need the view.

### 3.2 UI contract

The playfield fills at least 85 percent of the screen in the archetype orientation. HUD is a thin top gauge, a chapter mark, and a pause glyph. There is no bottom Hop button, no card stack, and no labeled terrain. Touch hits the scene, not a form.

### 3.6 Screen composition contract

One full-bleed playfield. Physical screens: Play, Pause, Chapter, Records, Settings. Review poses of Play, not extra databases: play, air, land, collect, hazard, fail, pause, chapter. Pause and Chapter are overlays. Records is one best-score list. Settings holds contact and reset.

Input: one touch: tap hops, or hold sets a jump and release commits it

---

## 4. Target file organization

```
Hawserrun/
  Hawserrun/
├── App/
│   └── HawserrunApp.swift
├── FerryScene/
│   ├── FerryScene.swift
│   ├── DeckLane.swift
│   ├── HawserLayer.swift
│   └── SprayLayer.swift
├── HeroNode/
│   └── HeroNode.swift
├── ChunkSpawner/
│   ├── MooringChunk.swift
│   ├── CargoCrate.swift
│   └── ChunkSpawner.swift
├── GameSimulation/
│   └── GameSimulation.swift
├── HUD/
│   ├── HeelGauge.swift
│   ├── ChapterBuoy.swift
│   └── PauseOverlayView.swift
├── RunRecord/
│   ├── RunRecord.swift
│   └── RecordsSheetView.swift
└── Settings/
    └── SettingsSheetView.swift
  Assets.xcassets/
```

---

## 5. Screens

Play is one full-bleed `SKScene`. Review poses are frozen moments of that scene: play, air, land, collect, hazard, fail, pause, chapter.
Pause and Chapter are overlays. Records stores the best run. Settings holds reset and the contact link.
Do not invent a screen per mark, gap, or collectible.

---

## 6. Domain model

Publish the physics numbers below as constants and test against them.

Physics: gravity 2200 px/s^2, run 280 px/s, jump velocity 900 px/s, gaps 70...160 px.

Runner reach is `runSpeed * (2 * jumpVelocity / gravity) * 0.85`. Heavy jump velocity is `jumpVelocity * (1 - tradeoffDelta)`.
Timing's next window is `max(minWindow, window * (1 - tradeoffDelta))`.
Flight's loaded lift is `lift * (1 - tradeoffDelta)` and must still exceed gravity.
A drop's tilted restitution is `restitution * (1 - tradeoffDelta)`.
The spawner must refuse a beat outside the current envelope. Chapters: 4. Obstacles: gap, drift, moving ledge.

---

## 7. Design system

Direction: archetype `runner`, not the design-axis chrome.

### 7.1 Palette

- `bg` `#16181D`
- `surface` `#23262C`
- `ink` `#F4F0E6`
- `accent` `#E3B341`
- `muted` `#9A958C`
- `sky` `#12141A`
- `far` `#2A3142`
- `mid` `#3E4654`
- `ground` `#C8C4B8`
- `hero` `#F7F4EE`
- `hazard` `#C45C4A`
- `collectible` `#E3B341`
- `weather` `#D7D3CB`
- `shadow` `#0E0F12`

Read colours from `DesignTokens`. HUD type uses ink on a surface plate. World colours are sky, far, mid, ground, hero, hazard, collectible, weather, and shadow.

### 7.2 Typography

Family: **Hoefler Text**

Set chapter banners, overlay titles, and buoy callouts in `Hoefler Text` bold/italic to evoke editorial maritime logbooks with high-contrast serif authority, paired with monospaced numeric digits on `HeelGauge` and `ChapterBuoy` so rapid distance and cargo weight ticks never jitter during 60 fps runs.

### 7.6 Playfield

Full bleed. At least 85 percent of the screen is the scene. Thin top HUD. No bottom control bar. No three equal cards.

---

## 8. Game feel

- Frame loop: dt is 0 on the first frame, then min(currentTime - lastUpdateTime, 1/30). Step GameSimulation with a fixed 1/120 s accumulator. The scene renders that simulation.
- Units stay in px/s^2 and px/s inside GameSimulation. Set physicsWorld.gravity to zero. Physics bodies are for contacts only. Never copy contract gravity into physicsWorld.gravity. SpriteKit uses m/s^2 at 150 points per meter.
- Queue contacts in didBegin and apply them in update.
- Hit-stop is a 40 to 60 ms countdown in update that skips simulation steps. Do not set isPaused or speed to 0 and wait on an action to resume.
- Camera: smoothed look-ahead along the travel axis, plus a decaying trauma shake. No shake when Reduce Motion is on.
- Runner: a 100 ms input buffer and no coyote time. Timing: the contract window is the only leniency. Flight, grid, and drop: squash, a puff, and hit-stop only.
- Runner and flight: a body, a limb on sin(phase), eyes facing velocity, squash through xScale and yScale, and a shadow that shrinks with height. Grid and drop: a named sprite with the same squash.
- One-shot particles, an SKEmitterNode with targetNode set and removed after its lifetime, or pooled puffs. At most 400 live nodes.

The collectible visibly changes the tradeoff. Restart is immediate. The first ten seconds teach the gesture without a paragraph.

---

## 9. Concurrency

Scene updates stay on the main thread. Persistence writes are small and off the per-frame allocator. Do not allocate unbounded nodes inside `update`.

---

## 10. Persistence engineering

A single `Codable` root struct `RunRecord` (`bestScore`, `highestChapter`, `peakCargo`, and `lastPlayedDayKey` as `Int` in `YYYYMMDD` form) encodes to JSON under one `UserDefaults` key with debounced write on run completion or chapter horn clearance, while `hsr.demo.v1` seeds initial records and places the first playable deck chunk on cold launch.

Chosen technology: **UserDefaults+Codable · one RunRecord root holding bestScore, highestChapter, and peakCargo, encoded under a single key with debounced save after each run end**

Keep best score and chapter. Provide `resetAllData()` from Settings.

---

## 11. Networking

No required network. Do not add a camera usage string. Do not call a catalog or a food API.

```yaml
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.games
```

---

## 12. Functional twist

Collecting adds weight and cuts jump velocity by 22 percent. The shortest gap stays reachable when heavy. The longest gap is reachable only while light. The opening gesture is enabled on the first frame. An impossible gap, a missed window, or a dead pocket is refused and the run restarts. The Simulator seed opens straight into the play pose with the gesture live. The refused case is an impossible gap, window, or pocket, and the tests reject it.

The twist is visible in play, covered by `GameSimulation`, and described in the README as the reason to retry.

---

## 13. AI-generated assets

Art direction: Stylized runner scene, Ferry. Flat graphic silhouettes, clear shapes, no letters, no words, no watermark, no UI chrome.

The hero is drawn in code or loaded from a later portrait. These five images are the world kit. Create empty imagesets with these names and load them, with a procedural fallback:

- `hsr_BackdropFar` — Far parallax plate.
- `hsr_BackdropMid` — Mid parallax plate.
- `hsr_Collectible` — Collectible cutout.
- `hsr_PropNear` — Near prop cutout.
- `hsr_PropFar` — Far prop cutout.

BackdropFar and BackdropMid fill the canvas. Collectible, PropNear, and PropFar are solid cutouts with transparent corners. No text in any image.

---

## 14. Demo data

On Simulator only, seed `hsr.demo.v1`, mark onboarding complete, and open the play pose. `-ReviewScreen` then freezes the pose named by the key. Each pose is visually different. Never seed a device.

---

## 16. Anti-patterns

- Labeled tiles: Fresh, Ridge, Packed, Gap, or any word standing in for terrain.
- A bottom Hop or Jump button that plays the game.
- A hero made of one ellipse and one circle.
- A static board that only lerps one column when a button is tapped.
- CRUD screens named after marks.
- A watch-rate, calorie, barcode, or gram feature.
- More than 400 live nodes, or a new node allocated every frame with no pool.
- Contract gravity copied into physicsWorld.gravity.
- A scene created inside body, as SpriteView(scene: SomeScene(...)).
- Hit-stop done by pausing the scene or a node and waiting on an action to resume.

---

## 17. Tests

Add `HawserrunTests` with a `GameSimulation` type that lives in the app target. The scene steps that type. Tests call it; they do not reimplement the integration.

1. Runs `fixedSeed` and clears the first chunks.
2. Asserts the light or unloaded envelope is `reachable` and the heavy or loaded envelope is stricter.
3. Rejects an impossible gap, window, or pocket.
4. Asserts `nodeBudget` stays at or under 400.
5. Round-trips the best score.
6. Parses `ReviewLaunch.screen`.

---

## 18. README.md

Write what the game is, why the tradeoff is fair, the physics numbers, and how to build it.

---

## 19. Definition of done

- [ ] `xcodegen generate` and the iOS build succeed.
- [ ] Tests pass, including `GameSimulation`.
- [ ] Play, pause, and fail are reachable.
- [ ] The named imagesets are loaded, with a procedural fallback.
- [ ] Contact link is `https://hawserrun-deck.pro/contact-us`.
- [ ] Category is games. No camera key.

---

## 20. Build commands

```bash
cd Hawserrun
xcodegen generate
xcodebuild build-for-testing -scheme Hawserrun -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.hawserrun.deck/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Hawserrun -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.hawserrun.deck/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcodebuild test-without-building -scheme Hawserrun -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.hawserrun.deck/DerivedData'
```

Signing stays off on the command line only. Leave `CODE_SIGN_STYLE: Automatic` in project.yml.
