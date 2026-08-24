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
			local dest = nil
			if building and FromZoid.standoffSquare then
				dest = FromZoid.standoffSquare(building, entry.x, entry.y)
			end
			if not dest and building and FromZoid.nearestPorchSquare then
				dest = FromZoid.nearestPorchSquare(building, entry.x, entry.y)
			end
			dest = dest or sq
			if dest then
				table.insert(targets, {
					id = id,
					building = building,
					porch = dest,
					x = dest:getX() + 0.5,
					y = dest:getY() + 0.5,
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
	local targets = sealedTargets()
	if #targets == 0 then
		return
	end
	local maxN = tonumber(FromZoid.getSandbox("GatheringMax", 40)) or 40
	if maxN < 1 then
		maxN = 1
	end
	local now = FromZoid.nowMs()
	local n = 0
	FromZoid.eachLoadedZombie(function(zombie)
		if n >= maxN then
			return
		end
		local md = zombie:getModData()
		if md.fromzoidHold then
			return
		end
		if md.fromzoidStillUntil and now < md.fromzoidStillUntil then
			return
		end
		if md.fromzoidHuntUntil and now < md.fromzoidHuntUntil then
			return
		end
		if zombie:isUseless() then
			if FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
				return
			end
			FromZoid.wakeZombieBody(zombie)
		end
		if md.fromzoidGatherAt and (now - md.fromzoidGatherAt) < 20000 then
			return
		end
		local t, d2 = nearestTarget(zombie, targets)
		if not t then
			return
		end
		if d2 and d2 <= 36 then
			md.fromzoidGather = true
			return
		end
		if FromZoid.pathWouldLaunch and FromZoid.pathWouldLaunch(zombie, t.porch) then
			return
		end
		md.fromzoidGatherAt = now
		md.fromzoidGather = true
		FromZoid.pathZombieToSquare(zombie, t.porch)
		n = n + 1
	end)
end

Events.EveryOneMinute.Add(tickGathering)
