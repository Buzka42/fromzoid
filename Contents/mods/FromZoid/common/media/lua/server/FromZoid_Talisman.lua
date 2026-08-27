if isClient() then
	return
end

local function squareStillHasTalisman(x, y, z)
	local sq = getCell():getGridSquare(x, y, z)
	if not sq then
		return true
	end
	local worldObjects = sq:getWorldObjects()
	if not worldObjects then
		-- Fail safe like the missing-square case above. A square can report
		-- no world objects mid chunk load, and answering "gone" there
		-- unseals a house the player still has a talisman on.
		return true
	end
	for i = 0, worldObjects:size() - 1 do
		local wo = worldObjects:get(i)
		local item = wo.getItem and wo:getItem() or nil
		if item then
			local md = item.getModData and item:getModData() or nil
			local full = item.getFullType and item:getFullType() or ""
			if (md and md.fromzoid_talisman) or full == FromZoid.ITEM_TALISMAN then
				return true
			end
		end
	end
	return false
end

local function wiltWorldTalisman(x, y, z)
	local sq = getCell():getGridSquare(x, y, z)
	if not sq then
		return
	end
	local worldObjects = sq:getWorldObjects()
	if not worldObjects then
		return
	end
	for i = 0, worldObjects:size() - 1 do
		local wo = worldObjects:get(i)
		local item = wo.getItem and wo:getItem() or nil
		if item and item.getModData then
			local md = item:getModData()
			local full = item.getFullType and item:getFullType() or ""
			if md.fromzoid_talisman or full == FromZoid.ITEM_TALISMAN then
				md.fromzoid_wilted = true
				if item.transmitModData then
					item:transmitModData()
				end
			end
		end
	end
end

local function validateSeals()
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	local data = FromZoid.getTalismanData()
	local stale = {}
	local worn = FromZoid.isEnabled("EnableWornCharms")
	local maxNights = tonumber(FromZoid.getSandbox("TalismanNights", 7)) or 7
	local nowN = (getGameTime() and getGameTime():getNightsSurvived()) or 0
	for id, entry in pairs(data) do
		if type(entry) == "table" and entry.sealed and entry.x then
			if not squareStillHasTalisman(entry.x, entry.y, entry.z) then
				table.insert(stale, id)
			elseif worn then
				if entry.hungNight == nil then
					entry.hungNight = nowN
				elseif (nowN - entry.hungNight) >= maxNights then
					wiltWorldTalisman(entry.x, entry.y, entry.z)
					table.insert(stale, id)
				end
			end
		end
	end
	for i = 1, #stale do
		FromZoid.unsealBuildingId(stale[i])
	end
end

local function buildingFromObject(obj)
	if not obj then
		return nil
	end
	local sq = obj.getSquare and obj:getSquare() or nil
	if sq and sq:getBuilding() then
		return sq:getBuilding()
	end
	if obj.getOppositeSquare then
		local opp = obj:getOppositeSquare()
		if opp and opp:getBuilding() then
			return opp:getBuilding()
		end
	end
	return nil
end

local function thumpIsSealed(zombie)
	local thump = nil
	if zombie.getThumpTarget then
		thump = zombie:getThumpTarget()
	end
	if not thump then
		return false
	end
	local building = buildingFromObject(thump)
	if not building then
		return false
	end
	return FromZoid.isBuildingSealed(building) and not FromZoid.buildingHasInvitation(building)
end

local function clearPursuit(zombie)
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(false)
		end)
	end
end

local function squareIsSealedInterior(square, building)
	if not square or not building then
		return false
	end
	if not square.getRoom or not square:getRoom() then
		return false
	end
	local b = square:getBuilding()
	if not b then
		return false
	end
	return FromZoid.buildingId(b) == FromZoid.buildingId(building)
end

local function ejectIfInside(zombie, building)
	if FromZoid.buildingHasInvitation(building) then
		return false
	end
	local sq = FromZoid.zombieSquare(zombie)
	if not squareIsSealedInterior(sq, building) then
		return false
	end
	local opening = FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq)
	local porch = FromZoid.openingPorchSquare(opening)
	if not porch then
		porch = FromZoid.nearestPorchSquare(building, sq:getX(), sq:getY())
	end
	if not porch then
		local cell = getCell()
		local dirs = { {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {2, 0}, {-2, 0}, {0, 2}, {0, -2}, {3, 0}, {-3, 0}, {0, 3}, {0, -3} }
		for i = 1, #dirs do
			local n = cell:getGridSquare(sq:getX() + dirs[i][1], sq:getY() + dirs[i][2], sq:getZ())
			if n and not n:getBuilding() and not FromZoid.getWindowOnSquare(n) and not FromZoid.getDoorOnSquare(n) and n.isFree and n:isFree(false) then
				porch = n
				break
			end
		end
	end
	if porch then
		-- Do not pathFindBehavior2:cancel here: canceling a live path
		-- launches them when the player gets close enough to update them.
		-- Do not path through walls either: that is the other flyer.
		-- Unseen: teleport to the porch. Watched: leave them until later.
		if not FromZoid.allowVisibleTeleport(zombie) then
			return false
		end
		FromZoid.teleportZombieToSquare(zombie, porch)
		return true
	end
	return false
end

local function stopThump(zombie)
	if zombie.setThumpFlag then
		pcall(function()
			zombie:setThumpFlag(0)
		end)
	end
	if zombie.setThumpTarget then
		pcall(function()
			zombie:setThumpTarget(nil)
		end)
	end
end

local function shooFromSealed(zombie, building)
	stopThump(zombie)
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
	if building then
		ejectIfInside(zombie, building)
	end
	if FromZoid.sendZombieToNest then
		if FromZoid.sendZombieToNest(zombie, false) then
			return
		end
	end
	local cx, cy = FromZoid.buildingCenter(building)
	FromZoid.walkAwayFromHouse(zombie, cx, cy)
end

-- Graded response. Only zombies actually on the glass get frozen; the crowd
-- behind them loiters in the yard. Freezing everyone inside the old AABB+2
-- turned the whole siege into statues, and the standoff tile sat inside that
-- band, so arrivals froze on contact or fought the boundary.
local function keepOffSealedHouse(zombie, building, forceHold)
	stopThump(zombie)
	clearPursuit(zombie)
	if building then
		ejectIfInside(zombie, building)
	end
	FromZoid.stepOffOpening(zombie)
	if FromZoid.zombieTouchingBuilding(zombie, building) then
		FromZoid.holdAtGlass(zombie)
		return
	end
	if building and FromZoid.zombieInRingBand(zombie, building) then
		FromZoid.loiterNearHouse(zombie, building)
		return
	end
	if forceHold then
		FromZoid.holdAtGlass(zombie)
		return
	end
	if zombie:getModData().fromzoidHold then
		FromZoid.releaseHold(zombie)
	end
end

-- Daylight dispersal, for a zombie that is outside the field or holding a
-- leave pass. Never called on anyone still inside the field.
local function dayDisperse(zombie, sealed, sliced)
	if FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
		return
	end
	local md = zombie:getModData()
	local cx, cy = nil, nil
	if sealed then
		cx, cy = FromZoid.buildingCenter(sealed)
	end
	-- A route that is getting them nowhere: tear it down and pick another.
	if FromZoid.zombieStalled(zombie, "fromzoidDayMove", 6000) then
		if zombie.setPath2 then
			pcall(function()
				zombie:setPath2(nil)
			end)
		end
		md.fromzoidWalkTo = nil
		md.fromzoidWalkAt = nil
		md.fromzoidNestAt = nil
		FromZoid.walkAwayFromHouse(zombie, cx, cy)
		return
	end
	-- Get clear of the house before nesting. Nests are picked by proximity,
	-- so one chosen on the far side sends them back past the windows.
	if sealed and (FromZoid.distToBuildingEdge(zombie, sealed) or 99) <= 10 then
		if FromZoid.walkAwayFromHouse(zombie, cx, cy) then
			return
		end
		-- Nowhere to walk to: a fenced yard, a dense block, or every
		-- candidate tile occupied. Returning here left them standing on the
		-- porch doing nothing, so fall through and let them nest from where
		-- they are instead of dead-ending.
	end
	-- Nest picking scans buildings and room tiles BEFORE it reaches its own
	-- cooldown, so it is far too expensive to run every tick on every
	-- zombie. Keep it on the slice; the walk-away below is cheap because
	-- its commitment check short-circuits first.
	local nested = false
	if sliced and FromZoid.sendZombieToNest then
		nested = FromZoid.sendZombieToNest(zombie, FromZoid.allowNestTeleport(zombie))
	end
	if not nested then
		FromZoid.walkAwayFromHouse(zombie, cx, cy)
	end
end

-- The talisman works the SAME day and night. There is no separate daytime
-- path any more: the field (hold at the glass, loiter in the yard) is the
-- only thing that reliably stops them, because it does not have to win a
-- race against vanilla re-acquiring the player through a window. Every
-- daytime substitute -- clear the target, walk them off, send them to a nest
-- -- lost that race, which is why they charged at 07:00.
--
-- Daylight adds exactly one thing on top: a short, staggered leave pass
-- handed out by herdIndoors, letting a few at a time out of the field to go
-- and hide. Anyone without a live pass stays in the field and cannot charge.
function FromZoid.enforceTalisman(zombie, ctx, sliced)
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	local day = not FromZoid.isClockNight()

	local function standDown()
		if md.fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		FromZoid.clearLoiter(zombie)
	end
	local function leaveSiege()
		standDown()
		FromZoid.clearEscape(zombie)
	end
	-- Someone exposed within arm's reach: stand the field down completely and
	-- let vanilla fight. Holding them useless, or stripping their target every
	-- tick, is why they took so long to swing at a player stood beside them.
	-- The field stands down for a zombie that has acquired an exposed player,
	-- or has one within reach. Keeping it held or stripping its target is
	-- what stopped them ever connecting.
	if FromZoid.targetIsExposedPlayer(zombie) or FromZoid.exposedPlayerNear(zombie, 3) then
		FromZoid.clearWhisperWalk(zombie)
		leaveSiege()
		return
	end

	if thumpIsSealed(zombie) then
		local thump = zombie.getThumpTarget and zombie:getThumpTarget() or nil
		keepOffSealedHouse(zombie, buildingFromObject(thump), true)
		return
	end

	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.isBuildingSealed(building) then
		if not FromZoid.buildingHasInvitation(building) then
			if FromZoid.isWhisperWalker(zombie) then
				ejectIfInside(zombie, building)
			else
				keepOffSealedHouse(zombie, building, true)
				return
			end
		elseif day then
			-- Invited overnight, but daybreak still clears the house.
			shooFromSealed(zombie, building)
			return
		end
	end

	local sealed = FromZoid.nearestSealedBuilding(zombie, 40)
	if not sealed then
		leaveSiege()
		if day and sliced then
			dayDisperse(zombie, nil, sliced)
		end
		return
	end
	if FromZoid.buildingHasInvitation(sealed) then
		-- Door or window left open: they are allowed in.
		leaveSiege()
		if sliced and zombie.setCanOpenDoors then
			pcall(function()
				zombie:setCanOpenDoors(true)
			end)
		end
		if day and sliced then
			dayDisperse(zombie, nil, sliced)
		end
		return
	end

	-- Already hidden indoors nearby: leave them alone.
	if FromZoid.squareIsIndoorHide(sq) then
		leaveSiege()
		return
	end

	local function guideWhisperWalker()
		if md.fromzoidWhisperUntil and now >= md.fromzoidWhisperUntil and not (md.fromzoidWhisperBackUntil and now < md.fromzoidWhisperBackUntil) then
			if FromZoid.isEnabled("TalismanDebug") then
				local dx = (md.fromzoidWhisperX or 0) - zombie:getX()
				local dy = (md.fromzoidWhisperY or 0) - zombie:getY()
				print(string.format("[FromZoid] whisper: gave up %.1f tiles out", math.sqrt(dx * dx + dy * dy)))
			end
			FromZoid.clearWhisperWalk(zombie)
		end
		if not FromZoid.isWhisperWalker(zombie) then
			return false
		end
		if md.fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		if zombie.setTarget then
			zombie:setTarget(nil)
		end
		if zombie.setCanOpenDoors then
			pcall(function()
				zombie:setCanOpenDoors(false)
			end)
		end
		ejectIfInside(zombie, sealed)
		if md.fromzoidWhisperUntil and now < md.fromzoidWhisperUntil then
			FromZoid.clearLoiter(zombie)
			local cell = getCell()
			local dest = cell and cell:getGridSquare(md.fromzoidWhisperX, md.fromzoidWhisperY, md.fromzoidWhisperZ or 0)
			-- Do not repath on slice. Issuing pathToLocation every 10 ticks
			-- restarts A* before they take a step, which is why Annie/Zelda
			-- were assigned walks and never left the ring.
			if dest and not FromZoid.whispererArrived(zombie) then
				if not md.fromzoidWhisperPathed then
					md.fromzoidWhisperPathed = true
					FromZoid.pathZombieToSquare(zombie, dest)
				elseif FromZoid.zombieStalled(zombie, "fromzoidWhisperMove", 1500) then
					FromZoid.pathZombieToSquare(zombie, dest)
				end
			end
			return true
		end
		if md.fromzoidWhisperBackUntil and now < md.fromzoidWhisperBackUntil then
			FromZoid.loiterNearHouse(zombie, sealed)
			return true
		end
		return false
	end
	if guideWhisperWalker() then
		return
	end

	if day and md.fromzoidLeaveUntil and now < md.fromzoidLeaveUntil then
		standDown()
		-- Out of the field but still beside the house: vanilla will re-acquire
		-- the player through the glass. Clear the target every tick, but only
		-- rebuild the route when they have stopped making ground.
		if FromZoid.targetIsProtectedPlayer(zombie) then
			zombie:setTarget(nil)
			FromZoid.clearZombieHunt(zombie)
		elseif FromZoid.targetIsExposedPlayer(zombie) then
			return
		elseif zombie.getTarget and zombie:getTarget() then
			zombie:setTarget(nil)
		end
		local edge = FromZoid.distToBuildingEdge(zombie, sealed) or 99
		if FromZoid.escapeStalled(zombie, edge, 3000) then
			if zombie.setPath2 then
				pcall(function()
					zombie:setPath2(nil)
				end)
			end
			local cx, cy = FromZoid.buildingCenter(sealed)
			md.fromzoidWalkTo = nil
			md.fromzoidWalkAt = nil
			md.fromzoidNestAt = nil
			FromZoid.walkAwayFromHouse(zombie, cx, cy)
			return
		end
		dayDisperse(zombie, sealed, sliced)
		return
	end

	-- On the glass: frozen, day or night. Leave passes let these out.
	if FromZoid.zombieTouchingBuilding(zombie, sealed) then
		keepOffSealedHouse(zombie, sealed, true)
		return
	end
	if FromZoid.zombieInRingBand(zombie, sealed) then
		-- Loitering is NIGHT behaviour. Parking the yard crowd in daylight
		-- turned the talisman house into a permanent car park: anything that
		-- wandered into the band was held there, and the leave queue drained
		-- it slower than it refilled. Measured as loiter dipping to 27 and
		-- climbing back to 49 by mid-morning. By day the band repels outward
		-- instead, with the same anti-charge protection as a pass holder.
		if not day then
			keepOffSealedHouse(zombie, sealed, false)
			return
		end
		standDown()
		stopThump(zombie)
		-- Clearing the target every tick is cheap and stops vanilla making
		-- fresh pursuit decisions. Do NOT tear the path down just because a
		-- target existed: rebuilding it every tick the player is visible
		-- restarts A* before they can take a step, and they stick in place.
		-- Only break off a chase aimed at someone sheltering inside. A player
		-- out in the open stays a legitimate target, or they can never be
		-- chased anywhere near their own house.
		if FromZoid.targetIsProtectedPlayer(zombie) then
			zombie:setTarget(nil)
			FromZoid.clearZombieHunt(zombie)
		elseif FromZoid.targetIsExposedPlayer(zombie) then
			return
		elseif zombie.getTarget and zombie:getTarget() then
			zombie:setTarget(nil)
		end
		-- Intervene only when they are genuinely not getting away.
		local edge = FromZoid.distToBuildingEdge(zombie, sealed) or 99
		if FromZoid.escapeStalled(zombie, edge, 3000) then
			if zombie.setPath2 then
				pcall(function()
					zombie:setPath2(nil)
				end)
			end
			local cx, cy = FromZoid.buildingCenter(sealed)
			md.fromzoidWalkTo = nil
			md.fromzoidWalkAt = nil
			md.fromzoidNestAt = nil
			FromZoid.walkAwayFromHouse(zombie, cx, cy)
			return
		end
		dayDisperse(zombie, sealed, sliced)
		return
	end
	leaveSiege()
	if day and sliced then
		dayDisperse(zombie, sealed, sliced)
	end
end

Events.EveryTenMinutes.Add(validateSeals)
