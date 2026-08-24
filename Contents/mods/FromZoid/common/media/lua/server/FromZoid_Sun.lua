if isClient() then
	return
end

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
	local cell = getCell()
	if not cell or not zombie then
		return nil
	end
	for _ = 1, 8 do
		local x = math.floor(zombie:getX()) + ZombRand(dist * 2 + 1) - dist
		local y = math.floor(zombie:getY()) + ZombRand(dist * 2 + 1) - dist
		local sq = cell:getGridSquare(x, y, 0)
		if sq and not sq:getBuilding() and sq.isFree and sq:isFree(false) then
			return sq
		end
	end
	return nil
end

local function sendIndoors(zombie, teleport)
	return FromZoid.sendZombieToNest(zombie, teleport)
end

local function lureOutside(zombie)
	FromZoid.wakeZombieBody(zombie)
	if FromZoid.walkAwayFromHouse(zombie) then
		return
	end
	local dest = outdoorSquareNear(zombie, 40)
	if not dest then
		dest = outdoorSquareNear(zombie, 24)
	end
	if not dest then
		return
	end
	if FromZoid.allowVisibleTeleport(zombie) then
		FromZoid.teleportZombieToSquare(zombie, dest)
		return
	end
	if not FromZoid.pathWouldLaunch(zombie, dest) then
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
	local night = FromZoid.isClockNight()
	local nest = FromZoid.isEnabled("NestTeleport")
	local duskNow = lastNight == false and night == true
	local dawnNow = lastNight == true and night == false
	if lastNight == nil then
		lastNight = night
		dawnNow = not night
		duskNow = false
	else
		lastNight = night
	end
	if not duskNow and not dawnNow then
		return
	end
	FromZoid.eachLoadedZombie(function(zombie)
		if night then
			if zombie:getModData().fromzoidHold then
				FromZoid.releaseHold(zombie)
			end
			FromZoid.wakeZombieBody(zombie)
			return
		end
		FromZoid.clearZombieHunt(zombie)
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		local sq = FromZoid.zombieSquare(zombie)
		local building = sq and sq:getBuilding() or nil
		if building and FromZoid.shouldKeepZombiesOut(building) then
			FromZoid.wakeZombieBody(zombie)
			if FromZoid.allowVisibleTeleport(zombie) then
				local dest = outdoorSquareNear(zombie, 16)
				if dest then
					FromZoid.teleportZombieToSquare(zombie, dest)
				end
			else
				lureOutside(zombie)
			end
			return
		end
		if FromZoid.squareIsIndoorHide(sq) then
			FromZoid.putZombieToSleep(zombie)
			return
		end
		FromZoid.wakeZombieBody(zombie)
		local indoors = sendIndoors(zombie, false)
		if nest and not indoors then
			indoors = sendIndoors(zombie, FromZoid.allowNestTeleport(zombie))
		end
		if not indoors then
			if not FromZoid.walkAwayFromHouse(zombie) then
				lureOutside(zombie)
			end
		end
	end)
end

local function wakeSameRoom(zombie, cap)
	cap = cap or 8
	local sq = FromZoid.zombieSquare(zombie)
	local room = sq and sq.getRoom and sq:getRoom() or nil
	if not room or not room.getSquares then
		return
	end
	local squares = room:getSquares()
	if not squares then
		return
	end
	local woken = 0
	for s = 0, squares:size() - 1 do
		if woken >= cap then
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
					if woken >= cap then
						return
					end
				end
			end
		end
	end
end

local function wakeZombie(zombie, wakeBuilding)
	if not zombie then
		return
	end
	if zombie:isUseless() then
		FromZoid.wakeZombieBody(zombie)
	end
	if not wakeBuilding then
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
							if FromZoid.markZombieHunting then
								FromZoid.markZombieHunting(other, 60000)
							end
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
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not zombie or not zombie:isAlive() then
		return
	end
	local sunDown = FromZoid.isClockNight()
	if sunDown then
		if not zombie:getModData().fromzoidHold and zombie:isUseless() then
			FromZoid.wakeZombieBody(zombie)
		end
		return
	end
	if zombie:getModData().fromzoidHold then
		FromZoid.releaseHold(zombie)
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	local infos = ctx and ctx.infos or nil
	local d2 = 99999
	local closest = nil
	local closestInfo = nil
	if infos then
		for i = 1, #infos do
			local p = infos[i].player
			local n = FromZoid.dist2ToPlayer(zombie, p)
			if n < d2 then
				d2 = n
				closest = p
				closestInfo = infos[i]
			end
		end
	end
	local hunting = md.fromzoidHuntUntil and now < md.fromzoidHuntUntil
	if hunting and not FromZoid.sameUnsealedBuilding(zombie, closest) then
		FromZoid.clearZombieHunt(zombie)
		hunting = false
	end
	local loud = false
	if ctx and ctx.loud then
		local dx = zombie:getX() - ctx.loud.x
		local dy = zombie:getY() - ctx.loud.y
		if (dx * dx + dy * dy) <= (ctx.loud.r2 or 2500) then
			loud = true
		end
	elseif ctx and ctx.gunshot and d2 <= 2500 then
		loud = true
	end
	if loud and closestInfo and closestInfo.sealed and not closestInfo.invited then
		loud = false
	end
	if loud then
		FromZoid.wakeZombieBody(zombie)
		if closest then
			if zombie.setTarget then
				zombie:setTarget(closest)
			end
			if FromZoid.markZombieHunting then
				FromZoid.markZombieHunting(zombie, 60000)
			else
				md.fromzoidHuntUntil = now + 60000
			end
		end
		return
	end
	if hunting then
		if zombie:isUseless() then
			FromZoid.wakeZombieBody(zombie)
		end
		if closest and zombie.setTarget then
			zombie:setTarget(closest)
		end
		return
	end
	local sq = FromZoid.zombieSquare(zombie)
	if not FromZoid.squareIsIndoorHide(sq) then
		if zombie:isUseless() then
			FromZoid.wakeZombieBody(zombie)
		end
		if sliced then
			local nested = FromZoid.sendZombieToNest(zombie, FromZoid.allowNestTeleport(zombie))
			if not nested then
				if not FromZoid.walkAwayFromHouse(zombie) then
					lureOutside(zombie)
				end
			end
		end
		return
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	if md.fromzoidAsleep and zombie:isUseless() then
		FromZoid.stripLaunchPoses(zombie)
		return
	end
	FromZoid.putZombieToSleep(zombie)
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
	FromZoid.wakeZombieBody(target)
	if FromZoid.markZombieHunting then
		FromZoid.markZombieHunting(target, 60000)
	else
		target:getModData().fromzoidHuntUntil = FromZoid.nowMs() + 60000
	end
	if attacker and attacker.getX then
		if target.setTarget then
			target:setTarget(attacker)
		end
	end
	wakeZombie(target, true)
end

local function nestDayCreate(zombie)
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not zombie or not instanceof(zombie, "IsoZombie") then
		return
	end
	if FromZoid.isClockNight() then
		return
	end
	zombie:getModData().fromzoidDayNest = true
	FromZoid.sendZombieToNest(zombie, FromZoid.allowNestTeleport(zombie))
end

local function herdIndoors()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if FromZoid.isClockNight() then
		return
	end
	local nest = FromZoid.isEnabled("NestTeleport")
	FromZoid.eachLoadedZombie(function(zombie)
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		local huntUntil = zombie:getModData().fromzoidHuntUntil
		if huntUntil and FromZoid.nowMs() < huntUntil then
			FromZoid.clearZombieHunt(zombie)
		end
		local sq = FromZoid.zombieSquare(zombie)
		if FromZoid.squareIsIndoorHide(sq) then
			return
		end
		local nested = FromZoid.sendZombieToNest(zombie, nest and FromZoid.allowNestTeleport(zombie))
		if not nested then
			FromZoid.walkAwayFromHouse(zombie)
		end
	end)
end

local function trickleOutside()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not FromZoid.isClockNight() then
		return
	end
	local lure = tonumber(FromZoid.getSandbox("LureChance", 80)) or 80
	if lure <= 0 then
		return
	end
	local pct = math.max(3, math.floor(lure * 0.08))
	FromZoid.eachLoadedZombie(function(zombie)
		if zombie:getModData().fromzoidHold then
			return
		end
		if zombie:getModData().fromzoidStillUntil then
			return
		end
		local sq = FromZoid.zombieSquare(zombie)
		if not FromZoid.squareIsIndoorHide(sq) then
			return
		end
		if not chance(pct) then
			return
		end
		lureOutside(zombie)
	end)
end

local function playKnock(square)
	if not square then
		return
	end
	pcall(function()
		local sm = getSoundManager and getSoundManager() or nil
		local x = square:getX() + 0.5
		local y = square:getY() + 0.5
		local z = square:getZ() or 0
		if sm and sm.PlayWorldSoundImpl then
			sm:PlayWorldSoundImpl("DoorIsLocked", false, x, y, z, 0, 18, 1.1, false)
			return
		end
		if sm and sm.PlayWorldSound then
			sm:PlayWorldSound("DoorIsLocked", square, 0, 18, 1.1, false)
		end
	end)
end

local function tickTheStill()
	if not FromZoid.isClockNight() then
		return
	end
	local tod = FromZoid.getTimeOfDayHours()
	if tod > 5 and tod < 22 then
		return
	end
	local state = FromZoid.getState()
	local gt = getGameTime()
	local nights = gt and gt.getNightsSurvived and gt:getNightsSurvived() or 0
	if state.stillNight == nights then
		return
	end
	if ZombRand(100) >= 16 then
		return
	end
	local players = FromZoid.playerList()
	local player = nil
	local building = nil
	for i = 1, #players do
		local p = players[i]
		local sq = p.getCurrentSquare and p:getCurrentSquare() or nil
		local b = sq and sq:getBuilding() or nil
		if b then
			player = p
			building = b
			break
		end
	end
	if not player or not building then
		return
	end
	local nearby = {}
	FromZoid.eachLoadedZombie(function(zombie)
		if zombie:getModData().fromzoidHuntUntil and FromZoid.nowMs() < zombie:getModData().fromzoidHuntUntil then
			return
		end
		if zombie:isUseless() and FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
			return
		end
		if FromZoid.dist2ToPlayer(zombie, player) > 324 then
			return
		end
		table.insert(nearby, zombie)
	end)
	if #nearby < 3 then
		return
	end
	state.stillNight = nights
	local untilMs = FromZoid.nowMs() + 9000
	for i = 1, #nearby do
		local zombie = nearby[i]
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		zombie:getModData().fromzoidStillUntil = untilMs
		FromZoid.applyStillPose(zombie, player)
	end
	playKnock(player:getCurrentSquare())
	if player.addLineChatElement then
		player:addLineChatElement(FromZoid.text("IGUI_FromZoid_TheStill"))
	end
end

Events.EveryOneMinute.Add(processSunCycle)
Events.EveryOneMinute.Add(herdIndoors)
Events.EveryOneMinute.Add(trickleOutside)
Events.EveryOneMinute.Add(tickTheStill)
Events.OnGameStart.Add(function()
	lastNight = nil
	porchCache = {}
	porchCacheMin = -1
end)
Events.OnWeaponHitCharacter.Add(onHit)
Events.OnZombieCreate.Add(nestDayCreate)
if Events.OnWorldSound then
	Events.OnWorldSound.Add(function(x, y, z, radius, volume)
		if not FromZoid.isEnabled("EnableSunCycle") then
			return
		end
		if FromZoid.isClockNight() then
			return
		end
		if type(x) ~= "number" then
			return
		end
		radius = tonumber(radius) or 0
		volume = tonumber(volume) or 0
		if radius < 20 and volume < 20 then
			return
		end
		FromZoid.markLoudSound(x, y, z or 0, math.max(radius, 20))
	end)
end
