if isClient() then
	return
end

local lastHit = {}

local function extraDamage(player)
	if not player or not player:isAlive() then
		return
	end
	pcall(function()
		local bd = player:getBodyDamage()
		if bd and bd.ReduceGeneralHealth then
			bd:ReduceGeneralHealth(18)
		end
	end)
end

local function onZombieUpdate(zombie)
	if not FromZoid.isEnabled("UltraStrong") then
		return
	end
	if not zombie or not instanceof(zombie, "IsoZombie") or not zombie:isAlive() then
		return
	end
	local attacking = false
	if zombie.isAttacking and zombie:isAttacking() then
		attacking = true
	end
	local outcome = nil
	if zombie.getAttackOutcome then
		outcome = zombie:getAttackOutcome()
	end
	if outcome ~= nil then
		local ok = (outcome == "Success") or (tostring(outcome):find("Success") ~= nil)
		if not ok then
			return
		end
		attacking = true
	end
	if not attacking then
		return
	end
	local target = zombie.getTarget and zombie:getTarget() or nil
	if not target or not instanceof(target, "IsoPlayer") then
		return
	end
	if zombie:DistTo(target) > 1.35 then
		return
	end
	local id = zombie:getID()
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	if lastHit[id] and (now - lastHit[id]) < 650 then
		return
	end
	lastHit[id] = now
	extraDamage(target)
end

Events.OnGameStart.Add(function()
	if FromZoid.isEnabled("UltraStrong") and SandboxVars and SandboxVars.ZombieLore then
		SandboxVars.ZombieLore.Strength = 1
	end
end)

Events.OnZombieUpdate.Add(onZombieUpdate)
