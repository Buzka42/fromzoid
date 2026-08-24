# FromZoid — Garbled Name Whisper Commission

Project: FromZoid (Project Zomboid Build 42.20).  
Use **ElevenLabs** or **Higgsfield Seed Audio**, then drop mono `.ogg` into the mod.

These are **not** door lines. They are wet, close, through-glass smears that *almost* say a first name. The game overlays the player's garbled forename as world text. The audio must work for **any** player name.

Do **not** copy TV dialogue or song lyrics. Do **not** speak a real celebrity name.

---

## Deliverables

| Id | Filename | Who | What it should sound like |
| --- | --- | --- | --- |
| 01 | `FromZoid_Name_01.ogg` | older man, close to glass | two-syllable smear, first consonant stuck |
| 02 | `FromZoid_Name_02.ogg` | young woman, breath on the pane | elongated vowel, name dies in the middle |
| 03 | `FromZoid_Name_03.ogg` | precise Englishman at a window | clipped start, the rest is air |
| 04 | `FromZoid_Name_04.ogg` | lost-girl voice, not a cartoon | almost a call, then a swallow |
| 05 | `FromZoid_Name_05.ogg` | sideways nursery voice | singsong fragment, no real word |
| 06 | `FromZoid_Name_06.ogg` | carnival mutter | laugh that turns into a name-shape |
| 07 | `FromZoid_Name_07.ogg` | older man, further back | reversed-feeling smear, still human |
| 08 | `FromZoid_Name_08.ogg` | woman through wood, not glass | hush, then a broken second syllable |
| 09 | `FromZoid_Name_09.ogg` | mixed, very quiet | only the first letter, then static |
| 10 | `FromZoid_Name_10.ogg` | mixed, wet | repeating the first syllable twice |
| 11 | `FromZoid_Name_11.ogg` | mixed, angry whisper | consonants without a vowel |
| 12 | `FromZoid_Name_12.ogg` | mixed, tender | a full name-shape that never resolves |

**12 clips.** One take per file. Under **3 seconds** each.

Ship **01–08** first if you are batching. The mod already has placeholder smears for 01–08 (processed from the night-people bank so something plays). Replace those files in place; keep the same ids.

### Audio spec

- Ogg Vorbis, mono, **44.1 kHz**, q5–q6
- Peak around **-6 dB** (quieter than porch voices)
- **80–150 ms** silence at head and tail
- No music. Short porch / glass air is OK
- Conversation distance, as if the speaker is **outside** and the listener is **inside**

Place files in:

```
Contents/mods/FromZoid/common/media/sound/
```

Lua plays `FromZoid_Name_01` … `12` (stem only). Sound scripts already exist for 01–08; add 09–12 in `fromzoid_sounds.txt` the same way when those files land.

---

## Session prompt (paste once per batch)

```
Horror game, isolated town. Record one take per numbered line.
The speaker is outside a locked house, almost saying someone's first name through glass.
Do not speak a complete real name. Do not say "line 1".
Keep it under 3 seconds. Wet, close, human, wrong.
No music, no crowd, no second speaker.
```

### Phonetic smears (read these, do not "act" extra words)

1. "K-k… ay…"
2. "Jo… ohn…" (break the vowel; do not finish)
3. "Sa… ah—" (cut)
4. "Em… em…"
5. "Ri… i…"
6. "Da-da…" (not a laugh word, a stuck name)
7. reversed-feeling "nnh… ay"
8. "…ell" (only the tail)
9. "B…" then air
10. "Ka-ka…"
11. "t-k-s" unvoiced
12. a full two-syllable shape that falls apart on the second beat

If a take accidentally becomes a real name, redo it.

## Higgsfield Seed Audio

Model: `seed_audio`. Format `ogg_opus` or wav then convert to mono `.ogg`.  
`loudness_rate` slightly down. No `voice_id` required; rotate preset voices so 01–06 do not all sound like one person.

## QC

- [ ] Unintelligible as a specific English name
- [ ] Still sounds like a mouth, not a synth sting
- [ ] Quiet enough that two clips in a row do not clip
- [ ] Replacing 01–08 does not require a Lua change

---

## DELIVERED 2026-08-23

All twelve shipped to `common/media/sound/` as mono 44.1 kHz Ogg Vorbis, 1.37-1.76 s.
Script entries **09-12 added** to `fromzoid_sounds.txt` (now 156 sounds), matching the
existing Name block: `category = Voice`, `is3D = true`, `distanceMax = 14`,
`volume = 1.4`. 01-08 replaced in place, so no Lua change was needed.

### What actually worked

The phonetic-smear approach in this doc **does not work with TTS.** Asked for
"K-k... ay...", the engines enunciate the letters and it lands as throat-clearing,
not a mouth. What works is the inverse:

1. Speak a **whole two-syllable word normally**, so the engine gives it real prosody.
2. **Cut it mid-word** (~55% in, faded through the second syllable) so the shape
   starts confidently and dies before resolving. That is the "almost".
3. **Band-limit to ~1050 Hz** plus a slow chorus detune. This destroys consonant
   identity while leaving vowel and rhythm - the parts a player recognises as speech.

Prosody survives blurring; phoneme soup does not. Keep the source words ordinary
(kettle, shutter, window, hollow, wander, linen) with only a few name-ish ones
(marrow, harrow, morrow, ammon, bramble) - plain nouns cannot resolve into a real
player's name, which satisfies the QC line about specific English names.

### Voices

Two only, alternating by id so no two consecutive clips are the same speaker:
**Vlad** (`e5666b9c-99a2-4fac-8b4e-abee078b186d`) on odd ids, **Cillian**
(`d8ba9f14-8a24-44db-932b-99e16c45bd32`) on even. Model `seed_audio`.
Per-voice EQ pulls them together: Vlad is de-boomed hard (high-pass 380 Hz, cuts at
220/140/95 Hz), Cillian is weighted up (high-pass 105 Hz, boosts at 175/110 Hz).

### Two processing traps

- **`seed_audio` returns 24 kHz.** `-ar 44100` is an *output* option and runs after
  the filter graph, so `asetrate=44100*x` on a 24 kHz stream reinterprets the rate
  and pitches everything up ~9 semitones. Put `aresample=44100` **first** in the
  chain. This bug spoiled an entire audition round.
- **Peak normalising does not match loudness.** At an equal -6 dB peak, Vlad was
  audibly much louder than Cillian because of low-frequency energy. These are matched
  on *mean* level (-27 dB) with peak capped at -6. Id 11 (unvoiced "tsk/tsss") hits
  the peak cap first and sits at -30.9 mean, which suits a consonant-only clip.

### Still unverified

Nobody has heard these in-game yet. Check they do not clip when two fire in a row,
and that `volume = 1.4` / `distanceMax = 14` still suit clips quieter than the
placeholders they replaced.
