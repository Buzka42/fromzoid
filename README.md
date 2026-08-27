# FromZoid

A Project Zomboid **Build 42.20** mod (current pack **1.2.3**). Night people hide from the sun, hunt after dusk, whisper at your windows, and cannot enter a house that still has a talisman hanging unless you invite them in.

This is original code. It is not a dump of Workshop mods. See [CREDITS.md](CREDITS.md).

**Agent handoff:** [docs/CLAUDE_HANDOFF.md](docs/CLAUDE_HANDOFF.md) — constraints, tick order, how nest/hold/gather/damage actually work, and the playtest bugs already fixed. Read that before changing zombie AI.

## Install

1. Copy `Contents/mods/FromZoid` to:
   - `%UserProfile%\Zomboid\mods\FromZoid`
2. Launch Project Zomboid 42.20.
3. Main menu → Mods → enable **FromZoid**.
4. Start a new sandbox (recommended: 6–12 months later, high erosion) so the abandoned-town pass matches the tone.

A copy is also placed in `Zomboid\mods` if this repo was installed from the machine that built it.

Workshop upload later: copy this repo’s `Contents`, `workshop.txt`, and `preview.png` into `%UserProfile%\Zomboid\Workshop\FromZoid\`.

## What it does

- **Sun cycle** — At dawn they path (or nest-teleport) indoors and sit. They prefer the neighbourhood’s randomly destroyed houses. Noise can wake them. At dusk they pour into the streets. A watched porch crowd walks away a few at a time at sunrise, not as a ring of statues.
- **Hunter stats** — Sprint day and night if that option is on. Day: nearly deaf and blind, hide indoors. Night: gather at talisman houses. Twice as tough via lore (not `setHealth`).
- **Doors** — They can open ordinary doors and gates so they can nest and chase. They cannot open the door of a talisman-sealed house.
- **Gathering** — Each night a capped group (default 40) mills 2–5 tiles off sealed houses. Only the ones on a door or window freeze. They do not walk into the glass unless invited.
- **Whispers** — One person from the yard walks up to a sealed door or window, speaks, then goes back. Knox windows-only.
- **Sanity** — Strain meter (climb is slow), delusion/psychosis FX, Moodle Framework HUD (hard dependency).
- **Darkness events** — Rare multi-day fog / blackout with a radio-style warning.
- **Abandoned town** — First-loaded houses may have smashed glass, boards, leftover clutter, and rarely a gun + box.
- **Talismans** — Craft from stone + feather + twine/string, or find rare dresser loot. Spawn house always tries to hang one, board up (one door left clear), and put a 07:00 alarm in the house. Right-click inside → Hang Talisman. Sealed until you take it down, or until you open an exterior door/window (invitation). Worn charms wilt after N nights.
- **Ultra-strong** — Optional sandbox hell mode. Unarmored, about three or four landed hits kill. Off by default.

Sandbox page: **FromZoid**. Requires **Moodle Framework**.

## Smoke checklist (new save, debug cheat optional)

1. Enable FromZoid. Spawn in a town residential cell. The start house should be boarded, with a hung talisman and a 07:00 alarm.
2. **Dawn hide** — After sunrise, loaded night people go indoors and sit, preferably in ruined houses. Walking into one can wake it.
3. **Dusk hunt** — After sunset they leave buildings and use night stats.
4. **Whispers** — Stand inside a *sealed* house at night while they mill in the yard. One should sprint up to a window, speak, then go back. No “they all stop at once” popup.
5. **Hang seal** — They mill in the yard, not through the glass. They can open other doors in the street, not this one.
6. **Invite** — Open the exterior door. They may enter. Close it; new ones outside stay out.
7. **Take down** — Right-click the hung talisman → Take Down Talisman. The house is unsealed.
8. **Town** — Walk a street you have not loaded this save. Some windows/doors should already be broken or boarded.
9. **Ultra-strong** (optional) — Turn the option on, restart, take hits with no armour. You should drop in 3–4 landed hits.
10. **Darkness** (optional) — Raise “Darkness roll each day” to 100, wait until 07:00 for a schedule; warning then fog/blackout.

If Lua errors appear, check `C:\Users\<you>\Zomboid\Logs\` for `FromZoid` in the stack.
