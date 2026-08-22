local lastHit = {}

local function applyStrength()
	if not FromZoid.isEnabled("UltraStrong") then
		return
	end
	if SandboxVars and SandboxVars.ZombieLore then
		SandboxVars.ZombieLore.Strength = 1
	end
	if getSandboxOptions then
		pcall(function()
			getSandboxOptions():set("ZombieLore.Strength", 1)
		end)
	end
end

local function extraDamage(player, amount)
	if not player or not player:isAlive() then
		return
	end
	if not amount or amount <= 0 then
		return
	end
	local bd = player.getBodyDamage and player:getBodyDamage() or nil
	if bd and bd.ReduceGeneralHealth then
		bd:ReduceGeneralHealth(amount)
	end
end

local function onZombieHit(attacker, target, weapon, damage)
	if not instanceof(attacker, "IsoZombie") then
		return
	end
	if not instanceof(target, "IsoPlayer") then
		return
	end
	local id = attacker:getID()
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	if lastHit[id] and (now - lastHit[id]) < 400 then
		return
	end
	lastHit[id] = now
	local amount = tonumber(damage) or 0
	if amount < 8 then
		amount = 8
	end
	if FromZoid.isEnabled("UltraStrong") then
		amount = amount + 28
	end
	extraDamage(target, amount)
end

Events.OnGameStart.Add(applyStrength)
Events.OnWeaponHitCharacter.Add(onZombieHit)
