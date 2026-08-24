# FromZoid — Claude handoff (2026-08-24)

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
| `fromzoidGather` / `fromzoidGatherAt` | Night horde path; 20s repath cooldown. |
| `fromzoidNestAt` | Last nest or street-walk path (2–10s cooldown). |
| `fromzoidStillUntil` | “They all look” freeze (~9s). |
| `fromzoidVoice` | Sticky voice id (Vlad/Miles/Knox or Roxie/Annie/Zelda). |
| `fromzoidDayNest` | Created during daylight; send to nest. |

Player: `fromzoidStrain` (0–100), `fromzoidSanityBand` (`sanity` / `delusion` / `psychosis`).

---

## How the systems work now

### 1. Sun, nest, sleep (`FromZoid_Sun.lua` + Core)

- **Dawn** (`processSunCycle` when clock night → day): `clearZombieHunt`, `releaseHold`, eject from sealed interiors, nest or `walkAwayFromHouse`.
- **Dusk**: release hold, wake bodies; later `trickleOutside` lures a percent of indoor sleepers to the street.
- **Every minute, clock day**: `herdIndoors` releases leftover hold/hunt, nests, or street-walks anyone still outside.
- **Every zombie update, clock day**: `onDayZombieUpdate` wakes outdoor useless, nests if sliced, otherwise street-walks. Hunt through a sealed house is cleared unless `sameUnsealedBuilding`. Loud sounds inside a sealed uninvited house do not wake the street.
- Nest dest: nearby unsealed residential, prefer basement if sandbox on, skip sealed and occupied (player) buildings.
- `sendZombieToNest` returns **true** if already hidden, teleported, path issued, or nest cooldown is running. Returns **false** only if it could not nest (no tile / would launch). Callers must not treat “path started” as failure or they overwrite the nest with a street lure.

Sleep: `pinZombieSleepPose` / `stripLaunchPoses` — useless freeze only.

### 2. Pathing and “flying” (do not regress)

Vanilla pathing across buildings or z-levels, plus `pathFindBehavior2:cancel`, plus teleport-when-`isOnScreen` is false, all produced flying/teleport when the player looked at them.

Current rules:

- `pathWouldLaunch(zombie, dest)`: vertical change, or crossing building ids, **while any player is within 40 tiles**, is a launch → skip the path.
- **Exception:** same z, dest **outdoors**, distance² ≤ 256 (16 tiles) is **never** a launch. That is how porch → street works while you watch from a window.
- `allowVisibleTeleport`: no player within 40 tiles **and** offscreen helper. Not `isOnScreen` alone.
- `allowNestTeleport`: also refuses if already in a building, asleep, or held.
- `walkAwayFromHouse` / `streetSquareAway`: pick a free outdoor tile 4–20 tiles away with no door/window, then `pathZombieToSquare` (which respects `pathWouldLaunch`).

### 3. Talisman siege (`FromZoid_Talisman.lua`)

Night (`isClockNight`):

- Anyone thumping a sealed house, standing in it, on/near an opening, against the building AABB (+2 tiles), or hunting within 20 tiles (`d2 <= 400`) is `keepOffSealedHouse(..., true)`.
- `keepOffSealedHouse`: stop thump, clear target, eject if truly inside a room, `stepOffOpening` (1–2 tile shove onto the outdoor porch if they occupy the door/window square), then `holdAtGlass`.
- `holdAtGlass` **re-applies every tick**: `fromzoidHold`, useless, `setTarget(nil)`, `setCanOpenDoors(false)`, thump cleared, `setPath2(nil)`, motion zeroed. Do not early-return when already held — vanilla re-acquires through glass between ticks.
- `reconcileZombieState` **keeps** hold at clock night if sealed-uninvited and (near opening **or** against `watchBuilding`). Old code released anyone not on the opening itself; they then charged the glass.

Day (clock):

- Release hold, clear hunt, nest if possible, else `walkAwayFromHouse`.
- Do not wait for slice to shoo people around the sealed house.

Invitation: opening an exterior door/window marks the building invited; they may enter. Closed again: new ones outside stay out.

Worn charms: hung talisman lasts `TalismanNights` (default 7) then wilts.

### 4. Night gathering (`FromZoid_Gather.lua`)

Every `EveryOneMinute` while `isNight()` and gathering enabled: up to `GatheringMax` (default **40**) loaded zombies path to `standoffSquare` — two tiles **out** from the porch, not the door tile.

They stop when within 6 tiles of that standoff (`d2 <= 36`). Hold/still/hunt/indoor sleepers are skipped. 20s `fromzoidGatherAt` cooldown.

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

## Sandbox defaults that differ from the old plan doc

| Option | Plan (ENGAGEMENT) | Live 1.2.2 |
| --- | --- | --- |
| `GatheringIntervalNights` | 7 | **1** |
| `GatheringMax` | 12 | **40** |
| `NightSprinters` | off / hunt-only | **on**, day and night sprint |
| `StartWithSpareTalisman` | n/a | **on**; spawn house also hung |

---

## Smoke for the next agent

New save, cheat optional, **full restart** after overlay.

1. Dawn: loaded people go indoors and freeze. Walking into one can wake it. No fall-loop, no flying.
2. Dusk: they leave nests. With gathering on, a cap of them path to the talisman porch **standoff**, not through the glass.
3. Sealed house, player inside, sprint: they loiter / hold in the yard. They do not smash the window.
4. Open exterior door: invitation; they may enter. Close it; new ones stay out.
5. Sunrise while watching from the window: porch crowd walks down the street or nests next door. They do not remain in a ring all day.
6. Whispers at door/window at night; Knox only at windows.
7. Sanity moodle appears at delusion; veil does not steal clicks; sleeping through a whisper uses fade-in, not a black screen.
8. ~25% of houses have a gun + box; spawn house has a hung talisman.
