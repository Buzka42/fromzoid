# Graph Report - fromzoid  (2026-08-22)

## Corpus Check
- 13 files · ~5,641 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 90 nodes · 190 edges · 8 communities detected
- Extraction: 63% EXTRACTED · 37% INFERRED · 0% AMBIGUOUS · INFERRED: 71 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]

## God Nodes (most connected - your core abstractions)
1. `FromZoid.isEnabled()` - 19 edges
2. `FromZoid.isBuildingSealed()` - 11 edges
3. `FromZoid.isNight()` - 10 edges
4. `tryWhispers()` - 9 edges
5. `enforceTalisman()` - 9 edges
6. `FromZoid.buildingId()` - 9 edges
7. `sendIndoors()` - 8 edges
8. `processSunCycle()` - 8 edges
9. `FromZoid.getSandbox()` - 8 edges
10. `applyAll()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `FromZoidHangTalismanAction:perform()` --calls--> `FromZoid.hangTalismanOnSquare()`  [INFERRED]
  client/FromZoid_TalismanMenu.lua → shared/FromZoid_TalismanUtil.lua
- `onFillWorld()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  client/FromZoid_TalismanMenu.lua → shared/FromZoid_Core.lua
- `onFillWorld()` --calls--> `FromZoid.isBuildingSealed()`  [INFERRED]
  client/FromZoid_TalismanMenu.lua → shared/FromZoid_Core.lua
- `nearOpening()` --calls--> `FromZoid.zombieSquare()`  [INFERRED]
  client/FromZoid_Whispers.lua → shared/FromZoid_Core.lua
- `tryWhispers()` --calls--> `FromZoid.isEnabled()`  [INFERRED]
  client/FromZoid_Whispers.lua → shared/FromZoid_Core.lua

## Communities (9 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.2
Nodes (13): applyFx(), radioLine(), tickDarknessClient(), scheduleOrTick(), setPower(), worldHours(), applyAll(), applyLore() (+5 more)

### Community 1 - "Community 1"
Cohesion: 0.24
Nodes (13): FromZoid.buildingFromSquare(), FromZoid.buildingHasInvitation(), FromZoid.buildingId(), FromZoid.buildingIdFromDef(), FromZoid.getDawnDusk(), FromZoid.getTimeOfDayHours(), FromZoid.isDay(), FromZoid.isNight() (+5 more)

### Community 3 - "Community 3"
Cohesion: 0.29
Nodes (11): processSunCycle(), sendIndoors(), enforceTalisman(), nearestExteriorSquare(), nearestOpeningSquare(), FromZoid.findNearestUnsealedBuilding(), FromZoid.freeTileInBuilding(), FromZoid.isBuildingSealed() (+3 more)

### Community 4 - "Community 4"
Cohesion: 0.29
Nodes (9): FromZoidHangTalismanAction:perform(), FromZoidTakeTalismanAction:perform(), squareStillHasTalisman(), validateSeals(), FromZoid.getTalismanData(), FromZoid.hangTalismanOnSquare(), FromZoid.sealBuilding(), FromZoid.takeTalismanFromSquare() (+1 more)

### Community 5 - "Community 5"
Cohesion: 0.57
Nodes (7): chance(), lureOutside(), onHit(), onZombieUpdate(), outdoorSquareNear(), wakeZombie(), FromZoid.getSandbox()

### Community 6 - "Community 6"
Cohesion: 0.47
Nodes (5): nearOpening(), speak(), tryWhispers(), FromZoid.eachLoadedZombie(), FromZoid.squareHasOpening()

### Community 7 - "Community 7"
Cohesion: 0.53
Nodes (5): addPlanks(), alreadyDone(), isPlayerBuilt(), processSquare(), FromZoid.getSquareData()

## Knowledge Gaps
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FromZoid.isEnabled()` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`?**
  _High betweenness centrality (0.446) - this node is a cross-community bridge._
- **Why does `onFillWorld()` connect `Community 2` to `Community 0`, `Community 3`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._
- **Why does `FromZoid.isBuildingSealed()` connect `Community 3` to `Community 0`, `Community 1`, `Community 2`, `Community 4`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Are the 15 inferred relationships involving `FromZoid.isEnabled()` (e.g. with `tickDarknessClient()` and `onFillWorld()`) actually correct?**
  _`FromZoid.isEnabled()` has 15 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `FromZoid.isBuildingSealed()` (e.g. with `onFillWorld()` and `sendIndoors()`) actually correct?**
  _`FromZoid.isBuildingSealed()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `FromZoid.isNight()` (e.g. with `tryWhispers()` and `applyAll()`) actually correct?**
  _`FromZoid.isNight()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `tryWhispers()` (e.g. with `FromZoid.isEnabled()` and `FromZoid.isNight()`) actually correct?**
  _`tryWhispers()` has 6 INFERRED edges - model-reasoned connections that need verification._