# Graph Report - fromzoid  (2026-08-26)

## Corpus Check
- 64 files · ~779,727 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 451 nodes · 1524 edges · 18 communities detected
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 381 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cb115431`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 46 edges
2. `FromZoid.buildingId()` - 41 edges
3. `FromZoid.enforceTalisman()` - 40 edges
4. `FromZoid.sendZombieToNest()` - 30 edges
5. `processSunCycle()` - 29 edges
6. `keepOffSealedHouse()` - 28 edges
7. `FromZoid.isBuildingSealed()` - 27 edges
8. `FromZoid.nowMs()` - 26 edges
9. `FromZoid.zombieSquare()` - 23 edges
10. `tryWhispers()` - 21 edges

## Surprising Connections (you probably didn't know these)
- `mixWanted()` --calls--> `FromZoid.getState()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → _review_dump2/FromZoid_Core.lua
- `mixWanted()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → _review_dump2/FromZoid_Core.lua
- `mixWanted()` --calls--> `FromZoid.inTheWoods()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → _review_dump2/FromZoid_Sanity.lua
- `mixWanted()` --calls--> `FromZoid.sanityLevel()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → _review_dump2/FromZoid_Sanity.lua
- `tickSanityFx()` --calls--> `FromZoid.playerInVehicle()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_SanityFx.lua → _review_dump2/FromZoid_Core.lua

## Communities (26 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.11
Nodes (56): FromZoid.cachedPorchSquare(), sendIndoors(), FromZoid.applyStillPose(), FromZoid.buildingCenter(), FromZoid.buildingFromSquare(), FromZoid.buildingHasBasement(), FromZoid.buildingHasInvitation(), FromZoid.buildingHasOpenEntrance() (+48 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (50): nearestTarget(), sealedTargets(), tickGathering(), chance(), FromZoid.onDayZombieUpdate(), herdIndoors(), lureOutside(), nestDayCreate() (+42 more)

### Community 2 - "Community 2"
Cohesion: 0.09
Nodes (39): bumpTarget(), clickThrough(), delusionEvent(), delusionTrick(), doorBlocked(), drawVeil(), drawVeilScreen(), ensureVeil() (+31 more)

### Community 3 - "Community 3"
Cohesion: 0.15
Nodes (41): abortChase(), abortPath(), buildingFromObject(), clearPursuit(), clearThump(), distToNearestOpening(), ejectIfInside(), enforceTalisman() (+33 more)

### Community 4 - "Community 4"
Cohesion: 0.12
Nodes (36): doorFromContext(), FromZoidHangTalismanAction:isValid(), FromZoidHangTalismanAction:new(), FromZoidHangTalismanAction:perform(), FromZoidHangTalismanAction:start(), FromZoidHangTalismanAction:stop(), FromZoidHangTalismanAction:update(), FromZoidHangTalismanAction:waitToStart() (+28 more)

### Community 5 - "Community 5"
Cohesion: 0.19
Nodes (25): applyAll(), applyLore(), applySenses(), applyToughness(), applyWalkType(), captureLore(), FromZoid.markZombieHunting(), FromZoid.onCalmZombieUpdate() (+17 more)

### Community 6 - "Community 6"
Cohesion: 0.16
Nodes (24): allowed(), applyStrain(), FromZoid.debug(), FromZoid.handleDebugChat(), onFillWorld(), runDebug(), splitPrefix(), statusLine() (+16 more)

### Community 7 - "Community 7"
Cohesion: 0.18
Nodes (24): addClockToContainer(), armClock(), clearLockedSpawnHouse(), containerScore(), containerType(), dropClockOnSquare(), eachBuildingSquare(), eachContainerOnSquare() (+16 more)

### Community 8 - "Community 8"
Cohesion: 0.19
Nodes (14): tickSanity(), wakePlayer(), FromZoid.isDay(), FromZoid.wakePlayer(), FromZoid.addStrain(), FromZoid.deviceIsPlaying(), FromZoid.garbleName(), FromZoid.getStrain() (+6 more)

### Community 9 - "Community 9"
Cohesion: 0.31
Nodes (14): clipsFor(), fillMissingVoices(), genderPool(), loiteringAtSealed(), nearKind(), nearOpening(), pad2(), pickLeastHeard() (+6 more)

### Community 10 - "Community 10"
Cohesion: 0.45
Nodes (11): applyFx(), applySnap(), applyWanted(), mixWanted(), radioLine(), readFx(), tickClimate(), tickDarknessClient() (+3 more)

### Community 11 - "Community 11"
Cohesion: 0.33
Nodes (9): applyStrength(), bodyPart(), extraDamage(), FromZoid.applyUltraStrongHit(), FromZoid.onUltraStrongUpdate(), onPlayerDamage(), onZombieHit(), onZombieUpdate() (+1 more)

### Community 12 - "Community 12"
Cohesion: 0.42
Nodes (9): assignVoice(), cleanVisuals(), dressLikePerson(), nextVoice(), pickOutfit(), wipeBlood(), wipeBloodDirt(), wornCount() (+1 more)

### Community 13 - "Community 13"
Cohesion: 0.6
Nodes (8): endBlackout(), getElecShut(), powerShouldBeOn(), scheduleOrTick(), setElecShut(), setPower(), startBlackout(), worldHours()

### Community 14 - "Community 14"
Cohesion: 0.42
Nodes (8): tryBoardSpawnHouse(), addPlanks(), alreadyDone(), FromZoid.boardUpBuilding(), isPlayerBuilt(), processSquare(), smashWindow(), FromZoid.getSquareData()

### Community 15 - "Community 15"
Cohesion: 0.61
Nodes (7): addKit(), addLoadedMag(), armedData(), isGunContainer(), itemExists(), pickValid(), processSquare()

### Community 16 - "Community 16"
Cohesion: 0.8
Nodes (3): itemExists(), onCreate(), pickWeapon()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 5` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 14`, `Community 15`, `Community 16`?**
  _High betweenness centrality (0.261) - this node is a cross-community bridge._
- **Why does `FromZoid.text()` connect `Community 6` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 10`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Why does `tickSanityFx()` connect `Community 2` to `Community 8`, `Community 10`, `Community 5`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `mixWanted()` and `tickSanityFx()`) actually correct?**
  _`FromZoid.isEnabled()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `FromZoid.buildingId()` (e.g. with `loiteringAtSealed()` and `processSquare()`) actually correct?**
  _`FromZoid.buildingId()` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 30 inferred relationships involving `FromZoid.enforceTalisman()` (e.g. with `FromZoid.isClockNight()` and `FromZoid.targetIsExposedPlayer()`) actually correct?**
  _`FromZoid.enforceTalisman()` has 30 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `FromZoid.sendZombieToNest()` (e.g. with `sendIndoors()` and `FromZoid.onDayZombieUpdate()`) actually correct?**
  _`FromZoid.sendZombieToNest()` has 7 INFERRED edges - model-reasoned connections that need verification._