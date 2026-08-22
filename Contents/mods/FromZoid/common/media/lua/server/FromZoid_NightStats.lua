if isClient() then
	return
end

local lastNight = nil

local function applyWalkType(zombie, night, sprinters)
	if not zombie then
		return
	end
	if night then
		if zombie.setCrawler then
			zombie:setCrawler(false)
		end
		if zombie.setWalkType then
			if sprinters then
				zombie:setWalkType("sprint1")
			else
				zombie:setWalkType("")
			end
		end
	else
		if ZombRand(100) < 55 then
			if zombie.setCrawler then
				zombie:setCrawler(true)
			end
		else
			if zombie.setCrawler then
				zombie:setCrawler(false)
			end
			if zombie.setWalkType then
				zombie:setWalkType("slow1")
			end
		end
	end
	if zombie.setSpeedTypeFromWalkType then
		pcall(function()
			zombie:setSpeedTypeFromWalkType()
		end)
	end
end

local function applyLore(night, sprinters)
	if not SandboxVars or not SandboxVars.ZombieLore then
		return
	end
	local lore = SandboxVars.ZombieLore
	if night then
		lore.Speed = sprinters and 1 or 2
		lore.Hearing = 1
		lore.Memory = 1
		lore.Sight = 2
		lore.Cognition = 1
		lore.ThumpNoChasing = false
	else
		lore.Speed = 3
		lore.Hearing = 3
		lore.Memory = 4
		lore.Sight = 3
		lore.Cognition = 3
		lore.ThumpNoChasing = true
	end
end

local function applyAll()
	if not FromZoid.isEnabled("EnableNightStats") then
		return
	end
	local night = FromZoid.isNight()
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state.darknessActive then
			night = true
		end
	end
	if lastNight == night then
		return
	end
	lastNight = night
	local sprinters = FromZoid.isEnabled("NightSprinters")
	applyLore(night, sprinters)
	FromZoid.eachLoadedZombie(function(zombie)
		applyWalkType(zombie, night, sprinters)
	end)
end

local function onZombieCreate(zombie)
	if not FromZoid.isEnabled("EnableNightStats") then
		return
	end
	if not instanceof(zombie, "IsoZombie") then
		return
	end
	local night = FromZoid.isNight()
	local state = FromZoid.getState()
	if state.darknessActive then
		night = true
	end
	applyWalkType(zombie, night, FromZoid.isEnabled("NightSprinters"))
end

Events.EveryOneMinute.Add(applyAll)
Events.OnGameStart.Add(function()
	lastNight = nil
	applyAll()
end)
Events.OnZombieCreate.Add(onZombieCreate)
