if isClient() then
	return
end

local function wakePlayer(player)
	if not player then
		return
	end
	if player.isAsleep and player:isAsleep() then
		pcall(function()
			if player.setAsleep then
				player:setAsleep(false)
			end
			if player.forceAwake then
				player:forceAwake()
			end
		end)
	end
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
	for i = 1, #players do
		galleries[i] = 0
	end
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
		if asleep then
			delta = delta - (3.5 * sleepMul)
			if galleries[i] > 0 and FromZoid.isEnabled("WhispersBreakSleep") then
				delta = delta + (galleries[i] * 0.8 * crowdMul)
				if ZombRand(100) < (12 + galleries[i] * 8) then
					wakePlayer(player)
				end
			end
		end
		if galleries[i] > 0 then
			local crowd = galleries[i] * 0.55 * crowdMul
			if gathering then
				crowd = crowd * 1.6
			end
			delta = delta + crowd
		elseif FromZoid.isDay() and player:getCurrentSquare() and player:getCurrentSquare():getBuilding() then
			local b = player:getCurrentSquare():getBuilding()
			if FromZoid.isBuildingSealed(b) then
				delta = delta - 1.8
			else
				delta = delta - 0.4
			end
		end
		if FromZoid.inTheWoods(player) then
			delta = delta + 2.4
		end
		FromZoid.addStrain(player, delta)
		local level = FromZoid.sanityLevel(player)
		if stats then
			if level == "delusion" and stats.setStress then
				pcall(function()
					stats:setStress(math.min(1, (stats:getStress() or 0) + 0.02))
				end)
			elseif level == "psychosis" then
				pcall(function()
					if stats.setStress then
						stats:setStress(math.min(1, (stats:getStress() or 0) + 0.05))
					end
					if stats.setPanic then
						stats:setPanic(math.min(100, (stats:getPanic() or 0) + 4))
					end
				end)
			end
		end
	end
end

Events.EveryOneMinute.Add(tickSanity)
