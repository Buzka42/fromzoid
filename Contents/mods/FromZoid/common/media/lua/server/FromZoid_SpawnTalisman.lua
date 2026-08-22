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
	if state.spawnTalismanDone then
		return
	end
	local gt = getGameTime()
	if not gt or gt:getNightsSurvived() > 0 then
		if gt and gt:getNightsSurvived() > 0 then
			state.spawnTalismanDone = true
		end
		return
	end
	tryHangOnPlayerHouse()
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
