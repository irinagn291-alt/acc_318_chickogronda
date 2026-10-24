# Hawserrun

Hawserrun is a one-touch ferry-deck runner. Tap for a short hop. Hold, then release, to commit a longer leap across the mooring gaps.

Cargo is the reason to retry. Each crate multiplies jump velocity by 0.78, a 22 percent cut. The shortest gap, 70 px, still fits that heavier leap. The longest gap, 160 px, fits only while the runner is light. The spawner reads the current burden and the deck's heel, and it refuses a gap outside that envelope instead of asking for an impossible jump.

Physics, kept as published:

- gravity 2200 px/s^2
- run 280 px/s
- jump velocity 900 px/s
- gaps 70...160 px

Reach is `runSpeed * (2 * jumpVelocity / gravity) * 0.85`. Heel sway trims the landing window. A miss drops you between plates and the same deck reloads at once. Best score, highest chapter, and peak cargo stay on the device.

The playfield is the whole product: a thin heel gauge, a chapter mark, and a pause glyph. Records and Settings are sheets. There is no camera permission and no network play.

## Build

```bash
cd apps/Hawserrun
xcodegen generate
xcodebuild build-for-testing -scheme Hawserrun -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
