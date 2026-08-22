if isClient() then
	return
end

local NEST_MINUTES = {}

local function chance(percent)
	if not percent or percent <= 0 then
		return false
	end
	if percent >= 100 then
		return true
	end
	return ZombRand(10000) < (percent * 100)
end

local function outdoorSquareNear(zombie, dist)
	dist = dist or 8
	local x = math.floor(zombie:getX()) + ZombRand(dist * 2 + 1) - dist
	local y = math.floor(zombie:getY()) + ZombRand(dist * 2 + 1) - dist
	local sq = getCell():getGridSquare(x, y, 0)
	if sq and not sq:getBuilding() and sq:isFree(false) then
		return sq
	end
	return getCell():getGridSquare(x, y, 0)
end

local function sendIndoors(zombie, teleport)
	local sq = FromZoid.zombieSquare(zombie)
	if sq and sq:getBuilding() then
		if not FromZoid.isBuildingSealed(sq:getBuilding()) then
			FromZoid.putZombieToSleep(zombie)
			return true
		end
	end
	local tile = FromZoid.pickNestSquare(zombie)
	if not tile then
		return false
	end
	if teleport then
		FromZoid.teleportZombieToSquare(zombie, tile)
		FromZoid.putZombieToSleep(zombie)
		return true
	end
	FromZoid.pathZombieToSquare(zombie, tile)
	return false
end

local function lureOutside(zombie)
	FromZoid.wakeZombieBody(zombie)
	if chance(FromZoid.getSandbox("LureChance", 80)) then
		local dest = outdoorSquareNear(zombie, 12)
		if dest then
			FromZoid.pathZombieToSquare(zombie, dest)
		end
	end
end

local function processSunCycle()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	local night = FromZoid.isNight()
	local nest = FromZoid.isEnabled("NestTeleport")
	FromZoid.eachLoadedZombie(function(zombie)
		local id
		if zombie.getOnlineID and zombie:getOnlineID() then
			id = zombie:getOnlineID()
		else
			id = zombie:getID()
		end
		if night then
			NEST_MINUTES[id] = nil
			if zombie:isUseless() then
				lureOutside(zombie)
			else
				FromZoid.wakeZombieBody(zombie)
			end
			return
		end
		local sq = FromZoid.zombieSquare(zombie)
		local building = sq and sq:getBuilding() or nil
		if building and not FromZoid.isBuildingSealed(building) then
			FromZoid.putZombieToSleep(zombie)
			NEST_MINUTES[id] = nil
			return
		end
		FromZoid.wakeZombieBody(zombie)
		local indoors = sendIndoors(zombie, false)
		NEST_MINUTES[id] = (NEST_MINUTES[id] or 0) + 1
		if nest and not indoors then
			if FromZoid.isZombieOffscreen(zombie) then
				sendIndoors(zombie, true)
				NEST_MINUTES[id] = nil
			elseif NEST_MINUTES[id] >= 4 then
				sendIndoors(zombie, true)
				NEST_MINUTES[id] = nil
			end
		end
	end)
end

local function wakeZombie(zombie, wakeBuilding)
	if not zombie then
		return
	end
	if not zombie:isUseless() then
		return
	end
	FromZoid.wakeZombieBody(zombie)
	if wakeBuilding and chance(8) then
		local sq = FromZoid.zombieSquare(zombie)
		local building = sq and sq:getBuilding()
		if building and building.getRooms then
			local rooms = building:getRooms()
			if rooms then
				for r = 0, rooms:size() - 1 do
					local room = rooms:get(r)
					local squares = room and room.getSquares and room:getSquares()
					if squares then
						for s = 0, squares:size() - 1 do
							local tile = squares:get(s)
							local movers = tile and tile:getMovingObjects()
							if movers then
								for m = 0, movers:size() - 1 do
									local other = movers:get(m)
									if instanceof(other, "IsoZombie") and other:isUseless() then
										FromZoid.wakeZombieBody(other)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

local function onZombieUpdate(zombie)
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not zombie or not instanceof(zombie, "IsoZombie") or not zombie:isAlive() then
		return
	end
	if FromZoid.isNight() then
		return
	end
	if not zombie:isUseless() then
		return
	end
	local players = FromZoid.playerList()
	for i = 1, #players do
		local player = players[i]
		local dist = zombie:DistTo(player)
		if dist < 1.4 and chance(FromZoid.getSandbox("HitWakeChance", 75)) then
			wakeZombie(zombie, true)
			return
		end
		if dist < 6 then
			local sneak = player:isSneaking()
			local pct = sneak and FromZoid.getSandbox("SneakWakeChance", 1) or FromZoid.getSandbox("StepWakeChance", 12)
			if chance(pct / 30) then
				wakeZombie(zombie, sneak == false)
				return
			end
		end
	end
end

local function onHit(attacker, target, weapon, damage)
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not instanceof(target, "IsoZombie") then
		return
	end
	if FromZoid.isNight() then
		return
	end
	if chance(FromZoid.getSandbox("HitWakeChance", 75)) then
		wakeZombie(target, true)
	end
end

Events.EveryOneMinute.Add(processSunCycle)
Events.OnZombieUpdate.Add(onZombieUpdate)
Events.OnWeaponHitCharacter.Add(onHit)
