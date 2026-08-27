if isClient() then
	return
end

local function lockSpawnBuilding(building)
	return FromZoid.markSpawnHouse(building)
end

local tryHangOnPlayerHouse, tryBoardSpawnHouse, trySpawnAlarmClock

local function rememberSpawnSquare(square)
	if not square or not square.getX then
		return
	end
	local state = FromZoid.getState()
	local key = string.format("%d|%d|%d", square:getX(), square:getY(), square:getZ())
	local blob = state.pendingSpawnSquares or ""
	if ("," .. blob .. ","):find("," .. key .. ",", 1, true) then
		return
	end
	if blob == "" then
		state.pendingSpawnSquares = key
	else
		state.pendingSpawnSquares = blob .. "," .. key
	end
end

local function houseFullyReady(id)
	if not id then
		return false
	end
	if not FromZoid.spawnFlagHas("spawnHangIds", id) then
		return false
	end
	if FromZoid.isEnabled("BoardedSpawnHouse") and not FromZoid.spawnFlagHas("spawnBoardIds", id) then
		return false
	end
	if not FromZoid.spawnFlagHas("spawnClockIds", id) then
		return false
	end
	return true
end

local function resolvePendingSpawns()
	local state = FromZoid.getState()
	local blob = state.pendingSpawnSquares
	if not blob or blob == "" then
		return
	end
	local cell = getCell()
	if not cell then
		return
	end
	local keep = {}
	for piece in string.gmatch(blob, "[^,]+") do
		local x, y, z = piece:match("^(%-?%d+)|(%-?%d+)|(%-?%d+)$")
		if x then
			local sq = cell:getGridSquare(tonumber(x), tonumber(y), tonumber(z))
			local b = sq and sq.getBuilding and sq:getBuilding() or nil
			if b then
				local id = FromZoid.markSpawnHouse(b)
				FromZoid.evictZombiesFromBuilding(b)
				tryHangOnPlayerHouse(nil, b)
				tryBoardSpawnHouse(b)
				trySpawnAlarmClock(b, nil)
				if not houseFullyReady(id) then
					keep[#keep + 1] = piece
				end
			else
				keep[#keep + 1] = piece
			end
		end
	end
	state.pendingSpawnSquares = table.concat(keep, ",")
end

local function clearLockedSpawnHouses()
	local toRemove = {}
	FromZoid.eachLoadedZombie(function(zombie)
		local sq = FromZoid.zombieSquare(zombie)
		local b = sq and sq:getBuilding() or nil
		if b and FromZoid.isSpawnHouseId(FromZoid.buildingId(b)) and FromZoid.shouldKeepZombiesOut(b) then
			toRemove[#toRemove + 1] = zombie
		end
	end)
	for i = 1, #toRemove do
		FromZoid.removeZombieQuiet(toRemove[i])
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

local function giveClockToPlayer(player)
	local function giveTo(p)
		if not p then
			return false
		end
		local inv = p.getInventory and p:getInventory() or nil
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
		local sq = p.getCurrentSquare and p:getCurrentSquare() or nil
		return dropClockOnSquare(sq)
	end
	if giveTo(player) then
		return true
	end
	local players = FromZoid.playerList()
	for i = 1, #players do
		if players[i] ~= player and giveTo(players[i]) then
			return true
		end
	end
	return false
end

local function spawnBuildingForClock(player)
	if player then
		local sq = player.getCurrentSquare and player:getCurrentSquare() or nil
		local building = sq and sq:getBuilding() or nil
		if building then
			lockSpawnBuilding(building)
			return building
		end
	end
	local players = FromZoid.playerList()
	for i = 1, #players do
		local sq = players[i]:getCurrentSquare()
		local building = sq and sq:getBuilding() or nil
		if building and FromZoid.isSpawnHouseId(FromZoid.buildingId(building)) then
			return building
		end
	end
	return nil
end

trySpawnAlarmClock = function(building, player)
	building = building or spawnBuildingForClock(player)
	if not building then
		return false
	end
	lockSpawnBuilding(building)
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	if FromZoid.spawnFlagHas("spawnClockIds", id) then
		return true
	end
	local state = FromZoid.getState()
	local found = 0
	local best = nil
	local bestScore = 0
	local dropSq = nil
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
	if found > 0 or (best and addClockToContainer(best)) or (dropSq and dropClockOnSquare(dropSq)) then
		FromZoid.spawnFlagSet("spawnClockIds", id)
		return true
	end
	local triesKey = "scTries_" .. id
	state[triesKey] = (state[triesKey] or 0) + 1
	if state[triesKey] >= 3 and giveClockToPlayer(player) then
		FromZoid.spawnFlagSet("spawnClockIds", id)
		return true
	end
	return false
end

-- Always board the spawn house. Runs after the talisman is hung so the door
-- the charm picked is the one left clear.
--
-- Deliberately keeps re-running until the building has streamed in:
-- OnNewGame fires before most of the building's squares exist, so an early
-- pass finds barely any windows. addPlanks skips anything already barricaded.
tryBoardSpawnHouse = function(building)
	if not FromZoid.isEnabled("BoardedSpawnHouse") then
		return true
	end
	if not building then
		return false
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	if FromZoid.spawnFlagHas("spawnBoardIds", id) then
		return true
	end
	if not FromZoid.boardUpBuilding then
		return false
	end
	lockSpawnBuilding(building)
	local state = FromZoid.getState()
	local n = FromZoid.boardUpBuilding(building) or 0
	local triesKey = "sbTries_" .. id
	local countKey = "sbCount_" .. id
	state[countKey] = (state[countKey] or 0) + n
	state[triesKey] = (state[triesKey] or 0) + 1
	if FromZoid.isEnabled("TalismanDebug") then
		print(string.format("[FromZoid] board pass %d: +%d planked, %d total, house %s",
			state[triesKey], n, state[countKey], tostring(id)))
	end
	if state[triesKey] >= 10 and state[countKey] > 0 then
		FromZoid.spawnFlagSet("spawnBoardIds", id)
		return true
	end
	return false
end

local function giveSpareTalisman(player)
	if not player or not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not FromZoid.isEnabled("StartWithSpareTalisman") then
		return
	end
	local inv = player.getInventory and player:getInventory() or nil
	if not inv then
		return
	end
	local has = false
	if FromZoid.findTalismanInInventory then
		local ok, item = pcall(FromZoid.findTalismanInInventory, inv)
		has = ok and item
	end
	if has then
		return
	end
	inv:AddItem(FromZoid.ITEM_TALISMAN)
end

tryHangOnPlayerHouse = function(player, building)
	if not FromZoid.isEnabled("EnableTalismans") then
		if building then
			local id = FromZoid.buildingId(building)
			if id then
				FromZoid.spawnFlagSet("spawnHangIds", id)
			end
		end
		return true
	end
	if not building then
		if player then
			local square = player.getCurrentSquare and player:getCurrentSquare() or nil
			building = square and square:getBuilding() or nil
		end
	end
	if not building then
		return false
	end
	local id = lockSpawnBuilding(building)
	if not id then
		return false
	end
	if FromZoid.spawnFlagHas("spawnHangIds", id) then
		return true
	end
	FromZoid.evictZombiesFromBuilding(building)
	if FromZoid.isBuildingSealed(building) then
		FromZoid.spawnFlagSet("spawnHangIds", id)
		return true
	end
	local door = FromZoid.firstDoorInBuilding(building)
	if not door then
		return false
	end
	if FromZoid.hangTalismanOnDoor(nil, door) then
		FromZoid.spawnFlagSet("spawnHangIds", id)
		FromZoid.evictZombiesFromBuilding(building)
		return true
	end
	return false
end

local function prepareSpawnHouse(player, square)
	if square then
		rememberSpawnSquare(square)
	elseif player and player.getCurrentSquare then
		square = player:getCurrentSquare()
		rememberSpawnSquare(square)
	end
	giveSpareTalisman(player)
	local building = square and square.getBuilding and square:getBuilding() or nil
	if not building and player and player.getCurrentSquare then
		local sq = player:getCurrentSquare()
		building = sq and sq:getBuilding() or nil
	end
	if not building then
		return false
	end
	lockSpawnBuilding(building)
	FromZoid.evictZombiesFromBuilding(building)
	tryHangOnPlayerHouse(player, building)
	tryBoardSpawnHouse(building)
	trySpawnAlarmClock(building, player)
	if player and player.getModData then
		player:getModData().fromzoidHouseReady = true
	end
	return true
end

local function retrySpawnHouses()
	resolvePendingSpawns()
	local players = FromZoid.playerList()
	for i = 1, #players do
		local player = players[i]
		local sq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
		local building = sq and sq:getBuilding() or nil
		if building and FromZoid.isSpawnHouseId(FromZoid.buildingId(building)) then
			tryHangOnPlayerHouse(player, building)
			tryBoardSpawnHouse(building)
			trySpawnAlarmClock(building, player)
		end
	end
end

Events.OnNewGame.Add(function(player, square)
	prepareSpawnHouse(player, square)
end)

Events.OnCreatePlayer.Add(function(_, player)
	if not player then
		return
	end
	local md = player.getModData and player:getModData() or nil
	if md and md.fromzoidHouseReady then
		return
	end
	local hours = 0
	if player.getHoursSurvived then
		hours = player:getHoursSurvived() or 0
	end
	-- Load recreates the player. Hours > 0 means an existing survivor; do
	-- not treat their current house as a new spawn. A brand-new character
	-- is ~0 and may not get OnNewGame (second survivor in an old world).
	if hours > 0.05 then
		if md then
			md.fromzoidHouseReady = true
		end
		return
	end
	local square = player.getCurrentSquare and player:getCurrentSquare() or nil
	prepareSpawnHouse(player, square)
end)

Events.OnGameStart.Add(function()
	retrySpawnHouses()
end)

Events.EveryTenMinutes.Add(function()
	resolvePendingSpawns()
	clearLockedSpawnHouses()
end)

Events.EveryOneMinute.Add(function()
	retrySpawnHouses()
end)

Events.OnZombieCreate.Add(function(zombie)
	if not zombie then
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding() or nil
	if building and FromZoid.shouldKeepZombiesOut(building) then
		zombie:getModData().fromzoidEvict = true
	end
end)
