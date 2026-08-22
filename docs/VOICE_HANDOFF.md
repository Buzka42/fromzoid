# FromZoid — Voice Handoff

Companion to [VOICE_COMMISSION.md](VOICE_COMMISSION.md). Full 144-line script lives there.

**Content pass closed 2026-08-22.** Audio is in the mod, Lua is wired, sparse-pool indexing is live. Miles choruses stay spoken-with-lilt (accepted).

---

## Shipped files

```
Contents/mods/FromZoid/common/media/sound/FromZoid_<Voice>_<NN>.ogg
```

144 clips. Mono Ogg Vorbis, 44.1 kHz, q5, ~100 ms pad, hot takes pulled to about −3 dB peak. MP3s removed.

Sound scripts: `common/media/scripts/fromzoid_sounds.txt` — one `sound` block per stem, `distanceMax = 14`, `volume = 0.5` (porch / 4–8 tiles inside, not across the street).

Index: `FromZoid_VoiceIndex.lua` (`FromZoid.VOICE_CLIPS`) lists whatever is actually on disk. Lines: `FromZoid_VoiceData.lua`. Playback: `FromZoid_Whispers.lua`.

---

## In-game rules (implemented)

- Male → Vlad | Miles | Knox. Female → Roxie | Annie | Zelda.
- Sticky `fromzoidVoice` on the zombie; gender mismatch is the only re-roll.
- Knox only at windows. At a door he stays Knox and does not speak.
- Night or darkness event. One 8 s cooldown for subtitle + audio together.
- `playSound("FromZoid_Knox_17")` only if that index is in `VOICE_CLIPS`.

---

## Voice IDs (Higgsfield presets)

| Voice | Gender | voice_id |
| --- | --- | --- |
| Vlad | male | `e5666b9c-99a2-4fac-8b4e-abee078b186d` |
| Miles | male | `e18664a7-ee4f-5273-acf8-533eb24cd366` |
| Knox | male | `195e386a-cb61-5c1b-a53b-0e2f0669c408` |
| Roxie | female | `f6448975-768e-4327-b932-1b7c973d58e9` |
| Annie | female | `f2801b0f-e345-598e-86f5-8364d886d96b` |
| Zelda | female | `b7aaea29-0c88-5925-90c0-8f66754cda53` |

Engine used for the ship set: **elevenlabs** (`text2speech_v2`).

---

## QC

- [x] Filenames use original line numbers 01–24
- [x] Miles verses are original (no copyrighted lyrics)
- [x] Knox never fires at a door
- [x] Voice stays stable per zombie
- [x] Missing ids do not call `playSound`
- [x] Ogg spec + porch falloff
- [x] Miles sung-as-spoken accepted for this pass
- [ ] In-game listen for take slates (none expected from the generation job)

Retake later if needed: Miles 02, 05, 08, 11, 14, 17, 20, 23 (chorus lilt).
