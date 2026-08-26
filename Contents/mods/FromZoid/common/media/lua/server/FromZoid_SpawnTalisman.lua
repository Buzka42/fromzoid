if isClient() then
	return
end

local function lockSpawnBuilding(building)
	if not building then
		return
	end
	local state = FromZoid.getState()
	if state.spawnBuildingId then
		return
	end
	state.spawnBuildingId = FromZoid.buildingId(building)
end

local function clearLockedSpawnHouse()
	local id = FromZoid.getState().spawnBuildingId
	if id then
		FromZoid.evictZombiesFromBuilding(id)
	end
end

local CLOCK_TYPE = "Base.AlarmClock2"

local function isHouseAlarmClock(item)
	if not item then
		return false
	end
	local full = item.getFullType and tostring(item:getFullType() or "") or ""
	if full == CLOCK_TYPE or full == "Base.AlarmClock" then
		return true
	end
	local t = item.getType and tostring(item:getType() or "") or ""
	return t == "AlarmClock2" or t == "AlarmClock"
end

local function armClock(item)
	if not item then
		return
	end
	pcall(function()
		if item.setHour then
			item:setHour(7)
		end
		if item.setMinute then
			item:setMinute(0)
		end
		if item.setAlarmSet then
			item:setAlarmSet(true)
		end
		if item.syncAlarmClock then
			item:syncAlarmClock()
		end
	end)
end

local function makeClock()
	local item = nil
	if instanceItem then
		item = instanceItem(CLOCK_TYPE)
	end
	if not item and InventoryItemFactory and InventoryItemFactory.CreateItem then
		item = InventoryItemFactory.CreateItem(CLOCK_TYPE)
	end
	if item then
		armClock(item)
	end
	return item
end

local function eachBuildingSquare(building, fn)
	if not building or not fn then
		return
	end
	local rooms = building.getRooms and building:getRooms() or nil
	if not rooms then
		local def = FromZoid.getBuildingDef and FromZoid.getBuildingDef(building) or nil
		rooms = def and def.getRooms and def:getRooms() or nil
	end
	if not rooms then
		return
	end
	for r = 0, rooms:size() - 1 do
		local room = rooms:get(r)
		local squares = room and room.getSquares and room:getSquares()
		if squares then
			for s = 0, squares:size() - 1 do
				fn(squares:get(s), room)
			end
		end
	end
end

local function roomName(room, square)
	local name = ""
	if room and room.getName then
		name = tostring(room:getName() or "")
	end
	if name == "" and square and square.getRoom then
		local isoRoom = square:getRoom()
		if isoRoom and isoRoom.getName then
			name = tostring(isoRoom:getName() or "")
		end
	end
	return string.lower(name)
end

local function isBedroom(room, square)
	local name = roomName(room, square)
	return name:find("bedroom", 1, true) ~= nil or name:find("motel", 1, true) ~= nil
end

local function containerType(container)
	if not container then
		return ""
	end
	local typ = ""
	if container.getType then
		typ = tostring(container:getType() or "")
	end
	if typ == "" and container.getContainerType then
		typ = tostring(container:getContainerType() or "")
	end
	return string.lower(typ)
end

local function containerScore(container, room, square)
	local typ = containerType(container)
	if typ == "" then
		return 0
	end
	if typ:find("fridge") or typ:find("freezer") or typ:find("stove") or typ:find("microwave") or typ:find("oven") or typ:find("barbeque") or typ:find("bin") or typ:find("trash") or typ:find("toilet") then
		return -1
	end
	local score = 5
	if typ:find("sidetable") or typ:find("bedside") or typ:find("nightstand") then
		score = 60
	elseif typ:find("dresser") then
		score = 50
	elseif typ:find("shelf") then
		score = 25
	elseif typ:find("wardrobe") then
		score = 20
	elseif typ:find("desk") or typ:find("table") then
		score = 15
	end
	if isBedroom(room, square) then
		score = score + 25
	end
	return score
end

local function eachLiveSquare(building, fn)
	if not building or not fn then
		return
	end
	local seen = {}
	local function consider(square, room)
		if not square then
			return
		end
		local key = tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
		if seen[key] then
			return
		end
		seen[key] = true
		if not room and square.getRoom then
			room = square:getRoom()
		end
		fn(square, room)
	end
	eachBuildingSquare(building, consider)
	local def = FromZoid.getBuildingDef and FromZoid.getBuildingDef(building) or nil
	local cell = getCell()
	if not def or not def.getX or not cell then
		return
	end
	local x1 = def:getX()
	local y1 = def:getY()
	local x2 = def.getX2 and def:getX2() or x1
	local y2 = def.getY2 and def:getY2() or y1
	local z1 = 0
	local z2 = 1
	if def.getMinLevel then
		z1 = def:getMinLevel() or 0
	end
	if def.getMaxLevel then
		z2 = math.max(z2, def:getMaxLevel() or 1)
	end
	local bid = FromZoid.buildingId(building)
	for z = z1, z2 do
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, z)
				local b = sq and sq.getBuilding and sq:getBuilding() or nil
				if b and FromZoid.buildingId(b) == bid then
					consider(sq, nil)
				end
			end
		end
	end
end

local function eachContainerOnSquare(square, fn)
	if not square or not square.getObjects then
		return
	end
	local objects = square:getObjects()
	if not objects then
		return
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if obj then
			local used = false
			if obj.getContainerCount and obj.getContainerByIndex then
				local n = obj:getContainerCount() or 0
				for c = 0, n - 1 do
					fn(obj:getContainerByIndex(c))
					used = true
				end
			end
			if not used and obj.getContainer then
				fn(obj:getContainer())
			end
		end
	end
end

local function eachWorldItemOnSquare(square, fn)
	if not square then
		return
	end
	local list = square.getWorldObjects and square:getWorldObjects() or nil
	if not list and square.getWorldInventoryObjects then
		list = square:getWorldInventoryObjects()
	end
	if not list then
		return
	end
	for i = 0, list:size() - 1 do
		local obj = list:get(i)
		local item = obj and obj.getItem and obj:getItem() or nil
		if item then
			fn(item)
		end
	end
end

local function addClockToContainer(container)
	if not container then
		return false
	end
	local item = makeClock()
	if not item then
		return false
	end
	if container.AddItem then
		local added = container:AddItem(item)
		if added then
			if added ~= true then
				armClock(added)
			end
			return true
		end
	end
	return false
end

local function dropClockOnSquare(square)
	if not square or not square.AddWorldInventoryItem then
		return false
	end
	local item = makeClock()
	if not item then
		return false
	end
	local placed = square:AddWorldInventoryItem(item, 0.5, 0.5, 0)
	if placed then
		if placed ~= true then
			armClock(placed)
		end
		return true
	end
	placed = square:AddWorldInventoryItem(CLOCK_TYPE, 0.5, 0.5, 0)
	if placed then
		if placed ~= true then
			armClock(placed)
		end
		return true
	end
	return false
end

local function giveClockToPlayer()
	local players = FromZoid.playerList()
	for i = 1, #players do
		local player = players[i]
		local inv = player and player.getInventory and player:getInventory() or nil
		if inv then
			local item = makeClock()
			if item and inv.AddItem then
				local added = inv:AddItem(item)
				if added then
					if added ~= true then
						armClock(added)
					end
					return true
				end
			end
		end
		local sq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
		if dropClockOnSquare(sq) then
			return true
		end
	end
	return false
end

local function spawnBuildingForClock()
	local state = FromZoid.getState()
	local players = FromZoid.playerList()
	for i = 1, #players do
		local sq = players[i]:getCurrentSquare()
		local building = sq and sq:getBuilding() or nil
		if building then
			lockSpawnBuilding(building)
			if not state.spawnBuildingId or FromZoid.buildingId(building) == state.spawnBuildingId then
				return building
			end
		end
	end
	return nil
end

local function trySpawnAlarmClock(building)
	local state = FromZoid.getState()
	if state.spawnAlarmClock2 then
		return true
	end
	building = building or spawnBuildingForClock()
	local found = 0
	local best = nil
	local bestScore = 0
	local dropSq = nil
	if building then
		lockSpawnBuilding(building)
		eachLiveSquare(building, function(square, room)
			if not square then
				return
			end
			eachWorldItemOnSquare(square, function(item)
				if isHouseAlarmClock(item) then
					armClock(item)
					found = found + 1
				end
			end)
			eachContainerOnSquare(square, function(container)
				if not container then
					return
				end
				local items = container.getItems and container:getItems() or nil
				if items then
					for i = 0, items:size() - 1 do
						local item = items:get(i)
						if isHouseAlarmClock(item) then
							armClock(item)
							found = found + 1
						end
					end
				end
				local score = containerScore(container, room, square)
				if score > bestScore then
					bestScore = score
					best = container
				end
			end)
			if isBedroom(room, square) then
				dropSq = square
			elseif not dropSq then
				dropSq = square
			end
		end)
	end
	if found > 0 then
		state.spawnAlarmClock2 = true
		state.spawnAlarmClockDone = true
		return true
	end
	if best and addClockToContainer(best) then
		state.spawnAlarmClock2 = true
		state.spawnAlarmClockDone = true
		return true
	end
	if dropSq and dropClockOnSquare(dropSq) then
		state.spawnAlarmClock2 = true
		state.spawnAlarmClockDone = true
		return true
	end
	state.spawnAlarmClockTries = (state.spawnAlarmClockTries or 0) + 1
	if state.spawnAlarmClockTries >= 3 and giveClockToPlayer() then
		state.spawnAlarmClock2 = true
		state.spawnAlarmClockDone = true
		return true
	end
	return false
end

-- Always board the spawn house. Runs after the talisman is hung so the door
-- the charm picked is the one left clear.
-- Always board the spawn house. Runs after the talisman is hung so the door
-- the charm picked is the one left clear.
--
-- Deliberately keeps re-running across the first few minutes of day 0:
-- OnNewGame fires before most of the building's squares have streamed in, so
-- an early pass finds barely any windows. The old version boarded whatever it
-- could see, reported success and never came back, which is why the spawn
-- house came out unboarded. addPlanks skips anything already barricaded, so
-- repeat passes only top up.
local function tryBoardSpawnHouse(building)
	if not FromZoid.isEnabled("BoardedSpawnHouse") then
		return true
	end
	local state = FromZoid.getState()
	if state.spawnBoardedDone then
		return true
	end
	if not building then
		local id = state.spawnBuildingId
		local players = FromZoid.playerList()
		local sq = players[1] and players[1]:getCurrentSquare() or nil
		local b = sq and sq:getBuilding() or nil
		if b and (not id or FromZoid.buildingId(b) == id) then
			building = b
		end
	end
	if not building or not FromZoid.boardUpBuilding then
		return false
	end
	local n = FromZoid.boardUpBuilding(building) or 0
	state.spawnBoardedCount = (state.spawnBoardedCount or 0) + n
	state.spawnBoardTries = (state.spawnBoardTries or 0) + 1
	if FromZoid.isEnabled("TalismanDebug") then
		print(string.format("[FromZoid] board pass %d: +%d planked, %d total, house %s",
			state.spawnBoardTries, n, state.spawnBoardedCount,
			tostring(FromZoid.buildingId(building))))
	end
	if state.spawnBoardTries >= 10 and state.spawnBoardedCount > 0 then
		state.spawnBoardedDone = true
		return true
	end
	return false
end

local function tryHangOnPlayerHouse()
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	local state = FromZoid.getState()
	if state.spawnTalismanDone then
		return true
	end
	local players = FromZoid.playerList()
	if #players == 0 then
		return false
	end
	local square = players[1]:getCurrentSquare()
	local building = square and square:getBuilding() or nil
	lockSpawnBuilding(building)
	if not building and state.spawnBuildingId then
		return false
	end
	if not building then
		return false
	end
	FromZoid.evictZombiesFromBuilding(building)
	if FromZoid.isBuildingSealed(building) then
		state.spawnTalismanDone = true
		return true
	end
	local door = FromZoid.firstDoorInBuilding(building)
	if not door then
		return false
	end
	if FromZoid.hangTalismanOnDoor(nil, door) then
		state.spawnTalismanDone = true
		FromZoid.evictZombiesFromBuilding(building)
		return true
	end
	return false
end

Events.OnNewGame.Add(function(player, square)
	if FromZoid.isEnabled("EnableTalismans") and FromZoid.isEnabled("StartWithSpareTalisman") and player then
		player:getInventory():AddItem(FromZoid.ITEM_TALISMAN)
	end
	local building = square and square:getBuilding() or (player and player:getCurrentSquare() and player:getCurrentSquare():getBuilding())
	lockSpawnBuilding(building)
	if building then
		FromZoid.evictZombiesFromBuilding(building)
	end
	tryHangOnPlayerHouse()
	tryBoardSpawnHouse(building)
	trySpawnAlarmClock(building)
end)

Events.OnGameStart.Add(function()
	trySpawnAlarmClock()
end)

Events.EveryTenMinutes.Add(function()
	local gt = getGameTime()
	if gt and gt:getNightsSurvived() <= 0 then
		local players = FromZoid.playerList()
		if #players > 0 then
			local sq = players[1]:getCurrentSquare()
			lockSpawnBuilding(sq and sq:getBuilding() or nil)
		end
		clearLockedSpawnHouse()
	end
end)

Events.EveryOneMinute.Add(function()
	local state = FromZoid.getState()
	local gt = getGameTime()
	local day0 = gt and gt:getNightsSurvived() <= 0
	if not state.spawnTalismanDone then
		if not gt or not day0 then
			if gt and not day0 then
				state.spawnTalismanDone = true
			end
		else
			tryHangOnPlayerHouse()
		end
	end
	if not state.spawnAlarmClock2 then
		trySpawnAlarmClock()
	end
	-- Retry: on a fresh game the building is often not resolvable yet when
	-- OnNewGame fires, and LoadGridsquare ordering is not guaranteed either.
	if not state.spawnBoardedDone and day0 then
		tryBoardSpawnHouse(nil)
	end
end)

Events.OnZombieCreate.Add(function(zombie)
	if not zombie then
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.shouldKeepZombiesOut(building) then
		FromZoid.removeZombieQuiet(zombie)
	end
end)
