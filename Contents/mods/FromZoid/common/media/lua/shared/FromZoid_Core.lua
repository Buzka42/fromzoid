FromZoid = FromZoid or {}

FromZoid.ITEM_TALISMAN = "FromZoid.Talisman"
FromZoid.MD_STATE = "FromZoidState"
FromZoid.MD_TALISMANS = "FromZoidTalismans"
FromZoid.MD_SQUARES = "FromZoidSquares"

function FromZoid.getSandbox(key, default)
	local page = SandboxVars and SandboxVars.FromZoid
	if not page then
		return default
	end
	local value = page[key]
	if value == nil then
		return default
	end
	return value
end

function FromZoid.isEnabled(key)
	local value = FromZoid.getSandbox(key, true)
	if value == true or value == 1 or value == 2 then
		return true
	end
	if value == false or value == 0 then
		return false
	end
	return not not value
end

function FromZoid.getState()
	return ModData.getOrCreate(FromZoid.MD_STATE)
end

function FromZoid.getTalismanData()
	return ModData.getOrCreate(FromZoid.MD_TALISMANS)
end

function FromZoid.getSquareData()
	return ModData.getOrCreate(FromZoid.MD_SQUARES)
end

function FromZoid.getTimeOfDayHours()
	local gt = getGameTime()
	if not gt then
		return 12
	end
	if gt.getTimeOfDay then
		return gt:getTimeOfDay()
	end
	return gt:getHour() + (gt:getMinutes() / 60)
end

function FromZoid.getDawnDusk()
	local dawn = 6
	local dusk = 21
	local ok, season = pcall(function()
		return getClimateManager():getSeason()
	end)
	if ok and season then
		if season.getDawn then
			dawn = season:getDawn()
		end
		if season.getDusk then
			dusk = season:getDusk()
		end
	end
	return dawn, dusk
end

function FromZoid.isNight()
	local tod = FromZoid.getTimeOfDayHours()
	local dawn, dusk = FromZoid.getDawnDusk()
	return tod < dawn or tod > dusk
end

function FromZoid.isDay()
	return not FromZoid.isNight()
end

function FromZoid.buildingIdFromDef(def)
	if not def then
		return nil
	end
	if def.getID then
		local id = def:getID()
		if id ~= nil then
			return "b" .. tostring(id)
		end
	end
	local x = def.getX and def:getX() or 0
	local y = def.getY and def:getY() or 0
	local x2 = def.getX2 and def:getX2() or x
	local y2 = def.getY2 and def:getY2() or y
	return string.format("%d_%d_%d_%d", x, y, x2, y2)
end

function FromZoid.buildingId(building)
	if not building then
		return nil
	end
	if instanceof(building, "BuildingDef") then
		return FromZoid.buildingIdFromDef(building)
	end
	if building.getDef then
		return FromZoid.buildingIdFromDef(building:getDef())
	end
	if building.getID then
		return "iso" .. tostring(building:getID())
	end
	return nil
end

function FromZoid.buildingFromSquare(square)
	if not square then
		return nil
	end
	return square:getBuilding()
end

function FromZoid.isBuildingSealed(building)
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	local data = FromZoid.getTalismanData()
	local entry = data[id]
	return entry ~= nil and entry.sealed == true
end

function FromZoid.squareHasOpening(square)
	if not square then
		return false
	end
	local objects = square:getObjects()
	if not objects then
		return false
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoDoor") or instanceof(obj, "IsoWindow") then
			return true
		end
	end
	return false
end

function FromZoid.squareHasOpenInvitation(square)
	if not square then
		return false
	end
	local objects = square:getObjects()
	if not objects then
		return false
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoDoor") and obj:IsOpen() then
			return true
		end
		if instanceof(obj, "IsoWindow") then
			if obj.IsOpen and obj:IsOpen() then
				return true
			end
			if obj.isOpen and obj:isOpen() then
				return true
			end
		end
	end
	return false
end

FromZoid._openSeals = FromZoid._openSeals or {}

function FromZoid.scanBuildingInvitation(building)
	if not building then
		return false
	end
	local rooms = building.getRooms and building:getRooms()
	if not rooms then
		local def = building.getDef and building:getDef()
		if def and def.getRooms then
			rooms = def:getRooms()
		end
	end
	if not rooms then
		return false
	end
	for r = 0, rooms:size() - 1 do
		local room = rooms:get(r)
		if room then
			local squares = room.getSquares and room:getSquares()
			if squares then
				for s = 0, squares:size() - 1 do
					if FromZoid.squareHasOpenInvitation(squares:get(s)) then
						return true
					end
				end
			end
		end
	end
	return false
end

function FromZoid.buildingHasInvitation(building)
	if not FromZoid.isEnabled("InvitationRequired") then
		return true
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	return FromZoid._openSeals[id] == true
end

function FromZoid.eachLoadedZombie(fn)
	local cell = getCell()
	if not cell or not cell.getZombieList then
		return
	end
	local list = cell:getZombieList()
	if not list then
		return
	end
	for i = 0, list:size() - 1 do
		local zombie = list:get(i)
		if zombie and zombie:isAlive() and instanceof(zombie, "IsoZombie") then
			fn(zombie, i)
		end
	end
end

function FromZoid.findNearestUnsealedBuilding(x, y, maxRange)
	maxRange = maxRange or 48
	local cell = getCell()
	if not cell then
		return nil
	end
	local best = nil
	local bestD = maxRange * maxRange
	local step = 4
	local ix = math.floor(x)
	local iy = math.floor(y)
	for radius = 0, maxRange, step do
		for dx = -radius, radius, step do
			for dy = -radius, radius, step do
				if radius == 0 or math.abs(dx) == radius or math.abs(dy) == radius then
					local sq = cell:getGridSquare(ix + dx, iy + dy, 0)
					if sq then
						local building = sq:getBuilding()
						if building and not FromZoid.isBuildingSealed(building) then
							local d = dx * dx + dy * dy
							if d < bestD then
								bestD = d
								best = building
								if radius <= 8 then
									return best
								end
							end
						end
					end
				end
			end
		end
		if best and radius >= 20 then
			return best
		end
	end
	return best
end

function FromZoid.freeTileInBuilding(building)
	if not building then
		return nil
	end
	local def = building
	if not instanceof(building, "BuildingDef") and building.getDef then
		def = building:getDef()
	end
	if BuildingHelper and BuildingHelper.getFreeTileFromBuilding then
		local ok, sq = pcall(BuildingHelper.getFreeTileFromBuilding, def)
		if ok and sq then
			return sq
		end
	end
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms and rooms:size() > 0 then
			local room = rooms:get(ZombRand(rooms:size()))
			if room and getCell().getFreeTile then
				return getCell():getFreeTile(room)
			end
		end
	end
	return nil
end

function FromZoid.teleportZombieToSquare(zombie, square)
	if not zombie or not square then
		return
	end
	local x = square:getX() + 0.5
	local y = square:getY() + 0.5
	local z = square:getZ()
	zombie:setX(x)
	zombie:setY(y)
	zombie:setZ(z)
	if zombie.setLx then
		zombie:setLx(x)
		zombie:setLy(y)
		zombie:setLz(z)
	end
	if zombie.setCurrent then
		pcall(function()
			zombie:setCurrent(square)
		end)
	end
end

function FromZoid.pathZombieToSquare(zombie, square)
	if not zombie or not square then
		return
	end
	if zombie.pathToLocationF then
		zombie:pathToLocationF(square:getX() + 0.5, square:getY() + 0.5, square:getZ())
	elseif zombie.pathToLocation then
		zombie:pathToLocation(square:getX(), square:getY(), square:getZ())
	end
end

function FromZoid.zombieSquare(zombie)
	if not zombie then
		return nil
	end
	if zombie.getCurrentSquare then
		local sq = zombie:getCurrentSquare()
		if sq then
			return sq
		end
	end
	if zombie.getSquare then
		return zombie:getSquare()
	end
	return getCell():getGridSquare(math.floor(zombie:getX()), math.floor(zombie:getY()), math.floor(zombie:getZ()))
end

function FromZoid.playerList()
	local players = {}
	if getNumActivePlayers then
		for i = 0, getNumActivePlayers() - 1 do
			local p = getSpecificPlayer(i)
			if p and p:isAlive() then
				table.insert(players, p)
			end
		end
	else
		local p = getPlayer()
		if p and p:isAlive() then
			table.insert(players, p)
		end
	end
	return players
end

function FromZoid.occupiedBuildingIds()
	local ids = {}
	for _, player in ipairs(FromZoid.playerList()) do
		local sq = player:getCurrentSquare()
		local building = FromZoid.buildingFromSquare(sq)
		local id = FromZoid.buildingId(building)
		if id then
			ids[id] = building
		end
	end
	return ids
end
