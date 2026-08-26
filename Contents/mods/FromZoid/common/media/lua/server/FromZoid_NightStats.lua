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

local function captureLore(lore)
	local state = FromZoid.getState()
	if state.loreCaptured then
		return state
	end
	state.loreSight = lore.Sight
	state.loreHearing = lore.Hearing
	state.loreToughness = lore.Toughness
	state.loreArmor = lore.ZombiesArmorFactor
	state.loreDefense = lore.ZombiesMaxDefense
	state.loreCaptured = true
	return state
end

-- Only hand a value to getSandboxOptions when it actually changed. This ran
-- every in-game minute for the whole session otherwise.
local pushed = {}

local function pushLore(key, value)
	if value == nil or pushed[key] == value then
		return
	end
	pushed[key] = value
	if not getSandboxOptions then
		return
	end
	pcall(function()
		getSandboxOptions():set("ZombieLore." .. key, value)
	end)
end

local function applyToughness(lore)
	if not lore then
		return
	end
	local state = captureLore(lore)
	lore.Toughness = 1
	local armor = tonumber(state.loreArmor) or 1
	lore.ZombiesArmorFactor = math.min(4, armor * 2)
	if lore.ZombiesMaxDefense ~= nil then
		local def = tonumber(state.loreDefense) or 70
		lore.ZombiesMaxDefense = math.min(95, def * 1.25)
	end
	pushLore("Toughness", lore.Toughness)
	pushLore("ZombiesArmorFactor", lore.ZombiesArmorFactor)
end

local function applySenses(night)
	local lore = SandboxVars and SandboxVars.ZombieLore
	if not lore then
		return
	end
	local state = captureLore(lore)
	applyToughness(lore)
	if night then
		lore.Sight = state.loreSight
		lore.Hearing = state.loreHearing
	else
		-- 3 = Poor. 4/5 are random mixes, not "lowest".
		lore.Sight = 3
		lore.Hearing = 3
	end
	pushLore("Sight", lore.Sight)
	pushLore("Hearing", lore.Hearing)
end

-- Put the world back the way we found it if the option gets switched off
-- mid-session, so a disabled mod stops nerfing day sight and doubling armor.
local function restoreLore()
	local lore = SandboxVars and SandboxVars.ZombieLore
	local state = FromZoid.getState()
	if not lore or not state.loreCaptured then
		return
	end
	lore.Sight = state.loreSight
	lore.Hearing = state.loreHearing
	lore.Toughness = state.loreToughness
	lore.ZombiesArmorFactor = state.loreArmor
	if state.loreDefense ~= nil then
		lore.ZombiesMaxDefense = state.loreDefense
	end
	pushLore("Sight", lore.Sight)
	pushLore("Hearing", lore.Hearing)
	pushLore("Toughness", lore.Toughness)
	pushLore("ZombiesArmorFactor", lore.ZombiesArmorFactor)
end

local function applyWalkType(zombie, night, sprinters, hunting)
	if not zombie then
		return
	end
	if zombie:getModData().fromzoidAsleep then
		return
	end
	-- Loiterers own their own gait. They sprint the approach and shamble
	-- once they reach the yard; letting the sprint pass reclaim them puts
	-- them back to grinding into the wall at full speed.
	if zombie:getModData().fromzoidLoiter then
		return
	end
	local want = ""
	if sprinters then
		want = "sprint1"
	end
	local cur = nil
	if zombie.getWalkType then
		cur = zombie:getWalkType()
	end
	if cur == want then
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
	if zombie.setWalkType then
		zombie:setWalkType(want)
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
	applyWalkType(zombie, FromZoid.isNight(), FromZoid.isEnabled("NightSprinters"), true)
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
	if zombie:getModData().fromzoidHold or zombie:getModData().fromzoidLoiter then
		return
	end
	if huntUntil(zombie) then
		return
	end
	if zombie:getModData().fromzoidHuntUntil then
		zombie:getModData().fromzoidHuntUntil = nil
		applyWalkType(zombie, true, FromZoid.isEnabled("NightSprinters"), false)
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
		for i = 1, #infos do
			local info = infos[i]
			if info.sealed and not info.invited and FromZoid.dist2ToPlayer(zombie, info.player) <= 400 then
				return
			end
		end
		FromZoid.markZombieHunting(zombie, 25000)
	end
end

local function applyAll()
	-- The enable check has to come first. Senses and toughness used to be
	-- applied before it, so turning the option off still left day sight
	-- nerfed and armor doubled.
	if not FromZoid.isEnabled("EnableNightStats") then
		restoreLore()
		return
	end
	local night = FromZoid.isNight()
	applySenses(night)
	if lastNight == night then
		return
	end
	if not FromZoid.realTimeGate("nightstats", 1000) then
		return
	end
	lastNight = night
	local sprinters = FromZoid.isEnabled("NightSprinters")
	local calm = FromZoid.isEnabled("CalmUntilProvoked")
	FromZoid.eachLoadedZombie(function(zombie)
		if zombie:getModData().fromzoidHold or zombie:getModData().fromzoidLoiter then
			return
		end
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
	local hunting = not FromZoid.isEnabled("CalmUntilProvoked")
	applyWalkType(zombie, FromZoid.isNight(), FromZoid.isEnabled("NightSprinters"), hunting)
end

local function onHit(attacker, target, weapon, damage)
	if not FromZoid.isEnabled("EnableNightStats") then
		return
	end
	if instanceof(attacker, "IsoPlayer") and instanceof(target, "IsoZombie") then
		FromZoid.markZombieHunting(target, 25000)
	end
	if instanceof(attacker, "IsoPlayer") and weapon and weapon.isRanged and weapon:isRanged() then
		FromZoid.markGunshot(attacker)
	end
end

local function onSwing(character, weapon)
	if not FromZoid.isEnabled("EnableNightStats") then
		return
	end
	if not character or not weapon then
		return
	end
	if instanceof(character, "IsoPlayer") and weapon.isRanged and weapon:isRanged() then
		FromZoid.markGunshot(character)
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
