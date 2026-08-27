if isClient() then
	return
end

local function sealedTargets()
	local data = FromZoid.getTalismanData()
	local cell = getCell()
	if not data or not cell then
		return {}
	end
	local targets = {}
	for id, entry in pairs(data) do
		if type(entry) == "table" and entry.sealed and entry.x then
			local sq = cell:getGridSquare(entry.x, entry.y, entry.z or 0)
			local building = sq and sq.getBuilding and sq:getBuilding() or nil
			if building then
				local def = FromZoid.getBuildingDef(building)
				local cx, cy = entry.x, entry.y
				if def and def.getX then
					local x2 = def.getX2 and def:getX2() or def:getX()
					local y2 = def.getY2 and def:getY2() or def:getY()
					cx = (def:getX() + x2) / 2
					cy = (def:getY() + y2) / 2
				end
				table.insert(targets, {
					id = id,
					building = building,
					x = cx,
					y = cy,
				})
			end
		end
	end
	return targets
end

local function nearestTarget(zombie, targets)
	local best = nil
	local bestD = nil
	local zx = zombie:getX()
	local zy = zombie:getY()
	for i = 1, #targets do
		local t = targets[i]
		local dx = zx - t.x
		local dy = zy - t.y
		local d = dx * dx + dy * dy
		if not bestD or d < bestD then
			bestD = d
			best = t
		end
	end
	return best, bestD
end

local function tickGathering()
	if not FromZoid.isEnabled("EnableGatheringNights") then
		return
	end
	if not FromZoid.isNight() then
		return
	end
	if not FromZoid.realTimeGate("gather", 1000) then
		return
	end
	local targets = sealedTargets()
	if #targets == 0 then
		return
	end
	local maxN = tonumber(FromZoid.getSandbox("GatheringMax", 40)) or 40
	if maxN < 1 then
		maxN = 1
	end
	local now = FromZoid.nowMs()
	-- Count who is already in the horde first. The old code capped new
	-- paths per tick but re-picked the set every minute, so membership
	-- could drift well past GatheringMax over a long night.
	local enrolled = 0
	local candidates = {}
	FromZoid.eachLoadedZombie(function(zombie)
		local md = zombie:getModData()
		if md.fromzoidHold or md.fromzoidLoiter or FromZoid.isWhisperWalker(zombie) then
			enrolled = enrolled + 1
			return
		end
		if md.fromzoidStillUntil and now < md.fromzoidStillUntil then
			return
		end
		if md.fromzoidHuntUntil and now < md.fromzoidHuntUntil then
			return
		end
		local member = md.fromzoidGather and true or false
		if member then
			enrolled = enrolled + 1
		end
		if md.fromzoidGatherAt and (now - md.fromzoidGatherAt) < 10000 then
			return
		end
		candidates[#candidates + 1] = { zombie = zombie, member = member }
	end)
	-- Returns true if this zombie is part of the horde after this pass.
	local function enrol(zombie)
		local md = zombie:getModData()
		if zombie:isUseless() then
			if FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
				return false
			end
			FromZoid.wakeZombieBody(zombie)
		end
		local t = nearestTarget(zombie, targets)
		if not t then
			return false
		end
		-- Arrived: hand off to the loiter state instead of standing on the
		-- porch tile. enforceTalisman keeps them milling from here.
		if FromZoid.zombieInRingBand(zombie, t.building)
			or FromZoid.zombieTouchingBuilding(zombie, t.building) then
			md.fromzoidGather = true
			return true
		end
		-- Each zombie owns a fixed arc of the ring, so the horde wraps the
		-- house instead of forty bodies converging on one door.
		local dest = FromZoid.ringSlotSquare(zombie, t.building)
		if not dest then
			return false
		end
		if FromZoid.pathWouldLaunch(zombie, dest) then
			return false
		end
		md.fromzoidGatherAt = now
		md.fromzoidGather = true
		-- Sprint the approach. loiterNearHouse forces the shamble gait when
		-- they arrive and nothing put it back, so a zombie that had loitered
		-- once crossed the whole neighbourhood at walking pace afterwards.
		if FromZoid.isEnabled("NightSprinters") and zombie.setWalkType
			and zombie.getWalkType and zombie:getWalkType() ~= "sprint1" then
			pcall(function()
				zombie:setWalkType("sprint1")
				if zombie.setSpeedTypeFromWalkType then
					zombie:setSpeedTypeFromWalkType()
				end
			end)
		end
		FromZoid.pathZombieToSquare(zombie, dest)
		return true
	end

	local started = enrolled
	local added = 0
	local capped = false
	for i = 1, #candidates do
		if enrolled >= maxN then
			capped = true
			break
		end
		local c = candidates[i]
		-- Existing members were already counted above; only a newcomer
		-- taking a slot grows the horde.
		if enrol(c.zombie) and not c.member then
			enrolled = enrolled + 1
			added = added + 1
		end
	end
	if FromZoid.isEnabled("TalismanDebug") then
		print(string.format(
			"[FromZoid] gather: cap=%d already=%d candidates=%d added=%d now=%d%s",
			maxN, started, #candidates, added, enrolled, capped and " CAPPED" or ""))
	end
end

Events.EveryOneMinute.Add(tickGathering)
