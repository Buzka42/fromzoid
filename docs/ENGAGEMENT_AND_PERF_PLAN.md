# FromZoid — engagement + performance plan

Status: **historical**. Live pack is **1.2.3**. Do not implement from this file.

For current tick order, hold/nest/doors/damage rules, sandbox defaults, and playtest fixes, use [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md). Gathering, sprinter, strain, and UltraStrong numbers in this plan are stale.


Restart PZ so sandbox options, items, and Lua load. New FromZoid sandbox rows default on; turn off what you do not want.

Target machine: i5-4460 (4 cores). PZ 42.20. Live copy: `%UserProfile%\Zomboid\mods\FromZoid`.

Core loop stays: they hide by day, hunt after dusk, cannot enter a hanging-charm house unless invited. New work must not add another `OnZombieUpdate` listener.

This pass: **options 2–5**, a **Lovecraftian woods / sanity** layer, and **sandbox loot / nest** knobs. **The Knock is parked** (not in this expansion).

Every new system is a sandbox toggle. Defaults below are the “full vibe” pack; you can turn any of it off.

---

## Tone

Town at night is still From-shaped: calm people at the glass, a charm on the door, they wait.

Leave the streetlights and it should feel like the **woods are an intelligence**. Fog that drinks depth, something saying your name with no mouth, the sense that walking out is how you get *kept*. Sanity is how that leaks back into town: first the radio knows you, then the house does not.

No copied show names. No new `OnZombieUpdate` hooks.

---

## Chosen features (2–5)

### 2. Worn charms

A hung talisman lasts N nights (default 7), then wilts and stops sealing. Refresh with sage / dried herbs, or hang a new one. Fail at dusk = you have no house that night.

Sandbox: `EnableWornCharms` (on), `TalismanNights` (7).

### 3. They walk until you run

Night people shamble and loiter unless you sprint, fire, or hit them. Then that cluster hunts. Night Sprinters = they *can* sprint when hunting, not that the whole map sprints at dusk.

Sandbox: `CalmUntilProvoked` (on), `GunshotWakesStreet` (on).

### 4. Gathering nights

Every Nth night (and during darkness) a **capped** group (default 12) stands in the street facing your house. They do not rush until you open an exterior door or step out. Whispers are more frequent. Crowd sanity drain is worse that night.

**Requires Phase 0 dispatcher.** Sandbox: `EnableGatheringNights` (on), `GatheringIntervalNights` (7), `GatheringMax` (12).

### 5. The trees keep you (Lovecraft)

At night, far from residential / far from any sealed house:

- Fog drinks view distance; the far plane blurs and desaturates.
- Voices with **no body** — your forename, not zombie chat bubbles.
- Ambient life goes quiet (no birds). Then something answers from the trees.
- Mild panic / sanity drain while you stay out there.
- You can still walk out. The woods do not wall you; they *invite* you further.

At **delusion** in the woods: the name-calls get closer; a light that is not a house; compass/minimap jitter (soft, not a spin-forever troll).

At **psychosis** in the woods: tunnel vision, regular disembodied speech, a scream with no source, the feeling of a crowd when the cell is empty.

Sandbox: `EnableWoodsDread` (on), `WoodsDistance` (tiles from residential/seal, default ~80).

---

## Sanity (the expansion spine)

One meter on the player (`ModData`, 0–100 strain). Moodles can echo it (stress/panic) but the **level** is ours so FX stay authored.

| Level | Range | Feel |
| --- | --- | --- |
| **Sanity** | 0–39 | Tired, jumpy. No fake broadcasts. |
| **Delusion** | 40–69 | The world *knows your name*. Slight, deniable. |
| **Psychosis** | 70–100 | The house and the woods lie to you. Vision goes. Hallucinations on a timer. |

### What lowers it

- **Sleep debt** — the longer since a real sleep, the faster it climbs (uses fatigue / time awake, not a second tiredness bar).
- **The gallery** — night people standing outside *your sealed house* (count capped for perf, e.g. 8 nearest within 12 tiles). More bodies = more drain.
- **They will not let you sleep** — if you are in bed and they are talking at the glass, wake the player and play a line. Insomnia / fatigue stays high. Sealed house with a crowd is a siege on rest, not a free hotel.
- **The woods at night** — extra drain while `EnableWoodsDread` applies.
- **Gathering nights** — gallery drain multiplier.

### What raises it

- Sleep that actually completes, indoors, with few or no loiterers.
- Daytime inside a sealed house.
- (Optional later) reading / radio that is *not* a delusion event.

### Delusion (slight, creepy)

Client, rare, `EveryOneMinute` / throttled `OnPlayerUpdate`. Never every tick.

- A radio or TV in the cell **turns on** and speaks a short original line with your **forename** (“We are still looking for —”, weather that names you, a numbers station that repeats your name). Then it dies.
- Trees / walls whisper the name (sound, no zombie).
- A **far** vanilla zombie scream with nobody on-screen.
- **Distance blur** — view distance down a little, mild desaturation (same climate hooks as darkness FX; snapshot + restore).
- Lights in an empty room flicker once.
- Footsteps on the floor you are not on, then stop.
- The hung charm *ticks* against the door (sound only).
- Walkie/static burst.
- A child’s laugh from the yard (existing voice bank, no body).
- Refrigerator / fluorescent hum that becomes speech for two seconds.
- Window reflection: a chat line from the glass square that is just your name.

### Psychosis (regular, impairing)

- Stronger fog / night strength / view-distance cut (tunnel). Optional drunk-like sway if the API is stable.
- Hallucination clock (e.g. every 45–90s): empty-room speech, a knock when the porch is empty, a “crowd” of footsteps outside, a scream, a fake “someone’s in the house” line from an indoor tile with no mover.
- Sleep is almost impossible while a gallery is present; even alone, sleep is fragile.
- Woods psychosis: compass jitter, name-calls, scream, false crowd.

**Will not do (too cruel or too heavy):** fake-unsealing a real talisman; spawning extra IsoZombies as hallucinations (native crash / loot / MP); blocking the player in the woods.

Sandbox:

- `EnableSanity` (on)
- `SanitySleepDrain` (multiplier, default 1)
- `SanityCrowdDrain` (multiplier, default 1)
- `WhispersBreakSleep` (on)
- `EnableDelusions` (on)
- `EnablePsychosis` (on)

If `EnableSanity` is off, delusion/psychosis/woods-name FX do not run (woods can still do fog-only if `EnableWoodsDread` is on).

---

## Loot and world (all toggles)

### Armed houses

When a residential building is first visited this save, roll **once per house** (not per dresser):

- `HandgunHouseChance` default **50** — a handgun in a bedroom dresser / wardrobe.
- `LongGunHouseChance` default **33** — a rifle/shotgun in a closet / wardrobe / crate.
- Always **at least 3 reloads** of the matching ammo in the same container (or next to it).

Do not dump guns into global procedural tables at those rates — that would fill every drawer in the house. Building-once is “1 in 2 houses.”

Sandbox: `EnableArmedHouses` (on), the two chances, `GunAmmoReloads` (3).

### Lodged high-end weapons

On zombie create, a small chance they carry / drop a lodged weapon: katana, machete, fire axe, etc. “More common than vanilla,” not “every corpse is a katana.” Visual lodge if B42 attached-item API is stable; otherwise inventory so it drops.

Sandbox: `EnableLodgedWeapons` (on), `LodgedWeaponChance` (default ~4, meaning ~1 in 25), optional `LodgedKatanaWeight` vs other high-end.

### Basements and nests — what PZ will allow

**We cannot spawn a real basement under every second vanilla house.** B42 basements are map geometry / building defs. Injecting floors would be a map mod, not a Lua overlay, and would desync / crash.

What we **will** do:

1. **Prefer real basements** — day nest search looks for `z < 0` (or basement-named rooms) in a wide radius, not “nearest house then maybe cellar.” People hide *under* the town when a cellar exists.
2. **Every-other-house nest assignment** — hash of `buildingId`: half of residential buildings are nest houses. Dawn teleport / path targets those (basement tile if present, else deep interior). The other half stay emptier by day. This is the “every 2nd house” *behavior*, not new stairs.
3. **Vicinity** — if the loaded cell has at least one real basement, night people from nearby streets prefer it. Spawn house still never becomes a nest on night 0.

Sandbox: `PreferBasementNests` (on), `NestEveryOtherHouse` (on).

If we later want literal extra cellars, that is a separate map/tileset project.

---

## Extra sandbox ideas (same fashion)

Invented, all optional:

- `TheyKnowYourName` — at delusion+, window whispers may say the forename (chat + voice still original lines; name is extra).
- `SilenceBeforeThem` — a few seconds of muted ambient before a whisper or woods call.
- `FalseDawn` — rare delusion: lighting pretends it is almost morning for ~30s, then night slams back. Off by default.
- `HungryAir` — psychosis only: extra hunger/thirst tick. Off by default (easy to feel cheap).
- `TalismanTicks` — delusion sound on the hung charm. Can live under delusions without its own toggle.
- `CompassLies` — woods + psychosis only. Off unless woods are on.

Do not ship FalseDawn / HungryAir in v1 unless you ask; they are easy to add later.

---

## Build order

Perf first. Sanity/woods are client FX + minute ticks — still do not ship them on the old four-listener zombie model.

| Phase | What |
| --- | --- |
| **0** | Performance dispatcher + caches (below). Playtest gate. |
| **1** | They walk until you run. Worn charms. |
| **2** | Sanity meter, sleep debt, gallery drain, whispers break sleep. Delusion + psychosis FX. Woods dread (Lovecraft), tied to level. |
| **3** | Gathering nights (feeds gallery + whispers). |
| **4** | Armed houses, lodged weapons. |
| **5** | Nest: prefer real basements, every-other-house nest assignment. |

Phase 0 is blocking. 1 is cheap and makes nights cheaper. 2 is the expansion. 3 needs the dispatcher and a hard cap. 4 is loot (new save or unvisited houses). 5 is nest search changes (safe after 0).

---

## Phase 0 — performance (do this first)

### Diagnosis

Four `OnZombieUpdate` callbacks run for **every loaded zombie, every tick**:

1. `enforceTalisman` — DistTo, seal, `setTarget(nil)` on the 18-tile crowd.
2. `Sun.onZombieUpdate` — `playerList()` **per zombie**, DistTo, RNG.
3. `People` first-tick `wipeBlood`.
4. Create-only spawn-house delete is fine.

Also: `processSunCycle` may `nearestPorchSquare` per zombie per minute; `isZombieOffscreen` rebuilds player lists; `wakeZombie(..., true)` walks a whole building; town writes ModData for every residential square including `"none"` clusters; `applyStrength` every minute; night-0 evict every minute; `isNight()` pcalls climate every call.

### Work

1. One `OnZombieUpdate` dispatcher, round-robin `1/N` of loaded zombies (N ≈ 8–16).
2. Tick cache: night, players, occupied building, sealed/invited, sandbox flags. Range via `dx*dx+dy*dy` before DistTo.
3. Seal work only if a player is in a sealed uninvited house. Eject only inside / on that opening. Do not clear target on the whole crowd every tick.
4. One porch square per occupied building per minute. Stop pathing every zombie within 24 every minute (gathering/gallery will pick a cap instead).
5. Day wake: only sleepers within 6 tiles; cap building flood.
6. Blood wash only on create.
7. Town: if cluster is `"none"`, return before `alreadyDone`.
8. Drop minute `applyStrength`; cache dawn/dusk ~1s; night-0 evict much less often.
9. **Playtest:** loaded street, day sleepers, sealed house at night, climb with a crowd. Hitch or silent death → fix before Phase 1.

---

## Implementation notes (Phase 2+)

- Player name: `getDescriptor():getForename()` (fallback username). Original radio copy, not show quotes.
- Sleep: `isAsleep` / wake + sound; do not busy-loop. Gallery count from cached nearby list, not a full cell scan every tick.
- FX: extend `FromZoid_DarknessFx.lua` snapshot/restore so woods + delusion + darkness do not stomp each other (stack: darkness < woods < psychosis, or a single “wanted snap” mixer).
- Hallucinations: **audio + climate only** in v1. No fake zombies.
- Armed houses: ModData `FromZoidArmed[buildingId]`; find one container; vanilla pistol/revolver/rifle/shotgun IDs for 42.20.
- Lodged weapons: `OnZombieCreate` chance; pcall attached-item; fallback `getInventory():AddItem`.
- Nest: change `pickNestSquare` to “nearest nest-eligible building with basement in range, else nearest nest-eligible.” `NestEveryOtherHouse` uses id hash, never the locked spawn building.

---

## Rules

- Sandbox on/off (and chances) for every bullet above.
- No extra `OnZombieUpdate` registrations.
- No `pathFindBehavior2:cancel` except when teleporting off a sealed opening.
- No `setHealth`; extra damage stays `ReduceGeneralHealth`.
- Copy to `%UserProfile%\Zomboid\mods\FromZoid` after edits. Restart for sounds/items/loot.
- After code edits: `python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path(r'C:\Users\Arawn\fromzoid'))"`

## Playtest (after 0–2)

1. Day street: no hitch; sleepers still.
2. Night, sealed, sprint in the street: nearby hunt, far stay calm.
3. Crowd at the glass: sanity climbs; sleep gets broken by talk.
4. Stay awake + woods at night: delusion radio/name, then psychosis tunnel + hallucinations.
5. Sleep through a quiet day in a sealed house: meter falls.
6. Climb with a crowd: no silent crash.
7. (Later) gathering night; first visit to houses for guns; dawn people in real cellars / every-other nest house.
