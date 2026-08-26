if isClient() then
	return
end

-- Everything that BUILDS strain is scaled by this. Player call, 2026-08-25:
-- the descent into insanity was five times too fast. Recovery rates are
-- deliberately NOT scaled -- only the climb is slowed.
-- The sandbox SanitySleepDrain / SanityCrowdDrain multipliers still apply on
-- top of this, so a player can tune it further either way.
local STRAIN_GAIN_MUL = 0.2

local function wakePlayer(player)
	FromZoid.wakePlayer(player)
end

local function tickSanity()
	if not FromZoid.isEnabled("EnableSanity") then
		return
	end
	local players = FromZoid.playerList()
	if #players == 0 then
		return
	end
	local sleepMul = tonumber(FromZoid.getSandbox("SanitySleepDrain", 1)) or 1
	local crowdMul = tonumber(FromZoid.getSandbox("SanityCrowdDrain", 1)) or 1
	local gathering = FromZoid.isGatheringNight()
	local galleries = {}
	local needGallery = false
	for i = 1, #players do
		galleries[i] = 0
		local sq = players[i]:getCurrentSquare()
		local b = sq and sq:getBuilding() or nil
		if b and FromZoid.isBuildingSealed(b) then
			needGallery = true
		end
	end
	-- Cache the crowd count across accelerated game minutes. The strain maths
	-- below must still run every game minute (sleep drain depends on it), but
	-- re-counting the whole zombie list 8x a real second while the player
	-- sleeps is what makes this sweep expensive.
	if needGallery and not FromZoid.realTimeGate("gallery", 1000) then
		local cached = FromZoid._galleryCache
		if cached then
			for i = 1, #players do
				galleries[i] = cached[i] or 0
			end
			needGallery = false
		end
	end
	if needGallery then
		FromZoid.eachLoadedZombie(function(zombie)
			for i = 1, #players do
				if galleries[i] < 8 then
					local player = players[i]
					local sq = player:getCurrentSquare()
					local b = sq and sq:getBuilding() or nil
					if b and FromZoid.isBuildingSealed(b) then
						if FromZoid.dist2ToPlayer(zombie, player) <= 144 then
							local zsq = FromZoid.zombieSquare(zombie)
							local zb = zsq and zsq:getBuilding() or nil
							if not zb or FromZoid.buildingId(zb) ~= FromZoid.buildingId(b) then
								galleries[i] = galleries[i] + 1
							end
						end
					end
				end
			end
		end)
		local snap = {}
		for i = 1, #players do
			snap[i] = galleries[i]
		end
		FromZoid._galleryCache = snap
	end
	for i = 1, #players do
		local player = players[i]
		local delta = 0
		local stats = player.getStats and player:getStats() or nil
		local fatigue = 0
		if stats and stats.getFatigue then
			fatigue = stats:getFatigue() or 0
		end
		if fatigue > 0.45 then
			delta = delta + ((fatigue - 0.45) * 6 * sleepMul)
		end
		local asleep = player.isAsleep and player:isAsleep()
		local floorZ = player.getZ and player:getZ() or 0
		if asleep then
			if galleries[i] > 0 and FromZoid.isEnabled("WhispersBreakSleep") then
				local wake = 4 + galleries[i] * 3
				if floorZ >= 1 then
					wake = math.floor(wake * 0.35)
				end
				if ZombRand(100) < wake then
					wakePlayer(player)
				end
			end
		end
		if galleries[i] > 0 then
			local hear = 1
			if floorZ >= 1 then
				hear = 0.32
			end
			if asleep then
				hear = hear * 0.28
			end
			local crowd = galleries[i] * 0.22 * crowdMul * hear
			if gathering then
				crowd = crowd * 1.6
			end
			delta = delta + crowd
		elseif asleep then
			delta = delta - (0.08 * sleepMul)
		else
			local sq = player:getCurrentSquare()
			local b = sq and sq:getBuilding() or nil
			if b then
				if FromZoid.isBuildingSealed(b) then
					if FromZoid.isDay() then
						delta = delta - 0.07
					else
						delta = delta - 0.03
					end
				elseif FromZoid.isDay() then
					delta = delta - 0.025
				end
			end
		end
		if FromZoid.inTheWoods(player) then
			delta = delta + 2.4
		end
		local mental = FromZoid.mentalStrainMul(player)
		if delta > 0 then
			delta = delta * mental
		elseif mental > 1.25 then
			delta = delta * (2.2 - mental)
			if delta > 0 then
				delta = 0
			end
		end
		if delta > 0 and FromZoid.nearbyAudioPlaying and FromZoid.nearbyAudioPlaying(player) then
			delta = delta * 0.5
		end
		-- Applied last so it scales every source uniformly: woods dread, the
		-- crowd gallery, fatigue and the mental-strain multiplier alike.
		if delta > 0 then
			delta = delta * STRAIN_GAIN_MUL
		end
		FromZoid.addStrain(player, delta)
		local level = FromZoid.sanityLevel(player)
		if asleep and level == "psychosis" and ZombRand(100) < 10 then
			wakePlayer(player)
		end
		if stats then
			if level == "delusion" and stats.setStress then
				pcall(function()
					stats:setStress(math.min(1, (stats:getStress() or 0) + 0.02))
				end)
			elseif level == "psychosis" then
				pcall(function()
					if stats.setStress then
						stats:setStress(math.min(1, (stats:getStress() or 0) + 0.03))
					end
				end)
			end
		end
	end
end

Events.EveryOneMinute.Add(tickSanity)
