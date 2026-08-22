if isClient() then
	return
end

local NEST_MINUTES = {}
local porchCache = {}
local porchCacheMin = -1

local function chance(percent)
	if not percent or percent <= 0 then
		return false
	end
	if percent >= 100 then
		return true
	end
	return ZombRand(10000) < (percent * 100)
end

local lastNight = nil

local function outdoorSquareNear(zombie, dist)
	dist = dist or 8
	local x = math.floor(zombie:getX()) + ZombRand(dist * 2 + 1) - dist
	local y = math.floor(zombie:getY()) + ZombRand(dist * 2 + 1) - dist
	local sq = getCell():getGridSquare(x, y, 0)
	if sq and not sq:getBuilding() and sq.isFree and sq:isFree(false) then
		return sq
	end
	return nil
end

local function sendIndoors(zombie, teleport)
	local sq = FromZoid.zombieSquare(zombie)
	if sq and sq:getBuilding() then
		if FromZoid.shouldKeepZombiesOut(sq:getBuilding()) then
			return false
		end
		FromZoid.putZombieToSleep(zombie)
		return true
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
	local dest = outdoorSquareNear(zombie, 12)
	if dest then
		FromZoid.pathZombieToSquare(zombie, dest)
	end
end

function FromZoid.cachedPorchSquare(building, x, y)
	if not building then
		return nil
	end
	local id = FromZoid.buildingId(building) or "_"
	local gt = getGameTime()
	local minute = 0
	if gt and gt.getWorldAgeHours then
		minute = math.floor(gt:getWorldAgeHours() * 60)
	end
	if porchCacheMin ~= minute then
		porchCache = {}
		porchCacheMin = minute
	end
	if porchCache[id] ~= nil then
		if porchCache[id] == false then
			return nil
		end
		return porchCache[id]
	end
	local porch = FromZoid.nearestPorchSquare(building, x, y)
	porchCache[id] = porch or false
	return porch
end

local function processSunCycle()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	local night = FromZoid.isNight()
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state.darknessActive then
			night = true
		end
	end
	local nest = FromZoid.isEnabled("NestTeleport")
	local duskNow = lastNight == false and night == true
	lastNight = night
	FromZoid.eachLoadedZombie(function(zombie)
		local id
		if zombie.getOnlineID and zombie:getOnlineID() then
			id = zombie:getOnlineID()
		else
			id = zombie:getID()
		end
		if night then
			NEST_MINUTES[id] = nil
			FromZoid.wakeZombieBody(zombie)
			if duskNow and chance(FromZoid.getSandbox("LureChance", 80)) then
				lureOutside(zombie)
			end
			return
		end
		local sq = FromZoid.zombieSquare(zombie)
		local building = sq and sq:getBuilding() or nil
		if building and FromZoid.shouldKeepZombiesOut(building) then
			FromZoid.wakeZombieBody(zombie)
			if FromZoid.isZombieOffscreen(zombie) then
				local dest = outdoorSquareNear(zombie, 16)
				if dest then
					FromZoid.teleportZombieToSquare(zombie, dest)
				end
			else
				lureOutside(zombie)
			end
			NEST_MINUTES[id] = nil
			return
		end
		if building then
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
	if not wakeBuilding or not chance(8) then
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	local building = sq and sq:getBuilding()
	if not building or not building.getRooms then
		return
	end
	local rooms = building:getRooms()
	if not rooms then
		return
	end
	local woken = 0
	for r = 0, rooms:size() - 1 do
		if woken >= 8 then
			return
		end
		local room = rooms:get(r)
		local squares = room and room.getSquares and room:getSquares()
		if squares then
			for s = 0, squares:size() - 1 do
				if woken >= 8 then
					return
				end
				local tile = squares:get(s)
				local movers = tile and tile:getMovingObjects()
				if movers then
					for m = 0, movers:size() - 1 do
						local other = movers:get(m)
						if instanceof(other, "IsoZombie") and other:isUseless() then
							FromZoid.wakeZombieBody(other)
							woken = woken + 1
							if woken >= 8 then
								return
							end
						end
					end
				end
			end
		end
	end
end

function FromZoid.onDayZombieUpdate(zombie, ctx, sliced)
	if not sliced then
		return
	end
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	if ctx.night then
		return
	end
	if not zombie:isUseless() then
		return
	end
	local infos = ctx.infos
	if not infos then
		return
	end
	for i = 1, #infos do
		local info = infos[i]
		local d2 = FromZoid.dist2ToPlayer(zombie, info.player)
		if d2 > 36 then
			-- too far to wake
		elseif d2 < 2 and chance(FromZoid.getSandbox("HitWakeChance", 75)) then
			wakeZombie(zombie, true)
			return
		else
			local sneak = info.player:isSneaking()
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
Events.OnGameStart.Add(function()
	lastNight = nil
	porchCache = {}
	porchCacheMin = -1
end)
Events.OnWeaponHitCharacter.Add(onHit)
