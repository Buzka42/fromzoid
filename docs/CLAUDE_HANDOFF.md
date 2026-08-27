# FromZoid — Claude handoff (2026-08-26, 1.2.3)

Project Zomboid **Build 42.20.3** mod. Current `mod.info` version: **1.2.3**.

Repo: `C:\Users\Arawn\fromzoid` (GitHub `Buzka42/fromzoid`).  
Live playtest copy: `C:\Users\Arawn\Zomboid\mods\FromZoid`.

This file is the working memory for the next agent. Read it before changing zombie AI, talismans, sun cycle, sanity, or damage. Companion docs: [VOICE_HANDOFF.md](VOICE_HANDOFF.md), [MOODLE_COMMISSION.md](MOODLE_COMMISSION.md). [ENGAGEMENT_AND_PERF_PLAN.md](ENGAGEMENT_AND_PERF_PLAN.md) is stale; sandbox defaults and behaviour below supersede it.

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

4. Tell the user to **fully restart** PZ (not just reload Lua) after overlay, sound-script, translation, texture, or `mod.info` changes.
5. Do not commit unless asked. Do not commit `_review_dump/`, `_review_dump2/`, `_textures/`, `_tools/`, or `graphify-out/cache/`.

---

## Hard constraints (do not violate)

These were set by the player and re-broken when ignored.

- **One** `Events.OnZombieUpdate`. It lives in `FromZoid_ZombieTick.lua`. Other files register `FromZoid.onDayZombieUpdate` / `FromZoid.onCalmZombieUpdate` / `FromZoid.enforceTalisman` / `FromZoid.onUltraStrongUpdate` and the tick calls them. Do **not** add a second `OnZombieUpdate`.
- **No** `pathFindBehavior2:cancel` except when teleporting a zombie **out of a real interior room** of a sealed house. Cancel on a live path launches them (looks like flying).
- **No** `setHealth` on zombies. Toughness is lore + armor factor (see Night stats). Player extra damage in UltraStrong is `ReduceGeneralHealth` + body-part wounds, not zombie `setHealth`.
- **Do not slam climate** (`nightStrength` / daylight) for sanity FX. Snapshot/restore only what Darkness already uses.
- Teleport is **off-screen only**. `IsoZombie:isOnScreen()` is **false through walls**, so it cannot be the visibility test. Use `FromZoid.allowVisibleTeleport` / `allowNestTeleport`.
- Day sleep is a **useless freeze sitting** (`setSitOnGround`). Never `setOnFloor` / crawler / fake-dead / knockdown. Re-apply `pinZombieSleepPose` every tick while asleep indoors. **Wake** if the player is in the same unsealed building or within 3 tiles (and not sealed). If `fromzoidAsleep` but the square is **not** an indoor hide, wake immediately.
- **Loiter is never `setUseless`.** `holdAtGlass` is the clamp for zombies actually on an opening; the crowd behind them must stay awake and shambling.
- Loiterers **own their gait**. `applyWalkType`, `applyAll` and `onCalmZombieUpdate` all skip `fromzoidLoiter`. They sprint the approach and shamble in the yard.
- Every path out of the siege must call `FromZoid.clearLoiter`, or they stay pinned to the shamble gait forever.
- `setCanOpenDoors(true)` everywhere except while **held or loitering** at a sealed house. `clearLoiter` / `releaseHold` must restore it.
- Translations for 42.20 are **JSON** under `shared/Translate/EN/`. Do not revive `*_EN.txt`.
- Moodle Framework is a **hard dependency** (`require=\MoodleFramework`, workshop `3396446795`).
- **No sanity debug menu.** `FromZoid_SanityDebug.lua` was deleted. Do not add a world-context “FromZoid sanity” submenu or `/fromzoid` chat commands.

---

## Architecture

### File map (26 Lua files)

| File | Role |
| --- | --- |
| `shared/FromZoid_Core.lua` | Clock, buildings, nest, path/teleport safety, hold, sleep, doors, tick context |
| `server/FromZoid_ZombieTick.lua` | The only `OnZombieUpdate` |
| `server/FromZoid_Talisman.lua` | Seal enforcement: hold-at-glass, night loiter, day disperse |
| `server/FromZoid_Sun.lua` | Dawn/dusk, day nest, leave queue, lure, The Still (no chat line), census |
| `server/FromZoid_Gather.lua` | Night path to sealed-house ring slots |
| `server/FromZoid_NightStats.lua` | Sprint, poor day senses, hunt flag, calm-until-provoked |
| `server/FromZoid_UltraStrong.lua` | Optional hell-mode hits (AttackOutcome + OnPlayerGetDamage) |
| `server/FromZoid_SanityTick.lua` | Strain up/down (`STRAIN_GAIN_MUL = 0.2`) |
| `shared/FromZoid_Sanity.lua` | Bands, woods, mental multiplier, gathering-night helper |
| `client/FromZoid_SanityFx.lua` | Veil / delusion / psychosis visuals |
| `client/FromZoid_SanityMoodle.lua` | Moodle Framework HUD |
| `client/FromZoid_Whispers.lua` | Door/window lines + ogg |
| `client/FromZoid_TalismanMenu.lua` | Hang / take down / refresh |
| `shared/FromZoid_TalismanUtil.lua` | Seal / invite data |
| `shared/FromZoid_Invite.lua` | Open door/window = invitation |
| `server/FromZoid_SpawnTalisman.lua` | Spawn hang, board, spare inventory, 07:00 alarm clock |
| `server/FromZoid_ArmedHouses.lua` | Sparse residential guns |
| `server/FromZoid_People.lua` | Civilian outfits + sticky voice + doors on create |
| `server/FromZoid_Town.lua` | Boarded / damaged 64×64 clusters |
| `server/FromZoid_Darkness.lua` | Multi-day fog/blackout |
| `server/FromZoid_Loot.lua` / `LodgedWeapons.lua` | Loot and lodged blades |

Body overlays live in `media/textures/Body/` (`M_ZedBody*` / `F_ZedBody*`). `TalismanDebug` census prints the skin texture names live zombies actually use. Overriding `M_ZedBody*` does **nothing** if the game draws `MaleBody0X` instead.

### Clock vs “night”

| Helper | Meaning |
| --- | --- |
| `FromZoid.isClockNight()` | Sun is down (dawn/dusk from climate). Drives **nest, dawn leave queue, hold vs walk away**. |
| `FromZoid.isNight()` | Clock night **or** an active darkness event. Drives whispers, gathering, hunter “night” feel. |
| `FromZoid.isDay()` | `not isClockNight()` |
| `ctx.night` in the tick context | `isNight()`, not clock. Do not use it to decide dawn nest. |

The talisman **field** keys off the house, not the clock. Clock night vs day only changes what happens **in the ring band** (loiter vs disperse). If you gate the field on `ctx.night`, a darkness event in daylight keeps them frozen on the porch, and gating it off in daylight lets them charge the glass.

### Tick dispatcher (`FromZoid_ZombieTick.lua`)

Order, every zombie update:

1. Wake `fromzoidAsleep` if not indoor-hide; **re-pin sleep pose** if still indoors asleep; strip launch poses outdoors.
2. `onUltraStrongUpdate` (no-op unless sandbox UltraStrong is on). Must run on this tick — there is no other `OnZombieUpdate`.
3. The Still pose (`fromzoidStillUntil`) short-circuits.
4. **Sliced** (`id % 10 == ctx.slice`): `reconcileZombieState`. Unsliced outdoor useless (and not held) is woken so they do not freeze forever.
5. **`enforceTalisman` every tick** (including unsliced).
6. Sliced + not hold/loiter: `setCanOpenDoors(true)`.
7. **`fromzoidHold` return**, day or night. Nothing downstream may undo the field.
8. Unsliced indoor useless may return unless loud/gunshot/hunt.
9. `onDayZombieUpdate` then `onCalmZombieUpdate`.

`FromZoid.TICK_SLICE = 10`. Expensive nest pathing is sliced; seal hold is not.

### Shared tick context

`FromZoid.refreshTickContext()` once per frame: players, sealed/invited flags, sprinting, shouting→loud, gunshot, `watchBuilding` for the first sealed uninvited player. `watchPorch` was removed (a full perimeter scan, consumed by nothing).

---

## Zombie ModData keys

| Key | Meaning |
| --- | --- |
| `fromzoidAsleep` | Day indoor freeze (`setUseless` + sit). Never outdoors. |
| `fromzoidSleepWait` | Wait up to 8s after they stop moving before bedding down. |
| `fromzoidHold` | Freeze at a sealed opening. Re-applied every tick, day and night. |
| `fromzoidHuntUntil` | Epoch ms; hunting / aggro. Cleared at dawn and when held at glass. |
| `fromzoidGather` / `fromzoidGatherAt` | Night horde membership; 20s repath cooldown. |
| `fromzoidLoiter` | Arrived at a sealed house and milling in the yard. Awake, shambling, never useless. Night only. |
| `fromzoidLoiterAt` / `fromzoidLoiterFor` | Loiter drift timer; new ring tile every 6–12s. |
| `fromzoidLeaveUntil` | Daylight leave-pass expiry. At most 6 at once, 30s each. |
| `fromzoidWalkTo` | Committed street-walk destination `{x,y,at}`. Held until arrival, 20s, or 5s of no movement. |
| `fromzoidWalkAt` | Street-walk cooldown, 8s. Kept separate from `fromzoidNestAt`. |
| `fromzoidNestSince` | Start of the current nest-attempt run. **20s** without getting indoors = give up. |
| `fromzoidNestAt` | Last nest path (2–10s). Never share with walk. |
| `fromzoidEscapeEdge` / `fromzoidEscapeAt` / `fromzoidEscapeFails` | Daylight “are they gaining ground on the house” tracker. |
| `fromzoidStillUntil` | “They all look” freeze (~9s). No floating chat line. |
| `fromzoidVoice` | Sticky voice id (Vlad/Miles/Knox or Roxie/Annie/Zelda). |
| `fromzoidWhisperUntil` | Epoch ms; one walker approaching a window to speak. Field skips hold/loiter for them. |
| `fromzoidWhisperBackUntil` | After the line: walk back to the yard without being frozen on the glass. |
| `fromzoidWhisperX/Y/Z` / `fromzoidWhisperKind` | Dest tile and window/door for that walker. |
| `fromzoidAttackOut` | Last `AttackOutcome` string, for UltraStrong edge detect. |

Player: `fromzoidStrain` (0–100), `fromzoidSanityBand` (`sanity` / `delusion` / `psychosis`), `fromzoidUltraHitAt` (450ms extra-damage cooldown).

World state (`FromZoidState`): `spawnBuildingId` (first house), `spawnHouseIds` (all start houses), `spawnHangIds` / `spawnClockIds` / `spawnBoardIds`, `pendingSpawnSquares`, lore snapshots, darkness, `stillNight`. Spawn hang/clock/board is **per house**, not once per world.

---

## How the systems work now

### 1. Sun, nest, sleep (`FromZoid_Sun.lua` + Core)

- **Dawn** (`processSunCycle` when clock night → day): `clearZombieHunt`, **do not mass-release the talisman field**. Anyone near a sealed house stays in the field and leaves via the staggered leave queue. Others nest or `walkAwayFromHouse`.
- **Dusk**: wake bodies (hold is **not** mass-released if they are still in a sealed house’s field). Later `trickleOutside` lures a percent of indoor sleepers to the street.
- **Every minute, clock day**: `herdIndoors`.
  - Anyone within 12 tiles of a sealed house is **queued**, not released. At most `LEAVE_SLOTS` (6) hold `fromzoidLeaveUntil` for `LEAVE_MS` (30s). A shorter pass reclaims them mid-walk and they loiter forever. Do not go back to seed-rotation.
  - Everyone else escalates on `dawnMinute` (nil at night; mid-day load = phase 99):
    - **0–10**: staggered — `zombieID % 5 == dawnMinute % 5`.
    - **>12** + nest teleport + offscreen: force-teleport into a nest.
    - Else nest, else walk away.
- Nest buildings are picked **per zombie**, seeded among the **nearest 5** candidates, cap `FromZoid.NEST_CAPACITY` (6).
- **Damaged-cluster houses are preferred.** `EnableTown` rolls 64×64 cells boarded / damaged / none. `pickNearbyNestBuilding` tries damaged first; `isNestHouse` always accepts a damaged house even when `NestEveryOtherHouse` would skip it. Intact houses are the fallback.
- `sendZombieToNest` returns **true** if already hidden, teleported, path issued, or nest cooldown is running. Returns **false** if it could not nest **or if it has been retrying for 20s** (`fromzoidNestSince`). Callers must not treat “path started” as failure.
- `noteNestClaim` counts **distinct zombies**, not calls.

**Sleep pose:** `putZombieToSleep` → `pinZombieSleepPose`: useless, `setCanWalk(false)`, **`setSitOnGround(true)` every pin**. Clears leftover on-floor flags. Never crawler / knockdown / fake-dead / `setOnFloor`. Indoor sleepers are re-pinned **every tick**. Wake clears sit and floor.

### 2. Pathing and “flying” (do not regress)

- `pathWouldLaunch(zombie, dest)`: vertical change, or crossing building ids, **while any player is within 40 tiles**, is a launch → skip the path.
- **Exception:** same z, dest **outdoors**, distance² ≤ 256 (16 tiles) is **never** a launch.
- **The cross-building rule only applies when the zombie is currently INSIDE a building.** Outdoor → nest on the same floor is ordinary door pathing and is never a launch. Tightening this again shuts dawn nesting while the player watches from a window.
- `allowVisibleTeleport`: no player within 40 tiles **and** offscreen helper. Not `isOnScreen` alone.
- `walkAwayFromHouse` **commits** `fromzoidWalkTo` and returns `true` while en route. Uses `fromzoidWalkAt`, never `fromzoidNestAt`.
- **Never `setPath2(nil)` on a per-tick code path unless you re-issue a path in the same tick.**
- Day peel **skips zombies already in an indoor hide** (stall detection fires on sleepers).

### 3. Talisman siege (`FromZoid_Talisman.lua`)

**The siege keys off the HOUSE, never off the player.** `enforceTalisman` finds `FromZoid.nearestSealedBuilding(zombie, 40)`. Gating on `ctx.anySealedUninvited` turns the field off when the player steps outside or leaves a window open.

Graded response to the building AABB:

| Where | Night | Day |
| --- | --- | --- |
| On/near an opening, or AABB **+1** (`zombieTouchingBuilding`) | `holdAtGlass` | `holdAtGlass` (leave pass lets them out) |
| AABB +2 … +8 (`zombieInRingBand`) | `loiterNearHouse` (mill in the yard) | **dispersed outward** — never parked |
| Beyond | leave alone | `dayDisperse` if sliced |

Do **not** loiter in daylight. Parking the yard turned the talisman house into a permanent car park (measured 2026-08-25: `loiter` 27 → 49 by mid-morning).

- `holdAtGlass` **re-applies every tick**: `fromzoidHold`, useless, `setTarget(nil)`, `setCanOpenDoors(false)`, thump cleared, `setPath2(nil)`, motion zeroed. Do not early-return when already held.
- `loiterNearHouse` is awake shambling, `setCanOpenDoors(false)`, walkType `""`, stall repath. `clearLoiter` **must** restore doors.
- An exposed player within 3 tiles, or `targetIsExposedPlayer`, **stands the field down** for that zombie so they can melee. The talisman protects the **house**, not a player in the yard.
- `targetIsProtectedPlayer` gates pursuit teardown. Unconditional `setTarget(nil)` meant a player in the open could not be chased near their own house.
- **Clearing the target is cheap; tearing down the PATH is not.** Rebuild only when `escapeStalled` says they are not gaining ground. Per-tick A* restart looks like “they catch aggro and just stay there”. Census `targeting` stays near zero because the target is cleared — the surviving path is what charges. Do not read a low `targeting` as “not charging”.

`onDayZombieUpdate` must **not** release the hold. `processSunCycle` must **not** mass-release the field at 07:00.

Invitation: opening an exterior door/window marks the building invited; they may enter. Closed again: new ones outside stay out.

Worn charms: hung talisman lasts `TalismanNights` (default 7) then wilts.

### 4. Night gathering (`FromZoid_Gather.lua`)

Every `EveryOneMinute` while `isNight()` and gathering enabled: up to `GatheringMax` (default **40**) loaded zombies path to a **ring slot**.

Ring is outdoor tiles `RING_MIN`..`RING_MAX` (**2–5** from the AABB), cached per building per in-game minute. Slots are the **nearest 8 ring tiles to the zombie**, parted by id. Arrival is `zombieInRingBand` / `zombieTouchingBuilding`, then `loiterNearHouse` via `enforceTalisman`.

`GatheringIntervalNights` default is **1**. `FromZoid.isGatheringNight()` still respects the interval for whisper bonus / sanity crowd; the gather ticker itself runs every `isNight()`.

### 5. Night stats (`FromZoid_NightStats.lua`)

- Walk type `sprint1` **day and night** if `NightSprinters` is on. Loiterers and sleepers are skipped.
- Day senses: `Sight = 3`, `Hearing = 3` (Poor). Night: restore snapshotted lore.
- Toughness without `setHealth`: `Toughness = 1` (Tough) + `ZombiesArmorFactor * 2` (cap 4), defense `* 1.25` cap 95.
- `applySenses` runs **after** the `EnableNightStats` check. `restoreLore` if the option is off. `pushLore` only on change.
- `CalmUntilProvoked`: no hunt until sprint/gunshot/hit. **Do not** mark hunting if the player is sealed uninvited within 20 tiles.
- `onCalmZombieUpdate` is gated on `ctx.night`. Daytime suppression of a sealed player is `onDayZombieUpdate`’s job.

### 6. UltraStrong (`FromZoid_UltraStrong.lua`)

Sandbox **`UltraStrong` defaults off**. Tooltip: unarmored dies in three or four hits.

`OnWeaponHitCharacter` **does not fire when a zombie hits the player** (it is a player-swing event). The old extra-damage path was dead code.

Hits are detected on the existing tick via `AttackOutcome` flipping to `"success"` (confirm hit reaction, or DistTo ≤ 1.7), plus `OnPlayerGetDamage` `"WEAPONHIT"` if a zombie is within 1.8 tiles. Both call `FromZoid.applyUltraStrongHit`, 450ms cooldown on the player.

Per landed hit, on top of vanilla: `ReduceGeneralHealth(18)` and one light limb wound (`AddDamage` 10, short bleed). Do **not** call `AddRandomDamageFromZombie` as a second full blow — that is a two-hit kill.

Also pushes `ZombieLore.Strength = 1` (Superhuman) while the option is on, every real-time second, and restores the captured value when off.

### 7. Doors

Vanilla `canOpenDoors` is false. Night people must open ordinary doors to nest and chase.

True on: `OnZombieCreate` (Core + People), sliced tick if not hold/loiter, `sendZombieToNest`, `wakeZombieBody`, `clearLoiter`, `releaseHold`.

False only in `holdAtGlass`, `loiterNearHouse`, and `clearPursuit` (sealed thump). If you disable it somewhere, restore it on the way out.

### 8. Sanity, moodle, whispers

Strain 0–100. Hysteresis: enter delusion 40 / psychosis 70, exit 28 / 58.

**Climb is slow:** `STRAIN_GAIN_MUL = 0.2` on every positive delta (player call 2026-08-25: descent was 5× too fast). Recovery is **not** scaled. Sandbox `SanitySleepDrain` / `SanityCrowdDrain` still multiply on top. Panic/stress/unhappy/bored raise `mentalStrainMul` (cap 2.4). Nearby playing audio halves gain.

Moodle Framework moodle `FromZoidSanity`. See [MOODLE_COMMISSION.md](MOODLE_COMMISSION.md).

Whispers: night, player in a **sealed** house. Candidates must be within `RING_MAX+3` of **this** house (gather tags include people still walking in from across town — do not use the tag alone). Pick someone **3–10 tiles** from the porch, never the farthest loaded zombie. Speak only on `whispererArrived` at that dest, never `nearKind` on a random window. First line of the night skips the chance roll. One walker sprints to the glass, speaks, then returns. Knox **windows only**. 45s approach, 45s cooldown after a line. Do not repath the walker on tick slice.

Do not use climate slam for the veil.

The Still (`tickTheStill`): rare deep-night freeze + knock. **No** `addLineChatElement`. Do not put the “They all stop at once” line back.

### 9. Guns, spawn house, town, clocks

- `HandgunHouseChance` 25% of residential houses. Of those, `LongGunHouseChance` 12% long gun, else handgun. `GunAmmoReloads` 1.
- Spawn house: hang, board, spare (`StartWithSpareTalisman`), and 07:00 clock run **for every new survivor’s house**, not once per world. `OnNewGame` plus `OnCreatePlayer` (hours≈0 only, so a save load does not re-board wherever you are). Pending spawn-square coords retry until the cell streams in. `isSpawnHouseId` skips nest and keeps zombies out (unless invited). Do **not** `removeFromWorld` inside `OnZombieCreate` — set `fromzoidEvict` and drop them on the first tick.
- Spawn house is **always boarded** (`BoardedSpawnHouse`) via `FromZoid.boardUpBuilding`. **Exterior** windows/doors only (`openingIsExterior` needs both squares; missing opposite is not outside). One exterior door stays clear (talisman door, and any existing planks on it are stripped). Never hang the charm on an interior door. Town “boarded” clusters use the same exterior-only rule.
- Spawn house gets a **07:00 alarm clock** (`Base.AlarmClock2`): arm any clock already in the house, else put one in a container / on a bedroom square, else give it to that player after three failed tries.
- Town: 64×64 residential clusters roll boarded vs damaged vs vanilla once. Damaged = smashed windows + clutter. Those cells are the preferred daytime nests.

---

## Work done to reach 1.2.2

**Gameplay:** day sprinters + poor day senses + stay inside; toughness 2× via lore; night hordes cap 40 every night; sparse house guns; sanity moodle; spawn-house hang.

**Bugs that were real (fix in this order if they return):**

1. **Fall/get-up loop** — knockdown sleep. **Fix:** no knockdown. `setOnFloor` also failed (random floor poses; standing when peeked). **Fix:** sit (`setSitOnGround`), never floor.
2. **Fake-dead sleep lunged.** **Fix:** no fake-dead / crawler.
3. **Flying on approach** — `isOnScreen` through walls; `pathFindBehavior2:cancel`. **Fix:** 40-tile check; no cancel; `pathWouldLaunch`.
4. **Frozen outdoors** — `fromzoidAsleep` pinned regardless of location. **Fix:** outdoor sleepers always wake.
5. **Aggro through sealed glass** — hunt released hold; hold no-op if already held. **Fix:** keep hold; re-apply every tick.
6. **Dawn crowd on the porch** — nest treated outdoor→building as launch; nest returned false after starting a path. **Fix:** allow same-floor outdoor paths; nest returns true when pathing; leave queue instead of mass-release.

---

## Work done in 1.2.3 (shipped `80a4938`)

Talisman field day and night; night loiter vs day disperse; leave queue 6×30s; ring slots instead of one porch tile; nest give-up 20s; damaged houses preferred for nests; sleepers lie down (`setOnFloor`); doors open except at the sealed field; UltraStrong actually lands (AttackOutcome); sanity climb ×0.2; spawn-house boarding retries + 07:00 clock; sanity debug menu removed; The Still has no floating text; body texture pack added (effect unverified — census prints real names).

**Also:** `squareStillHasTalisman` fails safe when `getWorldObjects()` is nil (chunk load used to unseal the house). The Still uses `getDawnDusk`, not a hard-coded 22:00. `buildingHasOpenEntrance` cache 2s.

**Known not done:** the several `EveryOneMinute` handlers still each sweep the zombie list. A true single-pass merge is not mechanical.

### Playtest 2026-08-26 (after `80a4938`)

Log `2026-08-26_17-02_DebugLog.txt` had **no Lua traceback** — it cut off after a second survivor spawned into a cell already nested (`bedded=103` in the new house). Spawn hang/board/clock was world-once, so the second house was a legal nest. `setOnFloor` sleep stood them up when peeked and leaked floor poses. Town junk used `Base.EmptyTinCan` (invalid in B42). Fixes: per-house spawn setup, sit sleep, deferred evict, `Base.TinCanEmpty`.

---

## Open / last playtest status

UltraStrong, sitting nests, ruined-house preference, and doors need a **full restart** after overlay. UltraStrong is **off by default** — turn it on in the FromZoid sandbox page.

If the siege fails, check in this order:

1. Live duplicate `lua/lua` tree actually overwritten (and `sandbox-options.txt` if you touched options).
2. `enforceTalisman` keys off `nearestSealedBuilding`, not `ctx.anySealedUninvited`.
3. `holdAtGlass` not early-returning.
4. Day ring band **disperses**, it does not loiter.
5. `pathWouldLaunch` still allowing ≤16-tile outdoor dests.
6. Console Lua errors in `C:\Users\<you>\Zomboid\Logs\`.

Do not add a second `OnZombieUpdate`.

---

## Performance: EveryOneMinute is NOT once per real minute

`Events.EveryOneMinute` fires per **game** minute. Sleep/fast-forward measured **8 firings per real second**. Ungated zombie sweeps freeze the game and then feed themselves.

Every expensive minute handler sits behind `FromZoid.realTimeGate(key, ms)`:

| Handler | Gate |
| --- | --- |
| `herdIndoors` | 1000ms |
| `tickGathering` | 1000ms |
| `trickleOutside` | 1500ms |
| `tickTheStill` | 2000ms |
| `tickCensus` | 2000ms (debug print) |
| `applyAll` (NightStats) | 1000ms |
| `applyStrength` (UltraStrong) | 1000ms |
| `tickSanity` gallery scan | 1000ms, counts cached |

`tickSanity` is gated **only on its zombie sweep**, not the whole function.

## Sandbox defaults that differ from the old plan doc

| Option | Plan (ENGAGEMENT) | Live 1.2.3 |
| --- | --- | --- |
| `GatheringIntervalNights` | 7 | **1** |
| `GatheringMax` | 12 | **40** |
| `NightSprinters` | off / hunt-only | **on**, day and night sprint |
| `StartWithSpareTalisman` | n/a | **on**; spawn house also hung |
| `UltraStrong` | n/a | **off**; 3–4 unarmored hits when on |
| `STRAIN_GAIN_MUL` | (uncapped climb) | **0.2** on all positive strain |

---

## Smoke for the next agent

New save, cheat optional, **full restart** after overlay. Turn on sandbox `TalismanDebug` for the per-minute census.

1. Dawn: loaded people go indoors and **sit**. Walking into one can wake it. No fall-loop, no flying, no standing statues in bedrooms.
2. Prefer ruined (smashed-window) houses as nests when those clusters exist.
3. Dusk: they leave nests. Cap of them path to the **ring** around the sealed house — spread around the perimeter, not stacked on one porch.
4. Sealed house, player inside, sprint: they **shamble and mill** in the yard at 2–5 tiles. Only bodies on a door/window freeze. They do not smash the glass.
5. Sprint at them from outside: they charge, then shamble in the ring. A player standing **next to** a loiterer gets swung at.
6. Sunrise from the window: yard drains a few at a time; they walk into neighbouring houses. Census `outdoor` falls, `indoor` rises; `leaving` stays around 6. No “They all stop at once” line.
7. They open garden gates and nest-house doors. They do **not** open the sealed talisman door.
8. Open exterior door: invitation. Close it; new ones stay out.
9. Whispers at door/window at night; Knox only at windows. No right-click sanity debug menu.
10. Sanity moodle at delusion; climb is slow. Sleeping through a whisper uses fade-in.
11. ~25% of houses have a gun + box; spawn house has a hung talisman, boards, and a 07:00 alarm.
12. UltraStrong **on**: unarmored dies in 3–4 landed hits. Off: ordinary zombie damage.
