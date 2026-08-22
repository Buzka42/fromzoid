FromZoid.SANITY_DELUSION = 40
FromZoid.SANITY_PSYCHOSIS = 70

function FromZoid.playerForename(player)
	if not player then
		return "you"
	end
	local d = player.getDescriptor and player:getDescriptor() or nil
	if d and d.getForename then
		local name = d:getForename()
		if name and name ~= "" then
			return name
		end
	end
	if player.getUsername then
		local u = player:getUsername()
		if u and u ~= "" then
			return u
		end
	end
	return "you"
end

function FromZoid.getStrain(player)
	if not player or not player.getModData then
		return 0
	end
	return tonumber(player:getModData().fromzoidStrain) or 0
end

function FromZoid.setStrain(player, value)
	if not player or not player.getModData then
		return 0
	end
	local v = tonumber(value) or 0
	if v < 0 then
		v = 0
	elseif v > 100 then
		v = 100
	end
	player:getModData().fromzoidStrain = v
	return v
end

function FromZoid.addStrain(player, delta)
	return FromZoid.setStrain(player, FromZoid.getStrain(player) + (delta or 0))
end

function FromZoid.sanityLevel(player)
	local s = FromZoid.getStrain(player)
	if s >= FromZoid.SANITY_PSYCHOSIS then
		return "psychosis"
	end
	if s >= FromZoid.SANITY_DELUSION then
		return "delusion"
	end
	return "sanity"
end

function FromZoid.inTheWoods(player)
	if not player then
		return false
	end
	if not FromZoid.isEnabled("EnableWoodsDread") then
		return false
	end
	if not FromZoid.isNight() then
		local state = FromZoid.getState()
		if not (state and state.darknessActive) then
			return false
		end
	end
	local now = FromZoid.nowMs()
	if FromZoid._woodsAt and FromZoid._woodsPlayer == player and (now - FromZoid._woodsAt) < 4000 then
		return FromZoid._woods
	end
	local sq = player.getCurrentSquare and player:getCurrentSquare() or nil
	if not sq or sq:getBuilding() then
		FromZoid._woods = false
		FromZoid._woodsAt = now
		FromZoid._woodsPlayer = player
		return false
	end
	local dist = tonumber(FromZoid.getSandbox("WoodsDistance", 80)) or 80
	local cell = getCell()
	if not cell then
		return false
	end
	local ix = math.floor(player:getX())
	local iy = math.floor(player:getY())
	local step = 16
	local nearTown = false
	for dx = -dist, dist, step do
		if nearTown then
			break
		end
		for dy = -dist, dist, step do
			local n = cell:getGridSquare(ix + dx, iy + dy, 0)
			local b = n and n:getBuilding() or nil
			if b and (FromZoid.isResidentialBuilding(b) or FromZoid.isBuildingSealed(b)) then
				nearTown = true
				break
			end
		end
	end
	FromZoid._woods = not nearTown
	FromZoid._woodsAt = now
	FromZoid._woodsPlayer = player
	return FromZoid._woods
end

function FromZoid.isGatheringNight()
	if not FromZoid.isEnabled("EnableGatheringNights") then
		return false
	end
	if not FromZoid.isNight() then
		local state = FromZoid.getState()
		if not (state and state.darknessActive) then
			return false
		end
	end
	local interval = tonumber(FromZoid.getSandbox("GatheringIntervalNights", 7)) or 7
	if interval < 1 then
		interval = 1
	end
	local gt = getGameTime()
	local nights = gt and gt:getNightsSurvived() or 0
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state and state.darknessActive then
			return true
		end
	end
	return (nights % interval) == 0 and nights > 0
end
