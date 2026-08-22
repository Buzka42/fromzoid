# FromZoid

A Project Zomboid **Build 42.20** mod. Night people hide from the sun, hunt after dusk, whisper at your windows, and cannot enter a house that still has a talisman hanging unless you invite them in.

This is original code. It is not a dump of Workshop mods. See [CREDITS.md](CREDITS.md).

## Install

1. Copy `Contents/mods/FromZoid` to:
   - `%UserProfile%\Zomboid\mods\FromZoid`
2. Launch Project Zomboid 42.20.
3. Main menu → Mods → enable **FromZoid**.
4. Start a new sandbox (recommended: 6–12 months later, high erosion) so the abandoned-town pass matches the tone.

A copy is also placed in `Zomboid\mods` if this repo was installed from the machine that built it.

Workshop upload later: copy this repo’s `Contents`, `workshop.txt`, and `preview.png` into `%UserProfile%\Zomboid\Workshop\FromZoid\`.

## What it does

- **Sun cycle** — At dawn they path (or nest-teleport) indoors and go still. Noise can wake them. At dusk they pour into the streets.
- **Hunter stats** — Day: sluggish, poor senses. Night: hearing, memory, door use. Optional night sprinters (off by default).
- **Whispers** — Original lines at doors and windows at night. Zombies only, not animals.
- **Darkness events** — Rare multi-day fog / blackout with a radio-style warning.
- **Abandoned town** — First-loaded houses may have smashed glass, boards, and leftover clutter.
- **Talismans** — Craft from stone + feather + twine/string, or find rare dresser loot. Right-click inside a building → Hang Talisman. The whole building is sealed until you take it down, or until you open an exterior door/window (invitation).

Sandbox page: **FromZoid**.

## Smoke checklist (new save, debug cheat optional)

1. Enable FromZoid. Spawn in a town residential cell.
2. **Dawn hide** — Wait until after sunrise. Loaded night people should go indoors and stand idle. Walking into one can wake it.
3. **Dusk hunt** — After sunset they should leave buildings and use night stats (more aware).
4. **Whispers** — Stand inside a house at night with them at a window. You should see speech lines.
5. **Hang seal** — Craft or spawn `FromZoid.Talisman`. Right-click a wall/floor inside → Hang Talisman. Night people should loiter outside, not come in.
6. **Invite** — Open the exterior door. They may enter. Close it; new ones outside stay out.
7. **Take down** — Right-click the hung talisman → Take Down Talisman. The house is unsealed.
8. **Town** — Walk a street you have not loaded this save. Some windows/doors should already be broken or boarded.
9. **Darkness** (optional) — Raise “Darkness roll each day” to 100 in sandbox, wait until 07:00 for a schedule; warning then fog/blackout.

If Lua errors appear, check `C:\Users\<you>\Zomboid\Logs\` for `FromZoid` in the stack.
