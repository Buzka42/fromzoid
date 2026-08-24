# FromZoid — Delusion / Psychosis Moodle Commission

Project: FromZoid (Project Zomboid Build 42.20).  
Icons must read at **32×32** and **48×48**. No text on the art.

## Delivered (in the mod now)

**Redone 2026-08-23** in vanilla-PZ moodle form (glossy sphere, rim-light, bold
silhouette) carrying the FromZoid eye/cracked-glass motif. Generated with
`nano_banana_pro`, then cropped to a circle with a real alpha channel and installed.
Verified legible at 32x32 and 48x48, and the two states stay distinct by hue
(olive vs red) and by shape (crack-web vs staring eye).

Notes for whoever touches these next:
- The files are now **RGBA**; the previous ones were RGB with a baked black square.
  The alpha circle is what lets the HUD show through.
- `media/ui/32/` still holds **1024x1024** copies, matching the previous shipped
  state. Despite the folder name nothing here is 32px. If PZ actually wants a 32px
  texture there, downscale both — but change that on its own so a HUD regression is
  easy to attribute.
- Source art and a 32/48px legibility contact sheet are in the session scratchpad,
  not the repo.

| File | Moodle | Read |
| --- | --- | --- |
| `common/media/ui/FromZoidSanity_Bad_2.png` | Delusion | cracked window / eye in the glass |
| `common/media/ui/FromZoidSanity_Bad_3.png` | Psychosis | fractured eye, shards |
| `common/media/ui/32/` copies | same | HUD / MF fallback |

Optional later: a calm `FromZoidSanity.png` (unused while sane; DIY HUD hides below delusion).

## If you redo them

- Square, centered, dark ground, strong silhouette
- PZ moodle language: simple, painterly, no watermark, no letters
- Delusion: glass + eye, muted brown-green
- Psychosis: broken eye, dull red-black
- Export PNG, then copy into `media/ui/` and `media/ui/32/`

The DIY HUD loads `media/ui/FromZoidSanity_Bad_2.png` and `_3.png`. Restart the game after replacing textures.
