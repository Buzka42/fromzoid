# Graph Report - fromzoid  (2026-08-26)

## Corpus Check
- 64 files · ~780,655 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 490 nodes · 1657 edges · 16 communities detected
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 415 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `80a4938e`
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

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 47 edges
2. `FromZoid.buildingId()` - 43 edges
3. `FromZoid.enforceTalisman()` - 42 edges
4. `FromZoid.sendZombieToNest()` - 30 edges
5. `processSunCycle()` - 29 edges
6. `FromZoid.nowMs()` - 29 edges
7. `keepOffSealedHouse()` - 28 edges
8. `FromZoid.isBuildingSealed()` - 27 edges
9. `tryWhispers()` - 27 edges
10. `FromZoid.getState()` - 26 edges

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

## Communities (24 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (80): squareTalismanWilted(), clearLockedSpawnHouse(), lockSpawnBuilding(), markAndClearSpawnHouse(), tryHangOnPlayerHouse(), csvAdd(), csvHas(), FromZoid.buildingFromSquare() (+72 more)

### Community 1 - "Community 1"
Cohesion: 0.11
Nodes (54): nearestTarget(), sealedTargets(), tickGathering(), chance(), FromZoid.cachedPorchSquare(), FromZoid.onDayZombieUpdate(), herdIndoors(), lureOutside() (+46 more)

### Community 2 - "Community 2"
Cohesion: 0.09
Nodes (41): bumpTarget(), clickThrough(), delusionEvent(), delusionTrick(), deviceIsOn(), doorBlocked(), drawVeil(), drawVeilScreen() (+33 more)

### Community 3 - "Community 3"
Cohesion: 0.13
Nodes (44): abortChase(), abortPath(), buildingFromObject(), clearPursuit(), clearThump(), distToNearestOpening(), ejectIfInside(), enforceTalisman() (+36 more)

### Community 4 - "Community 4"
Cohesion: 0.13
Nodes (33): doorFromContext(), FromZoidHangTalismanAction:isValid(), FromZoidHangTalismanAction:new(), FromZoidHangTalismanAction:perform(), FromZoidHangTalismanAction:start(), FromZoidHangTalismanAction:stop(), FromZoidHangTalismanAction:update(), FromZoidHangTalismanAction:waitToStart() (+25 more)

### Community 5 - "Community 5"
Cohesion: 0.12
Nodes (29): itemExists(), onCreate(), pickWeapon(), applyAll(), applyLore(), applySenses(), applyToughness(), applyWalkType() (+21 more)

### Community 6 - "Community 6"
Cohesion: 0.15
Nodes (32): atSealedHouse(), clipsFor(), fillMissingVoices(), findActiveWalker(), findAnyWalker(), genderPool(), loiteringAtSealed(), nearDest() (+24 more)

### Community 7 - "Community 7"
Cohesion: 0.16
Nodes (24): allowed(), applyStrain(), FromZoid.debug(), FromZoid.handleDebugChat(), onFillWorld(), runDebug(), splitPrefix(), statusLine() (+16 more)

### Community 8 - "Community 8"
Cohesion: 0.18
Nodes (24): addClockToContainer(), armClock(), clearLockedSpawnHouses(), containerScore(), containerType(), dropClockOnSquare(), eachBuildingSquare(), eachContainerOnSquare() (+16 more)

### Community 9 - "Community 9"
Cohesion: 0.22
Nodes (14): tickSanity(), wakePlayer(), FromZoid.addStrain(), FromZoid.deviceIsPlaying(), FromZoid.garbleName(), FromZoid.getStrain(), FromZoid.inTheWoods(), FromZoid.isGatheringNight() (+6 more)

### Community 10 - "Community 10"
Cohesion: 0.52
Nodes (10): applyFx(), applySnap(), applyWanted(), mixWanted(), radioLine(), readFx(), tickClimate(), tickDarknessClient() (+2 more)

### Community 11 - "Community 11"
Cohesion: 0.42
Nodes (9): assignVoice(), cleanVisuals(), dressLikePerson(), nextVoice(), pickOutfit(), wipeBlood(), wipeBloodDirt(), wornCount() (+1 more)

### Community 12 - "Community 12"
Cohesion: 0.6
Nodes (8): endBlackout(), getElecShut(), powerShouldBeOn(), scheduleOrTick(), setElecShut(), setPower(), startBlackout(), worldHours()

### Community 13 - "Community 13"
Cohesion: 0.44
Nodes (8): tryBoardSpawnHouse(), addPlanks(), alreadyDone(), clearPlanks(), FromZoid.boardUpBuilding(), isPlayerBuilt(), processSquare(), smashWindow()

### Community 14 - "Community 14"
Cohesion: 0.61
Nodes (7): addKit(), addLoadedMag(), armedData(), isGunContainer(), itemExists(), pickValid(), processSquare()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 5` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 6`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 14`?**
  _High betweenness centrality (0.240) - this node is a cross-community bridge._
- **Why does `FromZoid.text()` connect `Community 7` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 10`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **Why does `tickSanityFx()` connect `Community 2` to `Community 0`, `Community 9`, `Community 5`?**
  _High betweenness centrality (0.120) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `mixWanted()` and `tickSanityFx()`) actually correct?**
  _`FromZoid.isEnabled()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `FromZoid.buildingId()` (e.g. with `processSquare()` and `tickSanity()`) actually correct?**
  _`FromZoid.buildingId()` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 32 inferred relationships involving `FromZoid.enforceTalisman()` (e.g. with `FromZoid.isClockNight()` and `FromZoid.targetIsExposedPlayer()`) actually correct?**
  _`FromZoid.enforceTalisman()` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `FromZoid.sendZombieToNest()` (e.g. with `sendIndoors()` and `FromZoid.onDayZombieUpdate()`) actually correct?**
  _`FromZoid.sendZombieToNest()` has 7 INFERRED edges - model-reasoned connections that need verification._