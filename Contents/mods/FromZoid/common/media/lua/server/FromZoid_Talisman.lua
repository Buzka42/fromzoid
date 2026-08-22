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

local function validateSeals()
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	local data = FromZoid.getTalismanData()
	local stale = {}
	for id, entry in pairs(data) do
		if type(entry) == "table" and entry.sealed and entry.x then
			if not squareStillHasTalisman(entry.x, entry.y, entry.z) then
				table.insert(stale, id)
			end
		end
	end
	for i = 1, #stale do
		FromZoid.unsealBuildingId(stale[i])
	end
end

local function nearestExteriorSquare(zombie)
	local zx = math.floor(zombie:getX())
	local zy = math.floor(zombie:getY())
	local zz = math.floor(zombie:getZ())
	local cell = getCell()
	for r = 1, 12 do
		for dx = -r, r do
			for dy = -r, r do
				if math.abs(dx) == r or math.abs(dy) == r then
					local sq = cell:getGridSquare(zx + dx, zy + dy, zz)
					if sq and not sq:getBuilding() then
						return sq
					end
				end
			end
		end
	end
	return cell:getGridSquare(zx + 8, zy, 0)
end

local function nearestOpeningSquare(building, zombie)
	if not building or not building.getRooms then
		return nil
	end
	local rooms = building:getRooms()
	if not rooms then
		return nil
	end
	local best = nil
	local bestD = 999999
	for r = 0, rooms:size() - 1 do
		local room = rooms:get(r)
		local squares = room and room.getSquares and room:getSquares()
		if squares then
			for s = 0, squares:size() - 1 do
				local sq = squares:get(s)
				if FromZoid.squareHasOpening(sq) then
					local dx = sq:getX() - zombie:getX()
					local dy = sq:getY() - zombie:getY()
					local d = dx * dx + dy * dy
					if d < bestD then
						bestD = d
						best = sq
					end
				end
			end
		end
	end
	return best
end

local function clearThump(zombie)
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
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
end

local function enforceTalisman(zombie)
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not zombie or not instanceof(zombie, "IsoZombie") or not zombie:isAlive() then
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.isBuildingSealed(building) then
		local invited = FromZoid.buildingHasInvitation(building)
		if not invited then
			local out = nearestExteriorSquare(zombie)
			if out then
				FromZoid.teleportZombieToSquare(zombie, out)
			end
			clearThump(zombie)
			if zombie.setUseless then
				zombie:setUseless(false)
			end
			return
		end
	end
	local target = zombie.getTarget and zombie:getTarget() or nil
	if target and instanceof(target, "IsoPlayer") then
		local tsq = target:getCurrentSquare()
		local tb = tsq and tsq:getBuilding() or nil
		if tb and FromZoid.isBuildingSealed(tb) and not FromZoid.buildingHasInvitation(tb) then
			clearThump(zombie)
			local opening = nearestOpeningSquare(tb, zombie)
			if opening then
				FromZoid.pathZombieToSquare(zombie, opening)
			end
		end
	end
end

Events.EveryTenMinutes.Add(validateSeals)
Events.OnZombieUpdate.Add(enforceTalisman)
