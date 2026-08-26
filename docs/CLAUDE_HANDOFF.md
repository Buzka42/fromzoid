# FromZoid — Claude handoff (2026-08-24, 1.2.3 pass)

Project Zomboid **Build 42.20.3** mod. Current `mod.info` version: **1.2.2**.

Repo: `C:\Users\Arawn\fromzoid` (GitHub `Buzka42/fromzoid`).  
Live playtest copy: `C:\Users\Arawn\Zomboid\mods\FromZoid`.

This file is the working memory for the next agent. Read it before changing zombie AI, talismans, sun cycle, or sanity. Companion docs: [VOICE_HANDOFF.md](VOICE_HANDOFF.md), [MOODLE_COMMISSION.md](MOODLE_COMMISSION.md), [ENGAGEMENT_AND_PERF_PLAN.md](ENGAGEMENT_AND_PERF_PLAN.md) (plan is older; gathering defaults below supersede it).

---

## How to work in this repo

1. Edit **only** files under `Contents/mods/FromZoid/`.
2. After Lua edits, overwrite the live copy. PZ 42.20 also keeps a duplicate tree — copy **both**:

```powershell
$src = "C:\Users\Arawn\fromzoid\Contents\mods\FromZoid\common\media\lua"
Copy-Item "$src\*" "C:\Users\Arawn\Zomboid\mods\FromZoid\common\media\lua" -Recurse -Force
if (Test-Path "C:\Users\Arawn\Zomboid\mods\FromZoid\common\media\lua\lua") {
  Copy-Item "$src\*" "C:\Users\Arawn\Zomboid\mods\FromZoid\common\media\lua\lua" -Recurse -Force
}
```

   Sandbox options live **outside** the lua tree (`common/media/sandbox-options.txt`). If you touch them, copy that file too — the lua-only copy silently misses it and the new option never appears in the menu.

3. Rebuild the graph after code changes:

```powershell
python -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path(r'C:\Users\Arawn\fromzoid'))"
```

4. Tell the user to **fully restart** PZ (not just reload Lua) after overlay, sound-script, translation, or `mod.info` changes.
5. Do not commit unless asked. Do not commit `_review_dump/`, `_review_dump2/`, or `graphify-out/cache/`.

---

## Hard constraints (do not violate)

These were set by the player and re-broken when ignored.

- **One** `Events.OnZombieUpdate`. It lives in `FromZoid_ZombieTick.lua`. Other files register `FromZoid.onDayZombieUpdate` / `FromZoid.onCalmZombieUpdate` / `FromZoid.enforceTalisman` and the tick calls them.
- **No** `pathFindBehavior2:cancel` except when teleporting a zombie **out of a real interior room** of a sealed house. Cancel on a live path launches them (looks like flying).
- **No** `setHealth`. Toughness is lore + armor factor (see Night stats).
- **Do not slam climate** (`nightStrength` / daylight) for sanity FX. Snapshot/restore only what Darkness already uses.
- Teleport is **off-screen only**. `IsoZombie:isOnScreen()` is **false through walls**, so it cannot be the visibility test. Use `FromZoid.allowVisibleTeleport` / `allowNestTeleport`.
- Day sleep is a **useless freeze**, not crawler / fake-dead / knockdown. Those poses lunge or loop when the player approaches.
- **Loiter is never `setUseless`.** `holdAtGlass` is the clamp for zombies actually on an opening; the crowd behind them must stay awake and shambling. A yard full of statues was the old behaviour and it is not the wanted one.
- Loiterers **own their gait**. `applyWalkType`, `applyAll` and `onCalmZombieUpdate` all skip `fromzoidLoiter`, so the sprint pass cannot reclaim them. They sprint the approach and shamble in the yard, by design.
- Every path out of the siege must call `FromZoid.clearLoiter`, or they stay pinned to the shamble gait and skipped by the calm pass forever.
- If `fromzoidAsleep` but the square is **not** an indoor hide, wake immediately.
- Translations for 42.20 are **JSON** under `shared/Translate/EN/` (`ContextMenu.json`, `IG_UI.json`, `ItemName.json`, `Moodles.json`, `Recipes.json`, `Sandbox.json`, `Tooltip.json`). Do not revive `*_EN.txt`.
- Moodle Framework is a **hard dependency** (`require=\MoodleFramework`, workshop `3396446795`).

---

## Architecture

### File map

| File | Role |
| --- | --- |
| `shared/FromZoid_Core.lua` | Clock, buildings, nest, path/teleport safety, hold, sleep, tick context |
| `server/FromZoid_ZombieTick.lua` | The only `OnZombieUpdate` |
| `server/FromZoid_Talisman.lua` | Seal enforcement, hold-at-glass, day shoo |
| `server/FromZoid_Sun.lua` | Dawn/dusk, day nest, herd, lure, The Still |
| `server/FromZoid_Gather.lua` | Night path to sealed-house standoff |
| `server/FromZoid_NightStats.lua` | Sprint, poor day senses, hunt flag, calm-until-provoked |
| `server/FromZoid_SanityTick.lua` | Strain up/down |
| `shared/FromZoid_Sanity.lua` | Bands, woods, gathering-night helper |
| `client/FromZoid_SanityFx.lua` | Veil / delusion / psychosis visuals |
| `client/FromZoid_SanityMoodle.lua` | Moodle Framework HUD |
| `client/FromZoid_Whispers.lua` | Door/window lines + ogg |
| `client/FromZoid_TalismanMenu.lua` | Hang / take down |
| `shared/FromZoid_TalismanUtil.lua` | Seal / invite data |
| `shared/FromZoid_Invite.lua` | Open door/window = invitation |
| `server/FromZoid_SpawnTalisman.lua` | Spawn house always hung; spare inventory option |
| `server/FromZoid_ArmedHouses.lua` | Sparse residential guns |
| `server/FromZoid_People.lua` | Civilian outfits + sticky voice |
| `server/FromZoid_Town.lua` | Boarded / damaged clusters |
| `server/FromZoid_Darkness.lua` | Multi-day fog/blackout |
| `server/FromZoid_Loot.lua` / `LodgedWeapons.lua` / `UltraStrong.lua` | Loot and optional hell mode |

### Clock vs “night”

| Helper | Meaning |
| --- | --- |
| `FromZoid.isClockNight()` | Sun is down (dawn/dusk from climate). Drives **nest, dawn shoo, hold vs walk away**. |
| `FromZoid.isNight()` | Clock night **or** an active darkness event. Drives whispers, gathering, hunter “night” feel. |
| `FromZoid.isDay()` | `not isClockNight()` |
| `ctx.night` in the tick context | `isNight()`, not clock. Do not use it to decide dawn nest. |

Talisman day/night split **must** use `isClockNight()`. If you use `ctx.night`, a darkness event in daylight keeps them frozen on the porch.

### Tick dispatcher (`FromZoid_ZombieTick.lua`)

Order, every zombie update:

1. Wake `fromzoidAsleep` if not indoor-hide; strip launch poses outdoors.
2. The Still pose (`fromzoidStillUntil`) short-circuits.
3. **Sliced** (`id % 10 == ctx.slice`): `reconcileZombieState`. Unsliced outdoor useless (and not held) is woken so they do not freeze forever.
4. **`enforceTalisman` every tick** (including unsliced). Night hold must be reapplied; vanilla re-targets between ticks.
5. Unsliced + clock-night + hold: return (skip day/calm). **During clock day, do not skip** — they must nest / walk away.
6. `onDayZombieUpdate` then `onCalmZombieUpdate`.

`FromZoid.TICK_SLICE = 10`. Expensive nest pathing is sliced; seal hold is not.

### Shared tick context

`FromZoid.refreshTickContext()` once per frame: players, sealed/invited flags, sprinting, gunshot, loud sound, `watchBuilding` / `watchPorch` for the first sealed uninvited player.

---

## Zombie ModData keys

| Key | Meaning |
| --- | --- |
| `fromzoidAsleep` | Day indoor freeze (`setUseless(true)`). Never outdoors. |
| `fromzoidHold` | Night freeze at a sealed house. Re-applied every tick. |
| `fromzoidHuntUntil` | Epoch ms; hunting / aggro. Cleared at dawn and when held at glass. |
| `fromzoidGather` / `fromzoidGatherAt` | Night horde membership; 20s repath cooldown. |
| `fromzoidLoiter` | Arrived at a sealed house and milling in the yard. Awake, shambling, never useless. |
| `fromzoidLoiterAt` / `fromzoidLoiterFor` | Loiter drift timer; new ring tile every 6–12s. |
| `fromzoidWalkTo` | Committed street-walk destination `{x,y,at}`. Held until arrival, 20s, or 5s of no movement. |
| `fromzoidWalkAt` | Street-walk cooldown, 8s. Kept separate from `fromzoidNestAt` on purpose. |
| `fromzoidNestSince` | Start of the current nest-attempt run. 30s without getting indoors = give up so callers escalate. |
| `fromzoidNestAt` | Last nest or street-walk path (2–10s nest, 8s street). |
| `fromzoidStillUntil` | “They all look” freeze (~9s). |
| `fromzoidVoice` | Sticky voice id (Vlad/Miles/Knox or Roxie/Annie/Zelda). |

Player: `fromzoidStrain` (0–100), `fromzoidSanityBand` (`sanity` / `delusion` / `psychosis`).

---

## How the systems work now

### 1. Sun, nest, sleep (`FromZoid_Sun.lua` + Core)

- **Dawn** (`processSunCycle` when clock night → day): `clearZombieHunt`, `releaseHold`, eject from sealed interiors, nest or `walkAwayFromHouse`.
- **Dusk**: release hold, wake bodies; later `trickleOutside` lures a percent of indoor sleepers to the street.
- **Every minute, clock day**: `herdIndoors` releases leftover hold/hunt, nests, or street-walks anyone still outside. It escalates on `dawnMinute` (minutes since sunrise, file-local in `FromZoid_Sun.lua`, nil at night):
  - **0–10**: staggered — only `zombieID % 5 == dawnMinute % 5` is processed, so the yard drains a fifth at a time instead of the whole crowd turning on one tick.
  - **11–30**: everyone, path or `allowNestTeleport`.
  - **30+**: still outdoors and `allowVisibleTeleport` → force-teleport into a nest. No recorded dawn (mid-day load) counts as phase 99.
- Nest buildings are picked **per zombie**, seeded among the **nearest 5** candidates and spilling outward only when they fill, with a per-building sleeper cap (`FromZoid.NEST_CAPACITY`, 6). Everyone rolling the same `ZombRand` piled the crowd into one house.
- **Every zombie update, clock day**: `onDayZombieUpdate` wakes outdoor useless, nests if sliced, otherwise street-walks. Hunt through a sealed house is cleared unless `sameUnsealedBuilding`. Loud sounds inside a sealed uninvited house do not wake the street.
- Nest dest: nearby unsealed residential, prefer basement if sandbox on, skip sealed and occupied (player) buildings.
- `sendZombieToNest` returns **true** if already hidden, teleported, path issued, or nest cooldown is running. Returns **false** if it could not nest (no tile / would launch) **or if it has been retrying for 30s without getting indoors** (`fromzoidNestSince`). Callers must not treat “path started” as failure or they overwrite the nest with a street lure.
- **The give-up matters.** `herdIndoors` returns early on a `true`, so without it a zombie whose nest tile was simply unreachable reported success forever: it never fell through to the street walk and never reached the phase>30 force-teleport. Measured in the 2026-08-24 playtest as `outdoor` plateauing at 14 with `walking=0` for the whole day. `walkAwayFromHouse` clears `fromzoidNestSince` when it commits a new destination, so the cycle is try-nest 30s → give up → walk → try again from the new spot.
- `noteNestClaim` counts **distinct zombies**, not calls. Counting retries let one stuck zombie mark a house full within seconds and starve the pool.

Sleep: `pinZombieSleepPose` / `stripLaunchPoses` — useless freeze only.

### 2. Pathing and “flying” (do not regress)

Vanilla pathing across buildings or z-levels, plus `pathFindBehavior2:cancel`, plus teleport-when-`isOnScreen` is false, all produced flying/teleport when the player looked at them.

Current rules:

- `pathWouldLaunch(zombie, dest)`: vertical change, or crossing building ids, **while any player is within 40 tiles**, is a launch → skip the path.
- **Exception:** same z, dest **outdoors**, distance² ≤ 256 (16 tiles) is **never** a launch. That is how porch → street works while you watch from a window.
- **The cross-building rule only applies when the zombie is currently INSIDE a building** (`zb and buildingId(zb) ~= buildingId(db)`). The flyer was always an interior zombie having a live path cancelled or being teleported through a wall. Walking in from **outdoors** on the same floor is ordinary pathing through a door and is never a launch, at any distance.
  - The old rule fired on any id mismatch, and an outdoor zombie has **no** building id, so *every* outdoor → nest path failed while a player was within 40 tiles. Both the path and the teleport route were shut for exactly the dawn crowd on the porch. Do not re-tighten this without fixing dawn another way.
- `allowVisibleTeleport`: no player within 40 tiles **and** offscreen helper. Not `isOnScreen` alone.
- `allowNestTeleport`: also refuses if already in a building, asleep, or held.
- `walkAwayFromHouse` / `streetSquareAway`: pick a free outdoor tile 4–20 tiles away with no door/window, then `pathZombieToSquare` (which respects `pathWouldLaunch`).
- `walkAwayFromHouse` **commits** (1.2.3): it stores `fromzoidWalkTo` and returns `true` while en route, re-pathing only on arrival, after 20s, or when the goal produced no movement for 5s (a path that silently failed to issue). 8s floor on `fromzoidWalkAt`.
- **Never `setPath2(nil)` on a per-tick code path unless you re-issue a path in the same tick.** `enforceTalisman` runs every tick and `walkAwayFromHouse` honours a 20s commitment, returning `true` without re-pathing. Clearing the path each tick therefore stripped the path issued on the previous tick and never replaced it, leaving the zombie permanently pathless against the wall with vanilla shoving it into the geometry. Measured 2026-08-24 as `atwall` pinned at 4-9 all day and `outdoor` plateauing at 26. Force a fresh route only when `zombieStalled` says the current one is going nowhere, by clearing `fromzoidWalkTo` + `fromzoidWalkAt` and letting `walkAwayFromHouse` re-path. (`loiterNearHouse` does clear the path, but re-paths in the same tick, which is why night was unaffected.)
- The day peel **skips zombies already in an indoor hide**. Stall detection fires on sleepers by definition -- they are not moving -- and without the guard it marched nested zombies back out into the street.
- `walkAwayFromHouse` uses **`fromzoidWalkAt`**, never `fromzoidNestAt`. Sharing that key made `sendZombieToNest` read a street walk as "a nest path is already running" and answer `true`, so every caller thought the zombie had gone to hide and stopped pushing it. That was a direct cause of the porch crowd. It used to re-roll every 2s from a fixed compass order, so the dawn crowd jittered in place and everybody drifted east. `streetSquareAway` now scores directions by a dot product against the away-vector plus a jitter, so they fan out.

### 3. Talisman siege (`FromZoid_Talisman.lua`)

**The siege keys off the HOUSE, never off the player.** `enforceTalisman` finds `FromZoid.nearestSealedBuilding(zombie, 40)` from the talisman data. It used to gate on `ctx.anySealedUninvited`, which is only true while a player is stood inside a sealed uninvited building — so stepping outside, *or simply leaving a window open* (which counts as an invitation), switched the entire hold/loiter layer off and the horde reverted to vanilla and walked into the doors and walls. In the 2026-08-24 log this showed as `loiter` flickering 14 → 0 → 14. `reconcileZombieState` uses the same test so the two cannot disagree.

Night (`isClockNight`):

Response is **graded** by distance to the building AABB (1.2.3). Freezing everything inside AABB+2 turned the whole siege into statues, and the old standoff tile sat inside that band, so arrivals froze on contact:

| Where | What |
| --- | --- |
| On/near an opening, or AABB **+1** (`zombieTouchingBuilding`) | `holdAtGlass` — the anti-window-smash clamp, unchanged |
| AABB +2 … +8 (`zombieInRingBand`, `RING_MAX + 3`) | `loiterNearHouse` — mill about in the yard |
| Beyond | release hold, clear loiter, leave alone |

- Anyone thumping a sealed house or standing in it still goes through `keepOffSealedHouse`, which applies the table above.
- `keepOffSealedHouse`: stop thump, clear target, eject if truly inside a room, `stepOffOpening` (1–2 tile shove onto the outdoor porch if they occupy the door/window square), then `holdAtGlass`.
- `holdAtGlass` **re-applies every tick**: `fromzoidHold`, useless, `setTarget(nil)`, `setCanOpenDoors(false)`, thump cleared, `setPath2(nil)`, motion zeroed. Do not early-return when already held — vanilla re-acquires through glass between ticks.
- `reconcileZombieState` **keeps** hold at clock night if sealed-uninvited and (near opening **or** `zombieTouchingBuilding(watchBuilding)`). It must use the same tight test as `enforceTalisman`, or reconcile releases a hold that enforce reapplies next tick.

**THE TALISMAN FIELD RUNS DAY AND NIGHT, IDENTICALLY.** This is a player decision (2026-08-24) and it replaced a separate daytime path. There is no day/night split in `enforceTalisman` any more: hold at the glass, loiter in the ring band, same rules whatever the clock says.

*Why:* every daytime substitute for the field — clear the target, walk them off, send them to a nest — had to win a race against vanilla re-acquiring the player through a window, and lost. The field wins because it does not race: it freezes or re-drives them every tick regardless. Do not reintroduce a day-only behaviour here.

**Zombies keep `setCanOpenDoors(true)` everywhere except while actually standing in the field.** `loiterNearHouse` and `holdAtGlass` take it away so they cannot let themselves into the talisman house; `clearLoiter` and `releaseHold` must put it back. `clearLoiter` used not to, which left every zombie that had ever loitered permanently unable to open any door or gate for the rest of its life — seen in playtest as zombies trapped in a fenced yard running into a gate they should have been able to open. If you add another place that disables it, add the matching restore.

**Loitering is NIGHT behaviour only.** The field applies day and night, but what it *does* in the ring band differs:

| | On the glass (`zombieTouchingBuilding`) | Ring band (`zombieInRingBand`) |
| --- | --- | --- |
| Night | `holdAtGlass` (frozen) | `loiterNearHouse` (mill in the yard) |
| Day | `holdAtGlass`, released by leave pass | **dispersed outward** — never parked |

Parking the yard crowd in daylight turned the talisman house into a permanent car park: anything that wandered into the band was held there, and the leave queue drained it slower than it refilled. Measured 2026-08-25 as `loiter` dipping to 27 mid-morning and climbing back to 49. Day-band zombies get the same anti-charge treatment as a pass holder (tear down the pursuit path, re-drive the escape route) but are then handed to `dayDisperse`.

*Dispersal rides on top, it does not replace the field.* `herdIndoors` runs a **leave queue**: at most `LEAVE_SLOTS` (6) zombies hold a live `fromzoidLeaveUntil` pass at once, for `LEAVE_MS` (30s) each, topped up from whoever is still in the field. Only a pass holder is let out to nest or walk off. If it fails to get clear the pass lapses and the field takes it back, so a failed exit can never become a charge.

**The pass must outlast a real walk clear of the ring band.** The first version gave 10s on a rotating one-in-five slot; at shamble speed the walk out takes longer than that, so they were reclaimed mid-exit and re-loitered forever — the "loiterers never return to nest at sunrise" report. Do not shorten it, and do not go back to seed-rotation: with a long pass a rotating slot ends up granting one to everybody, which turns the field off.

*Consequences, all load-bearing:*
- `FromZoid_ZombieTick.lua` returns immediately when `fromzoidHold` is set, day or night. The old code only skipped at night.
- `onDayZombieUpdate` must **not** release the hold. It used to, every tick.
- `processSunCycle` must **not** mass-release the field at dawn. Freeing a dozen zombies two tiles from the glass in one tick, with the player in view, *is* the sunrise charge.
- `reconcileZombieState` keeps the hold in daylight too.
- `dayDisperse` takes `sliced`: nest picking scans buildings and room tiles *before* reaching its own cooldown, so it must not run every tick on every zombie.

**A sealed house and the person inside it are never a valid target, day or night.** `onCalmZombieUpdate` is gated on `ctx.night`, so `CalmUntilProvoked` stops suppressing aggro the instant the clock says day — at 07:00 the whole street is handed a free target through the window. `onDayZombieUpdate` therefore computes `sealedPlayer` and refuses to set a target, clears any hunt, and blocks both the `loud` and `hunting` re-target paths. Do not remove this on the grounds that the calm pass "already handles it": it does not, in daylight.

**Daytime window charge.** Vanilla re-acquires the player through glass every tick. `setTarget(nil)` alone does **not** stop it: the pursuit path vanilla already issued outlives the cleared target, and `walkAwayFromHouse` honours its 20s commitment and returns without re-pathing, so our escape route never goes back. At night `holdAtGlass` only wins because it freezes them outright. In daylight the day branch instead captures whether a target existed *before* clearing (`reacquired`), and on that signal tears down the path plus `fromzoidWalkTo` / `fromzoidWalkAt` / `fromzoidNestAt` and re-walks them away in the same tick. The teardown runs **every tick**, not throttled: a 1.5s throttle left vanilla's charge path running unopposed in between, which is what produced the "guided" charge. The jitter that a per-tick teardown seems to imply is avoided by separating two things — kill the pursuit path every tick, but re-drive the **same** committed destination via `FromZoid.repathWalkGoal` instead of rolling a new one. Only pick a fresh destination when there is no goal, or when `zombieStalled` says the current one is dead.

**The talisman protects the HOUSE, not the player.** Suppression must be conditional on the target actually sheltering:

- `FromZoid.exposedPlayerNear(zombie, 3)` — an unprotected player within melee range stands the field down entirely for that zombie, hold and all. Without this a held/loitering zombie could not swing at someone stood right next to it, reported as a long delay before zombies attack.
- `FromZoid.targetIsProtectedPlayer` gates the pursuit teardown. Stripping the target unconditionally meant a player in the open could not be chased anywhere near their own house.
- `FromZoid.targetIsExposedPlayer` gates abandoning dispersal — a target that is scenery or another zombie is not a reason to stop going to a nest.

**Clearing the target is cheap; tearing down the PATH is not.** Clear `setTarget(nil)` every tick freely — it stops vanilla making fresh pursuit decisions and disturbs nothing. But rebuilding the path every tick restarts A* before the zombie can take a step, so while the player stays visible they vibrate on the spot and never leave. Reported as "they catch aggro and just stay there". Decide whether to rebuild with `FromZoid.escapeStalled(zombie, edge)` — *are they actually gaining ground on the house* — not with "did vanilla acquire the player". `FromZoid.clearEscape` resets the tracking when they genuinely leave the siege.

**This failure hides from the census.** `targeting` reads near zero throughout, because the target *is* cleared every tick — it is the surviving path, not the target, that moves them. Do not read a low `targeting` as "not charging". `setCanOpenDoors(false)` is also applied near a sealed house in daylight.

Day (clock):

- Release hold, clear hunt, nest if possible, else `walkAwayFromHouse`.
- Do not wait for slice to shoo people around the sealed house.

Invitation: opening an exterior door/window marks the building invited; they may enter. Closed again: new ones outside stay out.

Worn charms: hung talisman lasts `TalismanNights` (default 7) then wilts.

### 4. Night gathering (`FromZoid_Gather.lua`)

Every `EveryOneMinute` while `isNight()` and gathering enabled: up to `GatheringMax` (default **40**) loaded zombies path to a **ring slot**.

`FromZoid.buildingRingSquares(building)` builds outdoor tiles around the whole perimeter at `RING_MIN`..`RING_MAX` (**2–5** tiles out from the AABB; 4–7 was tried first and read as too far off the house), cached per building per in-game minute. Each zombie owns a fixed arc: `ring[(zombieID % #ring) + 1]`. The old code sent every zombie to **one** shared porch tile, so forty bodies converged on a single square and shoved each other into the door and along the wall — that scrum was the "running into the door".

Ring membership is deliberately **not** filtered on `isFree`, or slot assignment reshuffles every time somebody stands still.

Slots are chosen from the **nearest 8 ring tiles to the zombie**, parted by id — not by `id % #ring` across the whole ring. The global version sent them to the far side of the house, so they traversed the perimeter hugging the wall to get there, which is what read as walking into the wall. `ringDriftSquare` likewise only picks tiles within ~7 tiles of where they already stand.

`loiterNearHouse` also watches for **stalling** (`FromZoid.zombieStalled`): a path to an unreachable tile leaves vanilla walking them straight at the obstacle, so if they have not moved a tile in 6s the path is dropped and a closer target picked.

Arrival is `zombieInRingBand` / `zombieTouchingBuilding`, not a distance to a point — the old `d2 <= 36` disk overlapped the building interior. On arrival they are handed to `loiterNearHouse` via `enforceTalisman`.

Membership is counted before new enrolments, so the horde cannot drift past `GatheringMax` across a long night.

`GatheringIntervalNights` default is **1**. `FromZoid.isGatheringNight()` still respects the interval for whisper bonus / sanity crowd; the gather ticker itself runs every `isNight()` so old saves with interval 7 still get hordes.

### 5. Night stats (`FromZoid_NightStats.lua`)

- Walk type `sprint1` **day and night** if `NightSprinters` is on (not only while hunting).
- Day senses: `ZombieLore.Sight = 3`, `Hearing = 3` (Poor). Night: restore snapshotted lore.
- Toughness without `setHealth`: `Toughness = 1` (Tough) + `ZombiesArmorFactor * 2` (cap 4), defense `* 1.25` cap 95. Lore is captured once into `FromZoidState`.
- `CalmUntilProvoked`: no hunt until sprint/gunshot/hit. **Do not** mark hunting if the player is sealed uninvited within 20 tiles — that was “sprint inside the house → street slams the windows.”
- `markZombieHunting` must not release hold when `anySealedUninvited`. Hunt + sealed house = keep the hold.

### 6. Sanity, moodle, whispers

Strain 0–100. Hysteresis: enter delusion 40 / psychosis 70, exit 28 / 58. Bands stored on the player so FX do not flicker.

Moodle Framework moodle `FromZoidSanity`; icons `media/ui/FromZoidSanity_Bad_2.png` (delusion) and `_3.png` (psychosis). See [MOODLE_COMMISSION.md](MOODLE_COMMISSION.md).

Whispers: night, player in a **sealed** house, zombie DistTo ≤ 12, at door or window, 45s cooldown. Knox **windows only**. Voices: Vlad/Miles/Knox (male), Roxie/Annie/Zelda (female). Sticky `fromzoidVoice`. Garbled-name oggs are off-player (not the listener’s emitter). `FromZoid.wakePlayer` uses `forceAwake` + `UIManager.FadeIn`.

Do not use climate slam for the veil.

### 7. Guns, spawn house, town

- `HandgunHouseChance` 25% of residential houses. Of those armed houses, `LongGunHouseChance` 12% get a long gun, else handgun. One ammo box + mag if needed (`GunAmmoReloads` 1). Already-visited buildings in `FromZoidArmed` moddata do not reroll.
- Spawn house: always try to hang a talisman. Spare talisman in inventory is sandbox `StartWithSpareTalisman`.
- Spawn house is **always boarded** (`BoardedSpawnHouse`, default on) via `FromZoid.boardUpBuilding`. Exterior windows and doors get planks, **except one exterior door** — preferring the door the talisman hangs on. Barricades need a hammer to remove and a fresh character has none, so boarding every exit would seal the player inside their own start house. If the building has no exterior door at all, windows are boarded and doors left alone. Only fires on a **new game** (`OnNewGame`, retried each minute on day 0); existing saves are not retro-boarded.
- Town: 64×64 residential clusters roll boarded vs damaged vs vanilla once.

---

## Work done to reach 1.2.2 (this playtest thread)

Shipped in the working tree, not necessarily all committed before this handoff.

**Gameplay (intentional):**

- Day sprinters + poor day senses + stay inside.
- Toughness 2× via lore, not health.
- Night hordes to every sealed talisman house, cap 40, every night.
- Sparse house guns; exclusive long-gun roll.
- Sanity moodle, JSON translations, garbled-name clips, spawn-house hang.

**Bugs that were real in playtest (fix in this order if they return):**

1. **Fall/get-up loop (day indoor)** — knockdown sleep. Vanilla stands them up; sleep reapplied. **Fix:** useless freeze only.
2. **Fake-dead sleep lunged** when the player got close. **Fix:** no fake-dead / crawler sleep.
3. **Flying on approach** — `isOnScreen` false through walls → nest/eject teleported; `pathFindBehavior2:cancel` launched. **Fix:** 40-tile player check; no cancel; `pathWouldLaunch`.
4. **Frozen outdoors** — `fromzoidAsleep` pinned every tick regardless of location; unsliced useless returned early and never woke. **Fix:** outdoor sleepers always wake; unsliced outdoor useless no longer skips day update.
5. **Aggro through sealed glass** — hunt released hold; `holdAtGlass` no-op if already held; vanilla re-acquired and walked into the window. Calm treated indoor sprint as street aggro. **Fix:** keep hold when sealed; re-apply hold every tick; don’t hunt through an uninvited seal.
6. **Dawn crowd on the porch** — hunt not cleared; nest bailed on hunt; `pathWouldLaunch` treated porch→street as leaving a building; `sendZombieToNest` returned false after starting a path so lure overwrote/failed; gather stood on the door tile. **Fix:** clock-day shoo, short outdoor paths allowed, nest returns true when pathing, `standoffSquare`, `walkAwayFromHouse`, `stepOffOpening`.

---

## Work done in the 1.2.3 pass (loiter + dispersal)

Two player-reported failures, both traced to concrete causes rather than tuning.

**1. Gatherers ran into the door/wall instead of loitering.** Four compounding causes:

- `sealedTargets` built **one** target per house, so the whole horde converged on a single porch tile and shoved each other into the opening. → per-zombie **ring slots** around the whole perimeter.
- There was **no loiter state at all**. `fromzoidGather` was written and never read anywhere; the only "arrived" state was `holdAtGlass`, a `setUseless` freeze. → new `loiterNearHouse`.
- The hold trigger (AABB **+2**) was *wider* than the standoff it sent them to, so arrivals froze on contact or fought the boundary. → graded `zombieTouchingBuilding` (+1) vs `zombieInRingBand` (+2…+10).
- Arrival was a 6-tile disk around a point, which overlapped the building interior. → band test against the AABB.
- Gatherers also arrived **sprinting** (`NightSprinters` is on day and night). → loiterers force `walkType ""`; the sprint passes skip them.

**2. A lot of them remained after sunrise.** One decisive cause plus two that stopped recovery:

- `pathWouldLaunch` returned "launch" for any path whose destination building id differed from the zombie's, whenever a player was within 40 tiles. A nest tile is *inside* a building and a gathered zombie is outdoors, so **both** routes to a nest — path and teleport — were closed for exactly the crowd in the player's yard. Nesting was impossible by construction. → the ≤24-tile same-z exception.
- `walkAwayFromHouse` re-rolled a destination every 2s and `streetSquareAway` returned the first free compass direction (east), so nobody ever arrived anywhere. → commitment + directional scoring.
- Dawn was a single event with no follow-through. → the escalating `dawnMinute` window.

**Also fixed in this pass:**

- `applyAll` ran `applySenses` **before** the `EnableNightStats` check, so disabling the option still nerfed day sight and doubled toughness. Added `restoreLore` to put the world back.
- `getSandboxOptions():set` for lore ran every in-game minute forever; now only on change (`pushLore`).
- `squareStillHasTalisman` returned `false` (→ **unseals the house**) when `getWorldObjects()` was nil, which can happen mid chunk load. Now fails safe like the nil-square branch.
- The Still was gated on a hard-coded `22:00–05:00`, but winter dusk is ~19:00, so it could never fire early in a short night. Now measured against `getDawnDusk`.
- `buildingHasOpenEntrance` cache 400ms → 2s. It walks every room square plus the AABB across every floor, and `squareIsIndoorHide` reaches it for **every zombie every tick**.
- Removed dead weight: `fromzoidDayNest` and `fromzoidSleepAt` (written/cleared, never read), `ctx.watchPorch` (a full perimeter scan per minute, consumed by nothing) and its `cachedPorchSquare` helper, the unused `wakeSameRoom`, and `standoffSquare` (superseded by the ring).
- `TalismanDebug` now prints a per-minute census (`loaded/outdoor/indoor/hold/loiter/gather/hunt` + `dawn+N`). Turn it on to get numbers instead of impressions.

**Verified statically, not in game:** all 27 Lua files parse under a real Lua 5.1 interpreter (PZ's Kahlua is 5.1 — no `goto`), and every `FromZoid.*` referenced is defined. Behaviour still needs the playtest below.

**Known not done:** the seven `EveryOneMinute` handlers still each sweep the zombie list. A true single-pass merge is not mechanical — `tickTheStill` needs its own pass to count before acting — so it was left alone rather than risk a regression right before a playtest.

---

## Open / last playtest status

Last player report before this doc: they still ran into windows/doors and a lot remained after sunrise. The fixes in **§3–4 and “Bugs” 5–6** were written for that and copied to the live mod. They need a **full restart** and a fresh night→aggro→sunrise pass.

If it still fails, check in this order:

1. Live duplicate `lua/lua` tree actually overwritten.
2. `enforceTalisman` using `isClockNight()` (not `ctx.night`).
3. `holdAtGlass` not early-returning.
4. `reconcileZombieState` not releasing hold for AABB-adjacent zombies.
5. `pathWouldLaunch` still allowing ≤16-tile outdoor dests.
6. Console Lua errors in `C:\Users\<you>\Zomboid\Logs\`.

Do not add a second `OnZombieUpdate` to “make hold more reliable.” Re-apply on the existing tick instead.

---

## Performance: EveryOneMinute is NOT once per real minute

`Events.EveryOneMinute` fires per **game** minute, and game time accelerates hard when the player sleeps or fast-forwards. Measured 2026-08-24: **8 firings per real second**, against a normal ~0.4 — a 20x burst.

Seven handlers hang off it and five sweep the whole loaded zombie list; two also write to the console. At 8x that is thousands of zombie visits and hundreds of log writes per second, and because the resulting stall makes PZ fire the accumulated game minutes all at once, **it feeds itself** until the game appears frozen.

Every expensive minute handler must therefore sit behind `FromZoid.realTimeGate(key, ms)`:

| Handler | Gate |
| --- | --- |
| `herdIndoors` | 1000ms |
| `tickGathering` | 1000ms |
| `trickleOutside` | 1500ms |
| `tickTheStill` | 2000ms |
| `tickCensus` | 2000ms (debug print) |
| `applyAll` (NightStats) | 1000ms |
| `tickSanity` gallery scan | 1000ms, counts cached |

`tickSanity` is gated **only on its zombie sweep**, not the whole function: the strain maths has to keep running every game minute or sleep drain changes rate.

Adding a new `EveryOneMinute` handler that touches every zombie without a gate will reintroduce the freeze.

## Sandbox defaults that differ from the old plan doc

| Option | Plan (ENGAGEMENT) | Live 1.2.2 |
| --- | --- | --- |
| `GatheringIntervalNights` | 7 | **1** |
| `GatheringMax` | 12 | **40** |
| `NightSprinters` | off / hunt-only | **on**, day and night sprint |
| `StartWithSpareTalisman` | n/a | **on**; spawn house also hung |

---

## Smoke for the next agent

New save, cheat optional, **full restart** after overlay. Turn on sandbox `TalismanDebug` for the per-minute census.

1. Dawn: loaded people go indoors and freeze. Walking into one can wake it. No fall-loop, no flying.
2. Dusk: they leave nests. With gathering on, a cap of them path to the **ring** around the sealed house — spread around the whole perimeter, not stacked on one porch.
3. Sealed house, player inside, sprint: they **shamble and mill about** in the yard at 2–5 tiles. Only the ones actually on a door or window freeze. They do not smash the window, and they do not stand as a ring of statues.
4. Sprint at them from outside: they charge at sprint speed, then drop to a shamble as they reach the ring.
5. Sunrise while watching from the window: the yard drains **a few at a time** over the first ten minutes, and they walk into neighbouring houses rather than jittering in the street. Census `outdoor` should fall steadily and `indoor` rise; by `dawn+30` the street should be effectively clear.
6. Open exterior door: invitation; they may enter. Close it; new ones stay out.
7. Whispers at door/window at night; Knox only at windows.
8. Sanity moodle appears at delusion; veil does not steal clicks; sleeping through a whisper uses fade-in, not a black screen.
9. ~25% of houses have a gun + box; spawn house has a hung talisman.
