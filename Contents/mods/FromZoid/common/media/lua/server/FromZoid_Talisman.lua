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
		return false
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
	FromZoid.walkAwayFromHouse(zombie)
end

local function keepOffSealedHouse(zombie, building, forceHold)
	stopThump(zombie)
	clearPursuit(zombie)
	if building then
		ejectIfInside(zombie, building)
	end
	FromZoid.stepOffOpening(zombie)
	if forceHold or FromZoid.zombieNearOpening(zombie) or FromZoid.zombieAgainstBuilding(zombie, building) then
		FromZoid.holdAtGlass(zombie)
	elseif zombie:getModData().fromzoidHold then
		FromZoid.releaseHold(zombie)
	end
end

function FromZoid.enforceTalisman(zombie, ctx, sliced)
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	ctx = ctx or FromZoid.refreshTickContext()
	local night = FromZoid.isClockNight()
	if thumpIsSealed(zombie) then
		local thump = zombie.getThumpTarget and zombie:getThumpTarget() or nil
		local b = buildingFromObject(thump)
		if night then
			keepOffSealedHouse(zombie, b, true)
		else
			shooFromSealed(zombie, b)
		end
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.isBuildingSealed(building) and not FromZoid.buildingHasInvitation(building) then
		if night then
			keepOffSealedHouse(zombie, building, true)
		else
			shooFromSealed(zombie, building)
		end
		return
	end
	if not night then
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		FromZoid.clearZombieHunt(zombie)
		if zombie.setTarget then
			zombie:setTarget(nil)
		end
		stopThump(zombie)
		local infos = ctx.infos
		local d2 = 99999
		local sealedNear = nil
		if infos then
			for i = 1, #infos do
				local info = infos[i]
				local n = FromZoid.dist2ToPlayer(zombie, info.player)
				if n < d2 then
					d2 = n
				end
				if info.sealed and not info.invited and n <= 900 then
					sealedNear = info.building
				end
			end
		end
		local opening = sq and (FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq))
		if opening then
			local ob = buildingFromObject(opening)
			if ob and FromZoid.isBuildingSealed(ob) and not FromZoid.buildingHasInvitation(ob) then
				sealedNear = ob
			end
		end
		if sealedNear or (ctx.watchBuilding and FromZoid.zombieAgainstBuilding(zombie, ctx.watchBuilding)) then
			local nested = false
			if FromZoid.sendZombieToNest then
				nested = FromZoid.sendZombieToNest(zombie, FromZoid.allowNestTeleport(zombie))
			end
			if not nested and not FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
				FromZoid.walkAwayFromHouse(zombie)
			end
		end
		return
	end
	if not ctx.anySealedUninvited then
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		return
	end
	local sealedBuilding = ctx.watchBuilding
	local d2Watch = 99999
	local invited = false
	local hunting = zombie:getModData().fromzoidHuntUntil and FromZoid.nowMs() < zombie:getModData().fromzoidHuntUntil
	if zombie.getTarget and zombie:getTarget() then
		hunting = true
	end
	local infos = ctx.infos
	if infos then
		for i = 1, #infos do
			local info = infos[i]
			if info.sealed then
				local d2 = FromZoid.dist2ToPlayer(zombie, info.player)
				if info.invited then
					if d2 <= 324 then
						invited = true
					end
				elseif d2 < d2Watch then
					d2Watch = d2
					sealedBuilding = info.building
				end
			end
		end
	end
	if not sealedBuilding or d2Watch > 1600 then
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		return
	end
	local against = FromZoid.zombieAgainstBuilding(zombie, sealedBuilding)
	local nearOpening = FromZoid.zombieNearOpening(zombie)
	if nearOpening or against or (hunting and d2Watch <= 400) then
		keepOffSealedHouse(zombie, sealedBuilding, true)
		return
	end
	if zombie:getModData().fromzoidHold then
		FromZoid.releaseHold(zombie)
		return
	end
	if invited and sliced then
		if zombie.setCanOpenDoors then
			pcall(function()
				zombie:setCanOpenDoors(true)
			end)
		end
	end
end

Events.EveryTenMinutes.Add(validateSeals)
