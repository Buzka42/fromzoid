# Graph Report - fromzoid  (2026-08-22)

## Corpus Check
- 25 files · ~25,688 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 237 nodes · 674 edges · 12 communities detected
- Extraction: 65% EXTRACTED · 35% INFERRED · 0% AMBIGUOUS · INFERRED: 237 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3fc2ba5c`
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

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 41 edges
2. `FromZoid.buildingId()` - 29 edges
3. `FromZoid.isBuildingSealed()` - 24 edges
4. `processSunCycle()` - 19 edges
5. `FromZoid.getSandbox()` - 19 edges
6. `FromZoid.getState()` - 19 edges
7. `keepOffSealedHouse()` - 17 edges
8. `tryWhispers()` - 16 edges
9. `enforceTalisman()` - 16 edges
10. `tickSanity()` - 15 edges

## Surprising Connections (you probably didn't know these)
- `mixWanted()` --calls--> `FromZoid.getState()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → shared/FromZoid_Core.lua
- `mixWanted()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → shared/FromZoid_Core.lua
- `tickDarknessClient()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → shared/FromZoid_Core.lua
- `tickDarknessClient()` --calls--> `FromZoid.getState()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → shared/FromZoid_Core.lua
- `tickSanityFx()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_SanityFx.lua → shared/FromZoid_Core.lua

## Communities (16 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.14
Nodes (35): clearLockedSpawnHouse(), lockSpawnBuilding(), markAndClearSpawnHouse(), tryHangOnPlayerHouse(), FromZoid.buildingFromSquare(), FromZoid.buildingHasBasement(), FromZoid.buildingHasInvitation(), FromZoid.buildingId() (+27 more)

### Community 1 - "Community 1"
Cohesion: 0.09
Nodes (21): doorFromContext(), FromZoidHangTalismanAction:isValid(), FromZoidHangTalismanAction:perform(), FromZoidRefreshTalismanAction:isValid(), FromZoidRefreshTalismanAction:perform(), FromZoidTakeTalismanAction:perform(), onFillWorld(), squareHasHungTalisman() (+13 more)

### Community 2 - "Community 2"
Cohesion: 0.17
Nodes (30): abortChase(), abortPath(), buildingFromObject(), clearPursuit(), clearThump(), distToNearestOpening(), ejectIfInside(), enforceTalisman() (+22 more)

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (23): tickGathering(), itemExists(), onCreate(), pickWeapon(), chance(), FromZoid.cachedPorchSquare(), FromZoid.onDayZombieUpdate(), lureOutside() (+15 more)

### Community 4 - "Community 4"
Cohesion: 0.16
Nodes (21): clipsFor(), genderPool(), loiteringAtSealed(), nearKind(), nearOpening(), pad2(), speak(), tryWhispers() (+13 more)

### Community 5 - "Community 5"
Cohesion: 0.17
Nodes (21): applyAll(), applyLore(), applyWalkType(), FromZoid.markZombieHunting(), FromZoid.onCalmZombieUpdate(), huntUntil(), onHit(), onSwing() (+13 more)

### Community 6 - "Community 6"
Cohesion: 0.56
Nodes (8): applyFx(), applySnap(), applyWanted(), mixWanted(), radioLine(), readFx(), tickDarknessClient(), weatherFx()

### Community 7 - "Community 7"
Cohesion: 0.53
Nodes (8): endBlackout(), getElecShut(), powerShouldBeOn(), scheduleOrTick(), setElecShut(), setPower(), startBlackout(), worldHours()

### Community 8 - "Community 8"
Cohesion: 0.42
Nodes (8): assignVoice(), cleanVisuals(), dressLikePerson(), pickOutfit(), wipeBlood(), wipeBloodDirt(), wornCount(), wornItem()

### Community 9 - "Community 9"
Cohesion: 0.61
Nodes (8): delusionEvent(), findDevice(), namedLine(), playQuiet(), psychosisEvent(), sayLine(), tickSanityFx(), turnOnDevice()

### Community 10 - "Community 10"
Cohesion: 0.54
Nodes (7): addKit(), addLoadedMag(), armedData(), isGunContainer(), itemExists(), pickValid(), processSquare()

### Community 11 - "Community 11"
Cohesion: 0.48
Nodes (6): addPlanks(), alreadyDone(), isPlayerBuilt(), processSquare(), smashWindow(), FromZoid.getSquareData()

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 5` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 6`, `Community 7`, `Community 9`, `Community 10`, `Community 11`?**
  _High betweenness centrality (0.330) - this node is a cross-community bridge._
- **Why does `onFillWorld()` connect `Community 1` to `Community 0`, `Community 5`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Why does `FromZoid.buildingId()` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 10`, `Community 11`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Are the 34 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `mixWanted()` and `tickDarknessClient()`) actually correct?**
  _`FromZoid.isEnabled()` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 17 inferred relationships involving `FromZoid.buildingId()` (e.g. with `squareTalismanWilted()` and `loiteringAtSealed()`) actually correct?**
  _`FromZoid.buildingId()` has 17 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `FromZoid.isBuildingSealed()` (e.g. with `onFillWorld()` and `loiteringAtSealed()`) actually correct?**
  _`FromZoid.isBuildingSealed()` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 13 inferred relationships involving `processSunCycle()` (e.g. with `FromZoid.isEnabled()` and `FromZoid.isNight()`) actually correct?**
  _`processSunCycle()` has 13 INFERRED edges - model-reasoned connections that need verification._