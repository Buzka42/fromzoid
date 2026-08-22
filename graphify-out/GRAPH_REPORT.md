# Graph Report - fromzoid  (2026-08-22)

## Corpus Check
- 18 files · ~16,322 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 127 nodes · 279 edges · 11 communities detected
- Extraction: 66% EXTRACTED · 34% INFERRED · 0% AMBIGUOUS · INFERRED: 95 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `11ce2592`
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

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 23 edges
2. `FromZoid.isBuildingSealed()` - 14 edges
3. `tryWhispers()` - 12 edges
4. `processSunCycle()` - 11 edges
5. `sendIndoors()` - 10 edges
6. `enforceTalisman()` - 10 edges
7. `processSquare()` - 10 edges
8. `FromZoid.isNight()` - 10 edges
9. `FromZoid.buildingId()` - 10 edges
10. `FromZoid.getSandbox()` - 9 edges

## Surprising Connections (you probably didn't know these)
- `tickDarknessClient()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_DarknessFx.lua → Contents/mods/FromZoid/common/media/lua/shared/FromZoid_Core.lua
- `FromZoidHangTalismanAction:isValid()` --calls--> `FromZoid.findTalismanInInventory()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_TalismanMenu.lua → Contents/mods/FromZoid/common/media/lua/shared/FromZoid_TalismanUtil.lua
- `FromZoidTakeTalismanAction:perform()` --calls--> `FromZoid.takeTalismanFromSquare()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_TalismanMenu.lua → Contents/mods/FromZoid/common/media/lua/shared/FromZoid_TalismanUtil.lua
- `nearKind()` --calls--> `FromZoid.getWindowOnSquare()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_Whispers.lua → Contents/mods/FromZoid/common/media/lua/shared/FromZoid_Core.lua
- `nearKind()` --calls--> `FromZoid.getDoorOnSquare()`  [INFERRED]
  Contents/mods/FromZoid/common/media/lua/client/FromZoid_Whispers.lua → Contents/mods/FromZoid/common/media/lua/shared/FromZoid_Core.lua

## Communities (15 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.17
Nodes (21): sendIndoors(), FromZoid.buildingFromSquare(), FromZoid.buildingIdFromDef(), FromZoid.findBasementSquare(), FromZoid.findNearestUnsealedBuilding(), FromZoid.firstDoorInBuilding(), FromZoid.freeTileInBuilding(), FromZoid.getBuildingDef() (+13 more)

### Community 1 - "Community 1"
Cohesion: 0.21
Nodes (18): FromZoidHangTalismanAction:perform(), onFillWorld(), squareStillHasTalisman(), validateSeals(), FromZoid.buildingHasInvitation(), FromZoid.buildingId(), FromZoid.getTalismanData(), FromZoid.isBuildingSealed() (+10 more)

### Community 2 - "Community 2"
Cohesion: 0.13
Nodes (4): doorFromContext(), FromZoidHangTalismanAction:isValid(), FromZoidTakeTalismanAction:perform(), squareHasHungTalisman()

### Community 3 - "Community 3"
Cohesion: 0.3
Nodes (13): chance(), lureOutside(), onHit(), onZombieUpdate(), outdoorSquareNear(), processSunCycle(), wakeZombie(), FromZoid.getDawnDusk() (+5 more)

### Community 4 - "Community 4"
Cohesion: 0.33
Nodes (11): clipsFor(), genderPool(), nearKind(), nearOpening(), pad2(), speak(), tryWhispers(), voiceFits() (+3 more)

### Community 5 - "Community 5"
Cohesion: 0.29
Nodes (9): applyFx(), radioLine(), tickDarknessClient(), applyAll(), applyLore(), applyWalkType(), onZombieCreate(), FromZoid.eachLoadedZombie() (+1 more)

### Community 6 - "Community 6"
Cohesion: 0.33
Nodes (8): addPlanks(), alreadyDone(), isPlayerBuilt(), processSquare(), smashWindow(), FromZoid.clusterKey(), FromZoid.getClusterKind(), FromZoid.getSquareData()

### Community 7 - "Community 7"
Cohesion: 0.53
Nodes (5): clearThump(), enforceTalisman(), nearestExteriorSquare(), nearestOpeningSquare(), FromZoid.squareHasOpening()

### Community 8 - "Community 8"
Cohesion: 0.7
Nodes (4): assignVoice(), cleanVisuals(), dressLikePerson(), pickOutfit()

### Community 9 - "Community 9"
Cohesion: 0.83
Nodes (3): scheduleOrTick(), setPower(), worldHours()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 1` to `Community 0`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 9`, `Community 10`?**
  _High betweenness centrality (0.359) - this node is a cross-community bridge._
- **Why does `onFillWorld()` connect `Community 1` to `Community 2`?**
  _High betweenness centrality (0.174) - this node is a cross-community bridge._
- **Why does `tryWhispers()` connect `Community 4` to `Community 0`, `Community 1`, `Community 3`, `Community 5`?**
  _High betweenness centrality (0.104) - this node is a cross-community bridge._
- **Are the 19 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `tickDarknessClient()` and `onFillWorld()`) actually correct?**
  _`FromZoid.isEnabled()` has 19 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `FromZoid.isBuildingSealed()` (e.g. with `onFillWorld()` and `sendIndoors()`) actually correct?**
  _`FromZoid.isBuildingSealed()` has 8 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `tryWhispers()` (e.g. with `FromZoid.isEnabled()` and `FromZoid.isNight()`) actually correct?**
  _`tryWhispers()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `processSunCycle()` (e.g. with `FromZoid.isEnabled()` and `FromZoid.isNight()`) actually correct?**
  _`processSunCycle()` has 8 INFERRED edges - model-reasoned connections that need verification._