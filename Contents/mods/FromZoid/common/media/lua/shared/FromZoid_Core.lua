FromZoid = FromZoid or {}

FromZoid.ITEM_TALISMAN = "FromZoid.Talisman"
FromZoid.MD_STATE = "FromZoidState"
FromZoid.MD_TALISMANS = "FromZoidTalismans"
FromZoid.MD_SQUARES = "FromZoidSquares"
FromZoid.MD_CLUSTERS = "FromZoidClusters"

FromZoid.RESIDENTIAL = {
	bedroom = true,
	kitchen = true,
	livingroom = true,
	living = true,
	bathroom = true,
	hall = true,
	dining = true,
	diningroom = true,
	kidsbedroom = true,
}

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

function FromZoid.nowMs()
	if getTimestampMs then
		return getTimestampMs()
	end
	return (os.time() * 1000)
end

function FromZoid.getDawnDusk()
	local now = FromZoid.nowMs()
	if FromZoid._dawnDusk and FromZoid._dawnDuskAt and (now - FromZoid._dawnDuskAt) < 1000 then
		return FromZoid._dawnDusk[1], FromZoid._dawnDusk[2]
	end
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
	local tod = 12
	local gt = getGameTime()
	if gt and gt.getTimeOfDay then
		tod = gt:getTimeOfDay()
	end
	if dawn <= 1.5 and dusk <= 1.5 and tod > 2 then
		dawn = dawn * 24
		dusk = dusk * 24
	end
	FromZoid._dawnDusk = { dawn, dusk }
	FromZoid._dawnDuskAt = now
	return dawn, dusk
end

function FromZoid.isNight()
	local now = FromZoid.nowMs()
	if FromZoid._nightAt and (now - FromZoid._nightAt) < 1000 then
		return FromZoid._night
	end
	local tod = FromZoid.getTimeOfDayHours()
	local dawn, dusk = FromZoid.getDawnDusk()
	FromZoid._night = tod < dawn or tod > dusk
	FromZoid._nightAt = now
	return FromZoid._night
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
			if obj.isSmashed and obj:isSmashed() then
				-- broken glass is not an invitation
			elseif obj.IsOpen and obj:IsOpen() then
				return true
			elseif obj.isOpen and obj:isOpen() then
				return true
			end
		end
	end
	return false
end

FromZoid._openSeals = FromZoid._openSeals or {}
FromZoid._inviteScanAt = FromZoid._inviteScanAt or {}

function FromZoid.scanBuildingInvitation(building)
	if not building then
		return false
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if not def or not def.getX or not cell then
		return false
	end
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local z1 = -1
	local z2 = 1
	if def.getMaxLevel then
		local maxZ = def:getMaxLevel()
		if maxZ and maxZ > z2 then
			z2 = maxZ
		end
	end
	for z = z1, z2 do
		for x = x1, x2 do
			if FromZoid.squareHasOpenInvitation(cell:getGridSquare(x, y1, z)) then
				return true
			end
			if FromZoid.squareHasOpenInvitation(cell:getGridSquare(x, y2, z)) then
				return true
			end
		end
		for y = y1 + 1, y2 - 1 do
			if FromZoid.squareHasOpenInvitation(cell:getGridSquare(x1, y, z)) then
				return true
			end
			if FromZoid.squareHasOpenInvitation(cell:getGridSquare(x2, y, z)) then
				return true
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
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	local last = FromZoid._inviteScanAt[id] or 0
	if now - last > 400 then
		FromZoid._inviteScanAt[id] = now
		if FromZoid.scanBuildingInvitation(building) then
			FromZoid._openSeals[id] = true
		else
			FromZoid._openSeals[id] = nil
		end
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

function FromZoid.findNearestUnsealedBuilding(x, y, maxRange, residentialOnly, needBasement)
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
						if building and not FromZoid.shouldSkipNest(building) and FromZoid.isNestHouse(building) then
							if (not residentialOnly) or FromZoid.isResidentialBuilding(building) then
								if (not needBasement) or FromZoid.buildingHasBasement(building) then
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
			end
		end
		if best and radius >= 20 then
			return best
		end
	end
	return best
end

function FromZoid.pickNestSquare(zombie)
	local x = zombie:getX()
	local y = zombie:getY()
	local building = nil
	if FromZoid.isEnabled("PreferBasementNests") then
		building = FromZoid.findNearestUnsealedBuilding(x, y, 64, true, true)
		if not building then
			building = FromZoid.findNearestUnsealedBuilding(x, y, 64, false, true)
		end
		if building then
			local basement = FromZoid.findBasementSquare(building)
			if basement then
				return basement
			end
		end
	end
	building = FromZoid.findNearestUnsealedBuilding(x, y, 48, true, false)
	if not building then
		building = FromZoid.findNearestUnsealedBuilding(x, y, 48, false, false)
	end
	if not building then
		return nil
	end
	local basement = FromZoid.findBasementSquare(building)
	if basement then
		return basement
	end
	local tile = FromZoid.freeTileInBuilding(building)
	if tile and FromZoid.squareIsSafeNest(tile) then
		return FromZoid.wallAdjacentTile(tile)
	end
	return nil
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
	if not FromZoid.squareIsSafeNest(square) and square.getZ and square:getZ() ~= 0 then
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

FromZoid.TICK_SLICE = 10

function FromZoid.dist2ToPlayer(zombie, player)
	local dx = zombie:getX() - player:getX()
	local dy = zombie:getY() - player:getY()
	return dx * dx + dy * dy
end

function FromZoid.refreshTickContext()
	local now = FromZoid.nowMs()
	if FromZoid._tick and FromZoid._tick.at == now then
		return FromZoid._tick
	end
	local players = FromZoid.playerList()
	local infos = {}
	local anySealedUninvited = false
	local gunshot = FromZoid._gunshotUntil and now < FromZoid._gunshotUntil
	for i = 1, #players do
		local p = players[i]
		local sq = p:getCurrentSquare()
		local b = sq and sq:getBuilding() or nil
		local sprinting = false
		if p.isSprinting and p:isSprinting() then
			sprinting = true
		elseif p.isRunning and p:isRunning() then
			sprinting = true
		end
		local sealed = b and FromZoid.isBuildingSealed(b)
		local invited = false
		if sealed then
			invited = FromZoid.buildingHasInvitation(b)
			if not invited then
				anySealedUninvited = true
			end
		end
		infos[i] = {
			player = p,
			square = sq,
			building = b,
			bid = FromZoid.buildingId(b),
			x = p:getX(),
			y = p:getY(),
			sprinting = sprinting,
			sealed = sealed and true or false,
			invited = invited,
			asleep = (p.isAsleep and p:isAsleep()) or false,
		}
	end
	FromZoid._slice = ((FromZoid._slice or 0) + 1) % FromZoid.TICK_SLICE
	FromZoid._tick = {
		at = now,
		night = FromZoid.isNight(),
		players = players,
		infos = infos,
		anySealedUninvited = anySealedUninvited,
		gunshot = gunshot,
		slice = FromZoid._slice,
		darkness = false,
	}
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state and state.darknessActive then
			FromZoid._tick.night = true
			FromZoid._tick.darkness = true
		end
	end
	return FromZoid._tick
end

function FromZoid.inSlice(zombie, ctx)
	if not ctx then
		return true
	end
	local id = 0
	if zombie.getID then
		id = zombie:getID() or 0
	end
	if id < 0 then
		id = -id
	end
	return (id % FromZoid.TICK_SLICE) == ctx.slice
end

function FromZoid.markGunshot()
	FromZoid._gunshotUntil = FromZoid.nowMs() + 4000
end

function FromZoid.isNestHouse(building)
	if not building then
		return false
	end
	if not FromZoid.isEnabled("NestEveryOtherHouse") then
		return true
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return true
	end
	local spawnId = FromZoid.getState().spawnBuildingId
	if spawnId and spawnId == id then
		return false
	end
	local h = 0
	for i = 1, #id do
		h = h + id:byte(i) * i
	end
	return (h % 2) == 0
end

function FromZoid.getBuildingDef(building)
	if not building then
		return nil
	end
	if instanceof(building, "BuildingDef") then
		return building
	end
	if building.getDef then
		return building:getDef()
	end
	return nil
end

function FromZoid.roomNameIsResidential(name)
	if not name then
		return false
	end
	local n = string.lower(tostring(name))
	n = string.gsub(n, "%s+", "")
	return FromZoid.RESIDENTIAL[n] == true
end

function FromZoid.isResidentialBuilding(building)
	local def = FromZoid.getBuildingDef(building)
	if not def or not def.getRooms then
		return false
	end
	local rooms = def:getRooms()
	if not rooms then
		return false
	end
	for i = 0, rooms:size() - 1 do
		local room = rooms:get(i)
		local name = nil
		if room.getName then
			name = room:getName()
		elseif room.getRoomName then
			name = room:getRoomName()
		end
		if FromZoid.roomNameIsResidential(name) then
			return true
		end
	end
	return false
end

function FromZoid.getDoorOnSquare(square)
	if not square then
		return nil
	end
	local objects = square:getObjects()
	if not objects then
		return nil
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoDoor") then
			return obj
		end
	end
	return nil
end

function FromZoid.getWindowOnSquare(square)
	if not square then
		return nil
	end
	local objects = square:getObjects()
	if not objects then
		return nil
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoWindow") then
			return obj
		end
	end
	return nil
end

function FromZoid.openingPorchSquare(opening, steps)
	if not opening then
		return nil
	end
	steps = steps or 4
	local square = opening.getSquare and opening:getSquare() or nil
	local opp = opening.getOppositeSquare and opening:getOppositeSquare() or nil
	local indoor = nil
	local outdoor = nil
	if square and square:getBuilding() then
		indoor = square
	elseif opp and opp:getBuilding() then
		indoor = opp
	end
	if opp and not opp:getBuilding() then
		outdoor = opp
	elseif square and not square:getBuilding() then
		outdoor = square
	end
	if not outdoor then
		return nil
	end
	if not indoor then
		return outdoor
	end
	local dx = outdoor:getX() - indoor:getX()
	local dy = outdoor:getY() - indoor:getY()
	if dx ~= 0 then
		dx = dx > 0 and 1 or -1
	end
	if dy ~= 0 then
		dy = dy > 0 and 1 or -1
	end
	local cell = getCell()
	local best = outdoor
	for i = 1, steps do
		local n = cell:getGridSquare(outdoor:getX() + dx * i, outdoor:getY() + dy * i, outdoor:getZ())
		if not n or n:getBuilding() then
			break
		end
		if FromZoid.getWindowOnSquare(n) or FromZoid.getDoorOnSquare(n) then
			break
		end
		if n.isFree and not n:isFree(false) then
			break
		end
		best = n
	end
	return best
end

function FromZoid.nearestPorchSquare(building, x, y)
	if not building then
		return nil
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if not def or not def.getX or not cell then
		return nil
	end
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local best = nil
	local bestD = nil
	local function consider(sq)
		if not sq then
			return
		end
		local opening = FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq)
		local porch = FromZoid.openingPorchSquare(opening)
		if not porch then
			return
		end
		local dx = porch:getX() + 0.5 - x
		local dy = porch:getY() + 0.5 - y
		local d = dx * dx + dy * dy
		if not bestD or d < bestD then
			bestD = d
			best = porch
		end
	end
	for z = 0, 1 do
		for px = x1, x2 do
			consider(cell:getGridSquare(px, y1, z))
			consider(cell:getGridSquare(px, y2, z))
		end
		for py = y1 + 1, y2 - 1 do
			consider(cell:getGridSquare(x1, py, z))
			consider(cell:getGridSquare(x2, py, z))
		end
	end
	return best
end

function FromZoid.doorHangSquare(door)
	if not door then
		return nil
	end
	local square = door.getSquare and door:getSquare() or nil
	local opp = door.getOppositeSquare and door:getOppositeSquare() or nil
	if square and square:getBuilding() then
		return square
	end
	if opp and opp:getBuilding() then
		return opp
	end
	return square or opp
end

function FromZoid.doorIsExterior(door)
	if not door then
		return false
	end
	local square = door.getSquare and door:getSquare() or nil
	local opp = door.getOppositeSquare and door:getOppositeSquare() or nil
	local b1 = square and square:getBuilding() or nil
	local b2 = opp and opp:getBuilding() or nil
	if b1 and not b2 then
		return true
	end
	if b2 and not b1 then
		return true
	end
	if b1 and b2 and FromZoid.buildingId(b1) ~= FromZoid.buildingId(b2) then
		return true
	end
	return false
end

function FromZoid.doorHangOffset(door, square)
	local ox, oy, oz = 0.5, 0.5, 1.2
	if not door or not square then
		return ox, oy, oz
	end
	local doorSq = door.getSquare and door:getSquare() or nil
	local onDoorTile = doorSq and doorSq:getX() == square:getX() and doorSq:getY() == square:getY()
	local north = door.getNorth and door:getNorth()
	if north then
		oy = onDoorTile and 0.12 or 0.88
	else
		ox = onDoorTile and 0.12 or 0.88
	end
	return ox, oy, oz
end

function FromZoid.firstDoorInBuilding(building)
	if not building then
		return nil
	end
	local function consider(door, preferExterior)
		if not door then
			return nil
		end
		local hang = FromZoid.doorHangSquare(door)
		if not hang then
			return nil
		end
		if preferExterior and not FromZoid.doorIsExterior(door) then
			return nil
		end
		return door
	end
	local found = nil
	local rooms = building.getRooms and building:getRooms() or nil
	if not rooms then
		local def = FromZoid.getBuildingDef(building)
		if def and def.getRooms then
			rooms = def:getRooms()
		end
	end
	if rooms then
		for r = 0, rooms:size() - 1 do
			local room = rooms:get(r)
			local squares = room and room.getSquares and room:getSquares()
			if squares then
				for s = 0, squares:size() - 1 do
					local door = FromZoid.getDoorOnSquare(squares:get(s))
					local ext = consider(door, true)
					if ext then
						return ext
					end
					if not found then
						found = consider(door, false)
					end
				end
			end
		end
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if def and def.getX and cell then
		local x1 = def:getX() - 1
		local y1 = def:getY() - 1
		local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
		local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, 0)
				local door = FromZoid.getDoorOnSquare(sq)
				local ext = consider(door, true)
				if ext then
					return ext
				end
				if not found then
					found = consider(door, false)
				end
			end
		end
	end
	return found
end

function FromZoid.squareIsSafeNest(square)
	if not square then
		return false
	end
	if square.getZ and square:getZ() < 0 then
		local hasFloor = false
		if square.Has and IsoFlagType and IsoFlagType.solidfloor then
			hasFloor = square:Has(IsoFlagType.solidfloor)
		end
		if not hasFloor and square.getFloor then
			hasFloor = square:getFloor() ~= nil
		end
		if not hasFloor then
			return false
		end
	end
	if square.isFree then
		return square:isFree(false)
	end
	return true
end

function FromZoid.findBasementSquare(building)
	local cell = getCell()
	if not cell then
		return nil
	end
	local def = FromZoid.getBuildingDef(building)
	if def and def.getX and def.getY then
		local x1 = def:getX()
		local y1 = def:getY()
		local x2 = def.getX2 and def:getX2() or (x1 + 8)
		local y2 = def.getY2 and def:getY2() or (y1 + 8)
		if x2 < x1 then
			x1, x2 = x2, x1
		end
		if y2 < y1 then
			y1, y2 = y2, y1
		end
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, -1)
				if sq and FromZoid.squareIsSafeNest(sq) then
					local b = sq:getBuilding()
					if not b or not FromZoid.shouldSkipNest(b) then
						return sq
					end
				end
			end
		end
	end
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms then
			for i = 0, rooms:size() - 1 do
				local room = rooms:get(i)
				local z = 0
				if room.getZ then
					z = room:getZ()
				end
				if z < 0 and getCell().getFreeTile then
					local sq = getCell():getFreeTile(room)
					if sq and FromZoid.squareIsSafeNest(sq) then
						return sq
					end
				end
			end
		end
	end
	return nil
end

function FromZoid.buildingHasBasement(building)
	local id = FromZoid.buildingId(building)
	local now = FromZoid.nowMs()
	if not FromZoid._basementCache or (now - (FromZoid._basementAt or 0)) > 30000 then
		FromZoid._basementCache = {}
		FromZoid._basementAt = now
	end
	if id and FromZoid._basementCache[id] ~= nil then
		return FromZoid._basementCache[id]
	end
	local has = FromZoid.findBasementSquare(building) ~= nil
	if id then
		FromZoid._basementCache[id] = has
	end
	return has
end

function FromZoid.wallAdjacentTile(square)
	if not square then
		return square
	end
	local cell = getCell()
	local dirs = { {1, 0}, {-1, 0}, {0, 1}, {0, -1} }
	for i = 1, #dirs do
		local n = cell:getGridSquare(square:getX() + dirs[i][1], square:getY() + dirs[i][2], square:getZ())
		if n and n.isFree and n:isFree(false) then
			return n
		end
	end
	return square
end

function FromZoid.isZombieOffscreen(zombie)
	if not zombie then
		return true
	end
	if zombie.isOnScreen and zombie:isOnScreen() then
		return false
	end
	local players = (FromZoid._tick and FromZoid._tick.players) or FromZoid.playerList()
	for i = 1, #players do
		local p = players[i]
		if FromZoid.dist2ToPlayer(zombie, p) < 324 then
			if (not p.CanSee) or p:CanSee(zombie) then
				return false
			end
		end
	end
	return true
end

function FromZoid.clusterKey(x, y)
	return math.floor(x / 64) .. "_" .. math.floor(y / 64)
end

function FromZoid.getClusterKind(x, y)
	local data = ModData.getOrCreate(FromZoid.MD_CLUSTERS)
	local key = FromZoid.clusterKey(x, y)
	if data[key] then
		return data[key]
	end
	local boarded = FromZoid.getSandbox("NeighborhoodBoardedChance", 22)
	local damaged = FromZoid.getSandbox("NeighborhoodDamagedChance", 22)
	local kind = "none"
	if ZombRand(100) < boarded then
		kind = "boarded"
	elseif ZombRand(100) < damaged then
		kind = "damaged"
	end
	data[key] = kind
	return kind
end

function FromZoid.putZombieToSleep(zombie)
	if not zombie then
		return
	end
	zombie:setUseless(true)
	if zombie.setCrawler then
		zombie:setCrawler(false)
	end
	if zombie.setFakeDead then
		pcall(function()
			zombie:setFakeDead(false)
		end)
	end
	if zombie.setOnFloor then
		pcall(function()
			zombie:setOnFloor(false)
		end)
	end
	if zombie.setSitOnGround then
		pcall(function()
			zombie:setSitOnGround(true)
		end)
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
end

function FromZoid.wakeZombieBody(zombie)
	if not zombie then
		return
	end
	if zombie.setFakeDead then
		pcall(function()
			zombie:setFakeDead(false)
		end)
	end
	if zombie.setOnFloor then
		pcall(function()
			zombie:setOnFloor(false)
		end)
	end
	if zombie.setSitOnGround then
		pcall(function()
			zombie:setSitOnGround(false)
		end)
	end
	zombie:setUseless(false)
end

function FromZoid.occupiedBuildingIds()
	local now = getTimestampMs and getTimestampMs() or 0
	if FromZoid._occupiedCache and now - (FromZoid._occupiedAt or 0) < 250 then
		return FromZoid._occupiedCache
	end
	local ids = {}
	for _, player in ipairs(FromZoid.playerList()) do
		local sq = player:getCurrentSquare()
		local building = FromZoid.buildingFromSquare(sq)
		local id = FromZoid.buildingId(building)
		if id then
			ids[id] = building
		end
	end
	FromZoid._occupiedCache = ids
	FromZoid._occupiedAt = now
	return ids
end

function FromZoid.shouldSkipNest(building)
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed(building) then
		return true
	end
	local id = FromZoid.buildingId(building)
	if id and FromZoid.occupiedBuildingIds()[id] then
		return true
	end
	return false
end

function FromZoid.shouldKeepZombiesOut(building)
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed(building) and not FromZoid.buildingHasInvitation(building) then
		return true
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	local spawnId = FromZoid.getState().spawnBuildingId
	if spawnId and spawnId == id then
		local gt = getGameTime()
		if not gt or gt:getNightsSurvived() <= 0 then
			return true
		end
	end
	return false
end

function FromZoid.removeZombieQuiet(zombie)
	if not zombie then
		return
	end
	pcall(function()
		if zombie.setTarget then
			zombie:setTarget(nil)
		end
		if zombie.removeFromWorld then
			zombie:removeFromWorld()
		end
		if zombie.removeFromSquare then
			zombie:removeFromSquare()
		end
	end)
end

function FromZoid.evictZombiesFromBuilding(buildingOrId)
	local id = buildingOrId
	if type(buildingOrId) ~= "string" then
		id = FromZoid.buildingId(buildingOrId)
	end
	if not id then
		return
	end
	local toRemove = {}
	FromZoid.eachLoadedZombie(function(zombie)
		local sq = FromZoid.zombieSquare(zombie)
		local b = sq and sq:getBuilding() or nil
		if b and FromZoid.buildingId(b) == id then
			table.insert(toRemove, zombie)
		end
	end)
	for i = 1, #toRemove do
		FromZoid.removeZombieQuiet(toRemove[i])
	end
end
