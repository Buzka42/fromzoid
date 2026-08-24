FromZoid.SANITY_DELUSION = 40
FromZoid.SANITY_PSYCHOSIS = 70
FromZoid.SANITY_DELUSION_EXIT = 28
FromZoid.SANITY_PSYCHOSIS_EXIT = 58

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

function FromZoid.garbleName(name)
	name = tostring(name or "")
	if name == "" then
		return "you"
	end
	local first = string.sub(name, 1, 1)
	local rest = string.sub(name, 2)
	local n = ZombRand and ZombRand(4) or 0
	if n == 0 then
		return first .. "-" .. string.lower(first) .. "…" .. rest
	end
	if n == 1 then
		local tail = string.sub(name, math.max(2, #name - 1))
		return first .. "…" .. tail
	end
	if n == 2 then
		local mid = math.max(1, math.floor(#name / 2))
		return string.sub(name, 1, mid) .. "…" .. first
	end
	return name .. "…" .. first
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
	local md = player:getModData()
	local before = FromZoid.sanityLevel(player)
	local v = tonumber(value) or 0
	if v < 0 then
		v = 0
	elseif v > 100 then
		v = 100
	end
	md.fromzoidStrain = v
	local after = FromZoid.sanityLevel(player)
	if before ~= after then
		md.fromzoidSanityShift = after
		md.fromzoidSanityBand = after
	end
	return v
end

function FromZoid.addStrain(player, delta)
	return FromZoid.setStrain(player, FromZoid.getStrain(player) + (delta or 0))
end

function FromZoid.sanityLevel(player)
	local s = FromZoid.getStrain(player)
	local band = "sanity"
	if player and player.getModData then
		band = player:getModData().fromzoidSanityBand
	end
	if band == "psychosis" then
		if s < FromZoid.SANITY_PSYCHOSIS_EXIT then
			band = (s >= FromZoid.SANITY_DELUSION_EXIT) and "delusion" or "sanity"
		end
	elseif band == "delusion" then
		if s >= FromZoid.SANITY_PSYCHOSIS then
			band = "psychosis"
		elseif s < FromZoid.SANITY_DELUSION_EXIT then
			band = "sanity"
		end
	else
		if s >= FromZoid.SANITY_PSYCHOSIS then
			band = "psychosis"
		elseif s >= FromZoid.SANITY_DELUSION then
			band = "delusion"
		else
			band = "sanity"
		end
	end
	if player and player.getModData then
		player:getModData().fromzoidSanityBand = band
	end
	return band
end

function FromZoid.mentalStrainMul(player)
	local mul = 1
	if not player then
		return mul
	end
	local stats = player.getStats and player:getStats() or nil
	if stats then
		if stats.getPanic then
			mul = mul + ((stats:getPanic() or 0) / 100) * 0.7
		end
		if stats.getStress then
			mul = mul + (stats:getStress() or 0) * 0.5
		end
	end
	pcall(function()
		local moodles = player.getMoodles and player:getMoodles() or nil
		if not moodles or not MoodleType then
			return
		end
		local function bump(mt, amount)
			if not mt then
				return
			end
			local lvl = moodles:getMoodleLevel(mt)
			if lvl and lvl >= 2 then
				mul = mul + amount * (lvl - 1)
			end
		end
		local panicLvl = MoodleType.Panic and moodles:getMoodleLevel(MoodleType.Panic) or 0
		if panicLvl and panicLvl >= 1 then
			mul = mul + 0.08 * panicLvl
		end
		bump(MoodleType.Stress, 0.14)
		if MoodleType.Unhappy then
			bump(MoodleType.Unhappy, 0.1)
		end
		if MoodleType.Bored then
			bump(MoodleType.Bored, 0.06)
		end
	end)
	if mul < 1 then
		return 1
	end
	if mul > 2.4 then
		return 2.4
	end
	return mul
end

function FromZoid.sanityTier(player)
	local level = FromZoid.sanityLevel(player)
	if level == "psychosis" then
		return 3
	end
	if level == "delusion" then
		return 2
	end
	return 1
end

function FromZoid.strainForTier(tier)
	tier = tonumber(tier) or 1
	if tier >= 3 then
		return FromZoid.SANITY_PSYCHOSIS + 5
	end
	if tier >= 2 then
		return FromZoid.SANITY_DELUSION + 5
	end
	return 0
end

function FromZoid.deviceIsPlaying(obj)
	if not obj then
		return false
	end
	local dd = nil
	if obj.getDeviceData then
		dd = obj:getDeviceData()
	end
	if not dd and obj.getModData then
		return false
	end
	if not dd then
		return false
	end
	if dd.getIsTurnedOn then
		return dd:getIsTurnedOn() and true or false
	end
	if dd.isTurnedOn then
		return dd:isTurnedOn() and true or false
	end
	return false
end

function FromZoid.nearbyAudioPlaying(player)
	if not player then
		return false
	end
	local inv = player.getInventory and player:getInventory() or nil
	if inv and inv.getItems then
		local items = inv:getItems()
		if items then
			for i = 0, items:size() - 1 do
				if FromZoid.deviceIsPlaying(items:get(i)) then
					return true
				end
			end
		end
	end
	local vehicle = player.getVehicle and player:getVehicle() or nil
	if vehicle and vehicle.getPartCount then
		for i = 0, vehicle:getPartCount() - 1 do
			local part = vehicle:getPartByIndex(i)
			if part and FromZoid.deviceIsPlaying(part) then
				return true
			end
		end
	end
	local sq = player.getCurrentSquare and player:getCurrentSquare() or nil
	local cell = getCell()
	if not sq or not cell then
		return false
	end
	for dx = -8, 8 do
		for dy = -8, 8 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if n and n.getObjects then
				local objs = n:getObjects()
				if objs then
					for i = 0, objs:size() - 1 do
						local obj = objs:get(i)
						if obj and (instanceof(obj, "IsoRadio") or instanceof(obj, "IsoTelevision") or (obj.getDeviceData and obj:getDeviceData())) then
							if FromZoid.deviceIsPlaying(obj) then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

function FromZoid.inTheWoods(player)
	if not player then
		return false
	end
	if not FromZoid.isEnabled("EnableWoodsDread") then
		return false
	end
	if not FromZoid.isNight() then
		return false
	end
	local now = FromZoid.nowMs()
	if FromZoid._woodsAt and FromZoid._woodsPlayer == player and (now - FromZoid._woodsAt) < 8000 then
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
	local step = 24
	local nearTown = false
	for dx = -dist, dist, step do
		if nearTown then
			break
		end
		for dy = -dist, dist, step do
			local n = cell:getGridSquare(ix + dx, iy + dy, 0)
			if n and n:getBuilding() then
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
		return false
	end
	local interval = tonumber(FromZoid.getSandbox("GatheringIntervalNights", 1)) or 1
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
	return (nights % interval) == 0
end

local function alias(a, b)
	if FromZoid[a] and not FromZoid[b] then
		FromZoid[b] = FromZoid[a]
	end
	if FromZoid[b] and not FromZoid[a] then
		FromZoid[a] = FromZoid[b]
	end
end

alias("playerForename", "playerForename")
alias("nowMs", "nowMs")
alias("sanityLevel", "sanityLevel")
alias("sanityTier", "sanityTier")
alias("inTheWoods", "inTheWoods")
alias("mentalStrainMul", "mentalStrainMul")
alias("nearbyAudioPlaying", "nearbyAudioPlaying")
alias("playerInVehicle", "playerInVehicle")
alias("eachLoadedZombie", "eachLoadedZombie")
alias("buildingId", "buildingId")
alias("getWindowOnSquare", "getWindowOnSquare")
alias("zombieSquare", "zombieSquare")
alias("dist2ToPlayer", "dist2ToPlayer")
alias("putZombieToSleep", "putZombieToSleep")
alias("wakeZombieBody", "wakeZombieBody")
alias("text", "text")
alias("isEnabled", "isEnabled")
alias("getState", "getState")
