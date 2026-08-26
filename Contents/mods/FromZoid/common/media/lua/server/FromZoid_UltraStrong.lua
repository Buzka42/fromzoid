-- Superhuman lore plus extra wounds. OnWeaponHitCharacter never fires when a
-- night person lands a hit -- it is a player-swing event -- so the old extra
-- damage was dead code. Hits are detected from AttackOutcome on the existing
-- OnZombieUpdate, and OnPlayerGetDamage is a second path for the same blow.

local lastStrength = nil
local capturedStrength = nil

local PARTS = {
	"UpperArm_L",
	"UpperArm_R",
	"ForeArm_L",
	"ForeArm_R",
	"Hand_L",
	"Hand_R",
	"UpperLeg_L",
	"UpperLeg_R",
	"LowerLeg_L",
	"LowerLeg_R",
}

local function bodyPart(name)
	if not BodyPartType then
		return nil
	end
	return BodyPartType[name]
end

local function applyStrength()
	local lore = SandboxVars and SandboxVars.ZombieLore
	if not lore then
		return
	end
	if capturedStrength == nil then
		capturedStrength = lore.Strength
	end
	if not FromZoid.isEnabled("UltraStrong") then
		if lastStrength ~= nil and capturedStrength ~= nil then
			lore.Strength = capturedStrength
			if getSandboxOptions then
				pcall(function()
					getSandboxOptions():set("ZombieLore.Strength", capturedStrength)
				end)
			end
			lastStrength = nil
		end
		return
	end
	-- 1 = Superhuman. Existing zombies read lore at spawn, so this also has
	-- to stay pushed or a mid-session toggle does nothing.
	if lastStrength == 1 then
		return
	end
	lastStrength = 1
	lore.Strength = 1
	if getSandboxOptions then
		pcall(function()
			getSandboxOptions():set("ZombieLore.Strength", 1)
		end)
	end
end

local function woundPart(bd, name, amount)
	local part = bodyPart(name)
	if not part or not bd.AddDamage then
		return
	end
	pcall(function()
		bd:AddDamage(part, amount)
		if bd.getBodyPart then
			local bp = bd:getBodyPart(part)
			if bp and bp.setBleedingTime and bp.getBleedingTime then
				local bleed = bp:getBleedingTime() or 0
				if bleed < 3 then
					bp:setBleedingTime(3)
				end
			end
		end
	end)
end

function FromZoid.applyUltraStrongHit(player, zombie)
	if not player or not player:isAlive() then
		return
	end
	local now = FromZoid.nowMs()
	local pmd = player:getModData()
	if pmd.fromzoidUltraHitAt and (now - pmd.fromzoidUltraHitAt) < 450 then
		return
	end
	pmd.fromzoidUltraHitAt = now
	local bd = player.getBodyDamage and player:getBodyDamage() or nil
	if not bd then
		return
	end
	-- Vanilla already applied the scratch/bite. Extra is tuned so an
	-- unarmored player drops in three or four landed hits (health is 100).
	-- A second AddRandomDamageFromZombie would be another full vanilla blow
	-- and make it a two-hit kill.
	if bd.ReduceGeneralHealth then
		pcall(function()
			bd:ReduceGeneralHealth(18)
		end)
	end
	woundPart(bd, PARTS[1 + ZombRand(#PARTS)], 10)
end

function FromZoid.onUltraStrongUpdate(zombie)
	if not FromZoid.isEnabled("UltraStrong") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	if zombie:isUseless() then
		return
	end
	local target = zombie.getTarget and zombie:getTarget() or nil
	if not target or not instanceof(target, "IsoPlayer") or not target:isAlive() then
		return
	end
	local outcome = ""
	if zombie.getVariableString then
		outcome = zombie:getVariableString("AttackOutcome") or ""
	end
	local md = zombie:getModData()
	if outcome == md.fromzoidAttackOut then
		return
	end
	md.fromzoidAttackOut = outcome
	if outcome ~= "success" then
		return
	end
	local reaction = ""
	if target.getHitReaction then
		reaction = target:getHitReaction() or ""
	end
	if reaction == "" then
		local d = 99
		if zombie.DistTo then
			d = zombie:DistTo(target)
		end
		if d > 1.7 then
			return
		end
	end
	FromZoid.applyUltraStrongHit(target, zombie)
end

local function onPlayerDamage(character, damageType, damage)
	if not FromZoid.isEnabled("UltraStrong") then
		return
	end
	if damageType ~= "WEAPONHIT" then
		return
	end
	if not character or not instanceof(character, "IsoPlayer") then
		return
	end
	if not character:isAlive() then
		return
	end
	-- WEAPONHIT also fires for unrelated weapon damage. Only boost a blow
	-- that has a night person in grabbing range.
	local cell = getCell()
	local list = cell and cell.getZombieList and cell:getZombieList() or nil
	if not list then
		return
	end
	local zombie = nil
	for i = 0, list:size() - 1 do
		local z = list:get(i)
		if z and z:isAlive() and z.DistTo and z:DistTo(character) <= 1.8 then
			zombie = z
			break
		end
	end
	if not zombie then
		return
	end
	FromZoid.applyUltraStrongHit(character, zombie)
end

Events.OnGameStart.Add(function()
	lastStrength = nil
	applyStrength()
end)
Events.EveryOneMinute.Add(function()
	if not FromZoid.realTimeGate("ultrastrong", 1000) then
		return
	end
	applyStrength()
end)
if Events.OnPlayerGetDamage then
	Events.OnPlayerGetDamage.Add(onPlayerDamage)
end
