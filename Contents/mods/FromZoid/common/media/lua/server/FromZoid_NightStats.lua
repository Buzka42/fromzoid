if isClient() then
	return
end

local lastNight = nil

local function huntUntil(zombie)
	local untilMs = zombie:getModData().fromzoidHuntUntil
	if not untilMs then
		return false
	end
	return FromZoid.nowMs() < untilMs
end

local function applyWalkType(zombie, night, sprinters, hunting)
	if not zombie then
		return
	end
	if zombie.setCrawler then
		zombie:setCrawler(false)
	end
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(true)
		end)
	end
	if night then
		if zombie.setWalkType then
			if sprinters and hunting then
				zombie:setWalkType("sprint1")
			else
				zombie:setWalkType("")
			end
		end
	else
		if zombie.setWalkType then
			zombie:setWalkType("slow1")
		end
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
	if zombie.setSpeedTypeFromWalkType then
		pcall(function()
			zombie:setSpeedTypeFromWalkType()
		end)
	end
end

function FromZoid.markZombieHunting(zombie, ms)
	if not zombie then
		return
	end
	zombie:getModData().fromzoidHuntUntil = FromZoid.nowMs() + (ms or 25000)
	local night = FromZoid.isNight()
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state and state.darknessActive then
			night = true
		end
	end
	applyWalkType(zombie, night, FromZoid.isEnabled("NightSprinters"), true)
end

function FromZoid.onCalmZombieUpdate(zombie, ctx, sliced)
	if not sliced then
		return
	end
	if not FromZoid.isEnabled("EnableNightStats") then
		return
	end
	if not ctx.night then
		return
	end
	if not FromZoid.isEnabled("CalmUntilProvoked") then
		return
	end
	if zombie:getModData().fromzoidHold then
		return
	end
	if huntUntil(zombie) then
		return
	end
	local infos = ctx.infos
	if not infos then
		return
	end
	local provoke = ctx.gunshot and FromZoid.isEnabled("GunshotWakesStreet")
	if not provoke then
		for i = 1, #infos do
			if infos[i].sprinting and FromZoid.dist2ToPlayer(zombie, infos[i].player) <= 400 then
				provoke = true
				break
			end
		end
	else
		local near = false
		for i = 1, #infos do
			if FromZoid.dist2ToPlayer(zombie, infos[i].player) <= 400 then
				near = true
				break
			end
		end
		provoke = near
	end
	if provoke then
		FromZoid.markZombieHunting(zombie, 25000)
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
	local calm = FromZoid.isEnabled("CalmUntilProvoked")
	FromZoid.eachLoadedZombie(function(zombie)
		local hunting = (not calm) or huntUntil(zombie)
		applyWalkType(zombie, night, sprinters, hunting)
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
	local hunting = not FromZoid.isEnabled("CalmUntilProvoked")
	applyWalkType(zombie, night, FromZoid.isEnabled("NightSprinters"), hunting)
end

local function onHit(attacker, target, weapon, damage)
	if instanceof(attacker, "IsoPlayer") and instanceof(target, "IsoZombie") then
		FromZoid.markZombieHunting(target, 25000)
	end
	if instanceof(attacker, "IsoPlayer") and weapon and weapon.isRanged and weapon:isRanged() then
		FromZoid.markGunshot()
	end
end

local function onSwing(character, weapon)
	if not character or not weapon then
		return
	end
	if instanceof(character, "IsoPlayer") and weapon.isRanged and weapon:isRanged() then
		FromZoid.markGunshot()
	end
end

Events.EveryOneMinute.Add(applyAll)
Events.OnGameStart.Add(function()
	lastNight = nil
	applyAll()
end)
Events.OnZombieCreate.Add(onZombieCreate)
Events.OnWeaponHitCharacter.Add(onHit)
if Events.OnWeaponSwing then
	Events.OnWeaponSwing.Add(onSwing)
end
