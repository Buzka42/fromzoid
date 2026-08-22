if isClient() then
	return
end

local lastIssued = nil

local function tickGathering()
	if not FromZoid.isEnabled("EnableGatheringNights") then
		return
	end
	if not FromZoid.isGatheringNight() then
		lastIssued = nil
		return
	end
	local gt = getGameTime()
	local nights = gt and gt:getNightsSurvived() or 0
	local key = tostring(nights)
	if lastIssued == key then
		return
	end
	local players = FromZoid.playerList()
	if #players == 0 then
		return
	end
	local maxN = tonumber(FromZoid.getSandbox("GatheringMax", 12)) or 12
	if maxN < 1 then
		maxN = 1
	end
	local cands = {}
	FromZoid.eachLoadedZombie(function(zombie)
		if zombie:isUseless() then
			return
		end
		local best = 99999
		local building = nil
		local px, py = zombie:getX(), zombie:getY()
		for i = 1, #players do
			local player = players[i]
			local d2 = FromZoid.dist2ToPlayer(zombie, player)
			if d2 < best and d2 <= 1600 then
				best = d2
				local sq = player:getCurrentSquare()
				building = sq and sq:getBuilding() or nil
				px, py = player:getX(), player:getY()
			end
		end
		if building and best <= 1600 then
			table.insert(cands, { zombie = zombie, d2 = best, building = building, px = px, py = py })
		end
	end)
	table.sort(cands, function(a, b)
		return a.d2 < b.d2
	end)
	local n = math.min(#cands, maxN)
	for i = 1, n do
		local c = cands[i]
		local porch = FromZoid.cachedPorchSquare and FromZoid.cachedPorchSquare(c.building, c.zombie:getX(), c.zombie:getY())
		if not porch then
			porch = FromZoid.nearestPorchSquare(c.building, c.zombie:getX(), c.zombie:getY())
		end
		if porch then
			FromZoid.pathZombieToSquare(c.zombie, porch)
		end
		c.zombie:getModData().fromzoidGather = true
		if FromZoid.isBuildingSealed(c.building) and not FromZoid.buildingHasInvitation(c.building) then
			c.zombie:getModData().fromzoidHold = true
		end
	end
	lastIssued = key
end

Events.EveryOneMinute.Add(tickGathering)
Events.OnGameStart.Add(function()
	lastIssued = nil
end)
