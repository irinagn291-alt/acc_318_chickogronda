<!-- gf-brief source=5e60970113aa851184da2d72e58ae4c2dfedc65f7ca2e923506a34b40ffa0bfe written=2026-10-24T21:35:00+03:00 -->
# Chickogronda

## What it is

Chickogronda is a one-touch ferry-deck runner. You hop along mooring plates toward the next horn, picking up cargo that makes each leap shorter. It is a dark, full-screen game for someone who wants short runs, a heel readout, and best scores kept on the phone or iPad.

## Launch and onboarding

There is no onboarding. A cold launch goes from the system launch screen straight onto the deck, already moving in chapter 1.

For the first few seconds of play, two lines sit on the sky:

- "Cross to the next horn"
- "Tap hops. Hold, then release, for a long gap."

Those lines disappear after about nine seconds of running, and also while the run is paused or a chapter card is up. The top of the screen always shows "HEEL" with the current score, "CH" with the chapter number, and a pause icon.

## Screens

### Deck

The only main screen is the ferry deck. There are no tabs.

Along the top:

- "HEEL" sits beside the live score. Under it, a bar fills as cargo is picked up, and a marker shifts with the deck’s heel. VoiceOver reads this as "Heel and cargo", with the score as the value.
- "CH" shows the chapter number. VoiceOver reads it as "Chapter".
- A pause icon. VoiceOver reads it as "Pause". Tapping it opens the pause card and freezes the run. While that card is up, the same control shows a play icon and VoiceOver reads "Resume". Tapping it hides the card and the run continues.

On the deck itself, press and release anywhere to jump. A short press is a hop. Holding, then releasing, crouches and then commits a longer leap. Cargo crates can be collected while running. A miss drops between the plates. A strike on a hazard ends the run the same way. After a brief hold, the deck starts again from the beginning and the best numbers update if this run beat them.

### Pause card

Title: "Paused". Line: "The run is holding."

- "Resume" closes the card and continues the same run.
- "Records" opens the Records sheet. The run stays held.
- "Settings" opens the Settings sheet. The run stays held.

### Chapter card

This covers the deck when a chapter is reached, and again at the final horn. It is titled "Chapter" plus the number (2, 3, or 4). Under that, one line:

- Chapter 2: "Each crate cuts the jump. Short gaps still fit."
- Chapter 3: "The long gap clears only while you are light."
- Chapter 4, including the final horn: "Final horn. Weight still decides the leap."

"Score" and the current score sit above "Continue". "Continue" dismisses the card and the same run goes on. Reaching a chapter also updates the saved bests.

### Records

Sheet title: "Records". A drag handle is visible. Three rows, each with a number:

- "Best score"
- "Highest chapter"
- "Peak cargo"

"Close" dismisses the sheet and returns to the pause card.

### Settings

Sheet title: "Settings". A drag handle is visible.

- "Best runs stay on this device."
- "Contact" opens the support page.
- "Reset" clears the saved bests, starts a fresh deck, and closes Settings. There is no confirmation.
- "Close" dismisses the sheet and returns to the pause card.

## Features

- One-touch running on a ferry deck: tap to hop, hold and release for a longer leap.
- Cargo that shortens the jump, shown on the "HEEL" bar, up to a full bar.
- Heel sway that moves the marker on that bar and changes how forgiving a landing is.
- Four chapters, marked "CH", with a chapter card and a horn at each step, plus a final horn on chapter 4.
- A live score next to "HEEL", and "Score" on the chapter card.
- Pause and resume from the top icon or from "Resume".
- "Records": "Best score", "Highest chapter", and "Peak cargo".
- "Settings" with "Contact" and "Reset".
- A short success tap when cargo is taken, and a heavier tap when the chapter changes.
- Opening lines "Cross to the next horn" and "Tap hops. Hold, then release, for a long gap."

## Behaviours that can look like bugs

- The pause icon does nothing while a chapter card is up, and nothing during the short freeze after a miss. Wait for "Continue", or wait until the deck has restarted, then pause.
- Presses do not jump while "Paused" is showing, while a chapter card is showing, or while the runner is falling. Tap "Resume" or "Continue", or wait for the restart.
- A miss has no "game over" label. The runner drops, then the deck reloads at the start on its own. "Best score", "Highest chapter", and "Peak cargo" update only if this run beat them.
- The two opening lines vanish on their own after the run has been going for a few seconds. They are instructions, not a stuck overlay.
- "Reset" asks for nothing and wipes the three records, then puts you on a new deck. Pause, open "Settings", and tap "Reset" only when that is intended.
- With the "HEEL" bar high, the long gap will not clear. The chapter 3 line says "The long gap clears only while you are light." Finish or miss the run so cargo clears; a new deck starts empty.
- Before any chapter is reached and before any miss, Records shows "Best score", "Highest chapter", and "Peak cargo" as 0. Finish a stretch that hits a chapter, or miss once, and the numbers can rise.
- Chapter 4’s card and the later final horn use the same line, "Final horn. Weight still decides the leap." "Continue" leaves each one and play goes on; the second card is the end of the horn sequence, not a stuck screen.
- The deck keeps generating plates. It does not offer a level select, and it does not stop after chapter 4 except for that final card.

## Starter content and resume

On a device, Records start at 0. There is no sample deck and no seeded best run.

A run that is only paused can be resumed with "Resume" in that same session. A miss restarts the deck immediately and does not offer a continue. Quitting the app does not restore the unfinished run. Only "Best score", "Highest chapter", and "Peak cargo" remain.

## Permissions

None.

## Absent

Login or accounts, in-app purchase, ads, analytics, user-generated content, an account deletion flow, and an App Tracking Transparency prompt are all absent. "Reset" clears saved bests only. It is not an account deletion.

## Data and support

Best runs stay on this device, as Settings says: "Best runs stay on this device." The support control is "Contact" in Settings. It opens the support page.

## Scanning and health

None.

## Platform

English only. No region lock. The interface is dark. iPhone and iPad. iPhone supports portrait, landscape left, and landscape right. iPad also supports upside down. The game is full screen. Minimum iOS version is 17.0.

## Category

Games. The fit inside that is an arcade runner.
