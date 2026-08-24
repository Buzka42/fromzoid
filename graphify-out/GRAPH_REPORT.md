# Graph Report - fromzoid  (2026-08-24)

## Corpus Check
- 65 files · ~454,313 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 415 nodes · 1375 edges · 15 communities detected
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 339 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ae157524`
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

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 45 edges
2. `FromZoid.buildingId()` - 38 edges
3. `processSunCycle()` - 28 edges
4. `FromZoid.sendZombieToNest()` - 27 edges
5. `FromZoid.enforceTalisman()` - 26 edges
6. `FromZoid.isBuildingSealed()` - 26 edges
7. `keepOffSealedHouse()` - 25 edges
8. `FromZoid.zombieSquare()` - 23 edges
9. `tryWhispers()` - 21 edges
10. `FromZoid.getState()` - 21 edges

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

## Communities (23 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.12
Nodes (53): FromZoid.buildingFromSquare(), FromZoid.buildingHasBasement(), FromZoid.buildingHasInvitation(), FromZoid.buildingHasOpenEntrance(), FromZoid.buildingId(), FromZoid.buildingIdFromDef(), FromZoid.clusterKey(), FromZoid.doorHangOffset() (+45 more)

### Community 1 - "Community 1"
Cohesion: 0.09
Nodes (39): bumpTarget(), clickThrough(), delusionEvent(), delusionTrick(), doorBlocked(), drawVeil(), drawVeilScreen(), ensureVeil() (+31 more)

### Community 2 - "Community 2"
Cohesion: 0.13
Nodes (44): nearestTarget(), sealedTargets(), tickGathering(), chance(), FromZoid.cachedPorchSquare(), FromZoid.onDayZombieUpdate(), herdIndoors(), lureOutside() (+36 more)

### Community 3 - "Community 3"
Cohesion: 0.16
Nodes (37): abortChase(), abortPath(), buildingFromObject(), clearPursuit(), clearThump(), distToNearestOpening(), ejectIfInside(), enforceTalisman() (+29 more)

### Community 4 - "Community 4"
Cohesion: 0.13
Nodes (35): doorFromContext(), FromZoidHangTalismanAction:isValid(), FromZoidHangTalismanAction:new(), FromZoidHangTalismanAction:perform(), FromZoidHangTalismanAction:start(), FromZoidHangTalismanAction:stop(), FromZoidHangTalismanAction:update(), FromZoidHangTalismanAction:waitToStart() (+27 more)

### Community 5 - "Community 5"
Cohesion: 0.13
Nodes (28): clipsFor(), fillMissingVoices(), genderPool(), loiteringAtSealed(), nearKind(), nearOpening(), pad2(), pickLeastHeard() (+20 more)

### Community 6 - "Community 6"
Cohesion: 0.15
Nodes (21): itemExists(), onCreate(), pickWeapon(), applyAll(), applyLore(), applySenses(), applyToughness(), applyWalkType() (+13 more)

### Community 7 - "Community 7"
Cohesion: 0.16
Nodes (24): allowed(), applyStrain(), FromZoid.debug(), FromZoid.handleDebugChat(), onFillWorld(), runDebug(), splitPrefix(), statusLine() (+16 more)

### Community 8 - "Community 8"
Cohesion: 0.2
Nodes (23): addClockToContainer(), armClock(), clearLockedSpawnHouse(), containerScore(), containerType(), dropClockOnSquare(), eachBuildingSquare(), eachContainerOnSquare() (+15 more)

### Community 9 - "Community 9"
Cohesion: 0.52
Nodes (10): applyFx(), applySnap(), applyWanted(), mixWanted(), radioLine(), readFx(), tickClimate(), tickDarknessClient() (+2 more)

### Community 10 - "Community 10"
Cohesion: 0.42
Nodes (9): assignVoice(), cleanVisuals(), dressLikePerson(), nextVoice(), pickOutfit(), wipeBlood(), wipeBloodDirt(), wornCount() (+1 more)

### Community 11 - "Community 11"
Cohesion: 0.6
Nodes (8): endBlackout(), getElecShut(), powerShouldBeOn(), scheduleOrTick(), setElecShut(), setPower(), startBlackout(), worldHours()

### Community 12 - "Community 12"
Cohesion: 0.61
Nodes (7): addKit(), addLoadedMag(), armedData(), isGunContainer(), itemExists(), pickValid(), processSquare()

### Community 13 - "Community 13"
Cohesion: 0.67
Nodes (5): addPlanks(), alreadyDone(), isPlayerBuilt(), processSquare(), smashWindow()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 6` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`?**
  _High betweenness centrality (0.263) - this node is a cross-community bridge._
- **Why does `FromZoid.text()` connect `Community 7` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 9`?**
  _High betweenness centrality (0.150) - this node is a cross-community bridge._
- **Why does `tickSanityFx()` connect `Community 1` to `Community 0`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `mixWanted()` and `tickSanityFx()`) actually correct?**
  _`FromZoid.isEnabled()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 18 inferred relationships involving `FromZoid.buildingId()` (e.g. with `loiteringAtSealed()` and `processSquare()`) actually correct?**
  _`FromZoid.buildingId()` has 18 INFERRED edges - model-reasoned connections that need verification._
- **Are the 21 inferred relationships involving `processSunCycle()` (e.g. with `FromZoid.isClockNight()` and `FromZoid.clearZombieHunt()`) actually correct?**
  _`processSunCycle()` has 21 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `FromZoid.sendZombieToNest()` (e.g. with `sendIndoors()` and `FromZoid.onDayZombieUpdate()`) actually correct?**
  _`FromZoid.sendZombieToNest()` has 6 INFERRED edges - model-reasoned connections that need verification._