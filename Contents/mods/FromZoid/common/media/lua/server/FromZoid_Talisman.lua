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
					entry.sealed = false
					entry.wilted = true
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

local function abortPath(zombie)
	pcall(function()
		if zombie.getPathFindBehavior2 then
			zombie:getPathFindBehavior2():cancel()
		end
		if zombie.setPath2 then
			zombie:setPath2(nil)
		end
	end)
end

local function onSealedOpening(zombie, building)
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return false, nil
	end
	local opening = FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq)
	if not opening then
		return false, nil
	end
	local ob = buildingFromObject(opening)
	if ob and FromZoid.buildingId(ob) == FromZoid.buildingId(building) then
		return true, opening
	end
	return false, opening
end

local function ejectIfInside(zombie, building)
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return false
	end
	local inside = sq:getBuilding() and FromZoid.buildingId(sq:getBuilding()) == FromZoid.buildingId(building)
	local onOpening, opening = onSealedOpening(zombie, building)
	if not inside and not onOpening then
		return false
	end
	local porch = FromZoid.openingPorchSquare(opening)
	if not porch then
		local cell = getCell()
		local dirs = { {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {2, 0}, {-2, 0}, {0, 2}, {0, -2} }
		for i = 1, #dirs do
			local n = cell:getGridSquare(sq:getX() + dirs[i][1], sq:getY() + dirs[i][2], sq:getZ())
			if n and not n:getBuilding() and not FromZoid.getWindowOnSquare(n) and not FromZoid.getDoorOnSquare(n) and n.isFree and n:isFree(false) then
				porch = n
				break
			end
		end
	end
	if porch then
		abortPath(zombie)
		FromZoid.teleportZombieToSquare(zombie, porch)
		return true
	end
	return inside or onOpening
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

local function keepOffSealedHouse(zombie, building, aggressive)
	zombie:getModData().fromzoidHold = true
	stopThump(zombie)
	local ejected = false
	if building then
		ejected = ejectIfInside(zombie, building)
	end
	if aggressive or ejected then
		clearPursuit(zombie)
		return
	end
	local target = zombie.getTarget and zombie:getTarget() or nil
	if target then
		clearPursuit(zombie)
	end
end

function FromZoid.enforceTalisman(zombie, ctx, sliced)
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	if thumpIsSealed(zombie) then
		local thump = zombie.getThumpTarget and zombie:getThumpTarget() or nil
		keepOffSealedHouse(zombie, buildingFromObject(thump), true)
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.isBuildingSealed(building) and not FromZoid.buildingHasInvitation(building) then
		keepOffSealedHouse(zombie, building, true)
		return
	end
	ctx = ctx or FromZoid.refreshTickContext()
	if not ctx.anySealedUninvited then
		if zombie:getModData().fromzoidHold and sliced then
			zombie:getModData().fromzoidHold = nil
		end
		return
	end
	if not sliced then
		return
	end
	local infos = ctx.infos
	if not infos or #infos == 0 then
		return
	end
	local nearest = 9999
	local sealedBuilding = nil
	local invited = false
	for i = 1, #infos do
		local info = infos[i]
		local d2 = FromZoid.dist2ToPlayer(zombie, info.player)
		if d2 < nearest then
			nearest = d2
		end
		if d2 <= 324 and info.sealed then
			if info.invited then
				invited = true
			else
				sealedBuilding = info.building
			end
		end
	end
	if nearest > 324 then
		zombie:getModData().fromzoidHold = nil
		return
	end
	if sealedBuilding then
		keepOffSealedHouse(zombie, sealedBuilding, false)
		return
	end
	if invited then
		zombie:getModData().fromzoidHold = nil
		if zombie.setCanOpenDoors then
			pcall(function()
				zombie:setCanOpenDoors(true)
			end)
		end
	end
end

Events.EveryTenMinutes.Add(validateSeals)
