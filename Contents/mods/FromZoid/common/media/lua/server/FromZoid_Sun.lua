if isClient() then
	return
end

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
-- Minutes since the sun came up, or nil at night. Drives how hard we push
-- leftovers indoors: a nudge at first, a shove by mid-morning.
local dawnMinute = nil
-- Daylight drain of the talisman field: this many zombies hold a leave pass
-- at once, for this long. The pass must outlast a real walk clear of the ring
-- band or they get reclaimed mid-exit and loiter forever.
local LEAVE_SLOTS = 6
local LEAVE_MS = 30000

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
	if dawnNow then
		dawnMinute = 0
	elseif duskNow then
		dawnMinute = nil
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
		-- Do NOT mass-release the talisman field at 07:00. Freeing a dozen
		-- zombies stood two tiles from the glass, in the same tick, with the
		-- player in plain view, is the sunrise charge. They leave via the
		-- staggered leave passes in herdIndoors instead.
		if FromZoid.nearestSealedBuilding(zombie, 40) then
			return
		end
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
	-- Do NOT release the hold here. The talisman field applies in daylight
	-- too now; releasing it every tick is what handed them back to vanilla.
	if zombie:getModData().fromzoidHold then
		return
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
	-- Only break off a hunt aimed at someone SHELTERING. This used to fire on
	-- `not sameUnsealedBuilding`, which needs zombie and player inside the
	-- same building -- so with the player outdoors it was true every tick,
	-- and clearZombieHunt nils the target. That is why daytime zombies could
	-- never land a hit: their target was stripped every single frame.
	local shelteredNow = closestInfo and closestInfo.sealed and not closestInfo.invited
	if hunting and shelteredNow and not FromZoid.sameUnsealedBuilding(zombie, closest) then
		FromZoid.clearZombieHunt(zombie)
		hunting = false
	end
	-- A talisman house is never a valid target, and the person inside it is
	-- not either. CalmUntilProvoked is gated on ctx.night, so it stops
	-- suppressing aggro the instant the clock says day: at 07:00 the whole
	-- street is handed a free target through the window. Hold the line here
	-- so daylight cannot re-acquire someone stood in a sealed house.
	local sealedPlayer = closestInfo and closestInfo.sealed and not closestInfo.invited
	if sealedPlayer then
		if zombie.setTarget then
			zombie:setTarget(nil)
		end
		if hunting then
			FromZoid.clearZombieHunt(zombie)
			hunting = false
		end
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
		if closest and not sealedPlayer then
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
		if closest and not sealedPlayer and zombie.setTarget then
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
			-- Near a sealed house, enforceTalisman owns them: it walks them
			-- clear before letting them nest. Issuing a nest path here as
			-- well would route them straight back past the windows.
			local near = FromZoid.nearestSealedBuilding(zombie, 12)
			if near then
				return
			end
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
		FromZoid.pinZombieSleepPose(zombie)
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
	FromZoid.sendZombieToNest(zombie, FromZoid.allowNestTeleport(zombie))
end

local function herdIndoors()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not FromZoid.realTimeGate("herd", 1000) then
		return
	end
	if FromZoid.isClockNight() then
		dawnMinute = nil
		return
	end
	if dawnMinute then
		dawnMinute = dawnMinute + 1
	end
	-- No recorded dawn (mid-day load, or a save carried over) means we are
	-- well past it: go straight to the strongest push.
	local phase = dawnMinute or 99
	local nest = FromZoid.isEnabled("NestTeleport")
	local liveLeave = 0
	local waitingLeave = {}
	FromZoid.eachLoadedZombie(function(zombie)
		local huntUntil = zombie:getModData().fromzoidHuntUntil
		if huntUntil and FromZoid.nowMs() < huntUntil then
			FromZoid.clearZombieHunt(zombie)
		end
		local sq = FromZoid.zombieSquare(zombie)
		if FromZoid.squareIsIndoorHide(sq) then
			return
		end
		-- Inside the talisman field: queue for a leave pass rather than being
		-- released. Only LEAVE_SLOTS of them hold a live pass at once, so the
		-- yard drains steadily and everyone else stays held and cannot charge.
		-- If they fail to get clear the pass lapses and the field takes them
		-- back, so a failed exit can never become a charge.
		local near = FromZoid.nearestSealedBuilding(zombie, 12)
		if near then
			local md = zombie:getModData()
			if md.fromzoidLeaveUntil and FromZoid.nowMs() < md.fromzoidLeaveUntil then
				liveLeave = liveLeave + 1
			else
				waitingLeave[#waitingLeave + 1] = zombie
			end
			return
		end
		if zombie:getModData().fromzoidHold then
			FromZoid.releaseHold(zombie)
		end
		-- First ten minutes: drain the yard a fifth at a time. A crowd that
		-- all turns and leaves on the same tick reads like a script.
		if phase <= 10 and (FromZoid.zombieSeed(zombie) % 5) ~= (phase % 5) then
			return
		end
		if FromZoid.sendZombieToNest(zombie, nest and FromZoid.allowNestTeleport(zombie)) then
			return
		end
		-- Still outside a while after sunrise and nobody is looking: put them
		-- away rather than let them mill in daylight all day. This is
		-- offscreen-only, so bringing it forward cannot be seen happening.
		if phase > 12 and nest and FromZoid.allowVisibleTeleport(zombie) then
			local tile = FromZoid.pickNestSquare(zombie)
			if tile then
				FromZoid.teleportZombieToSquare(zombie, tile)
				FromZoid.putZombieToSleep(zombie)
				return
			end
		end
		FromZoid.walkAwayFromHouse(zombie)
	end)
	-- Top the leave queue back up to LEAVE_SLOTS. The pass has to outlast an
	-- actual walk out of the ring band: at shamble speed that is well over
	-- ten seconds, and a pass that expires mid-walk just hands them back to
	-- the field to loiter again, which is why they never left.
	local now = FromZoid.nowMs()
	for i = 1, #waitingLeave do
		if liveLeave >= LEAVE_SLOTS then
			break
		end
		waitingLeave[i]:getModData().fromzoidLeaveUntil = now + LEAVE_MS
		liveLeave = liveLeave + 1
	end
end

local function trickleOutside()
	if not FromZoid.isEnabled("EnableSunCycle") then
		return
	end
	if not FromZoid.realTimeGate("trickle", 1500) then
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
	if not FromZoid.realTimeGate("still", 2000) then
		return
	end
	-- Deep night, measured against the actual dawn/dusk rather than a fixed
	-- 22:00. Winter dusk lands around 19:00, and the hard-coded window meant
	-- The Still could never fire in the first hours of a short night.
	local tod = FromZoid.getTimeOfDayHours()
	local dawn, dusk = FromZoid.getDawnDusk()
	local deep = tod < (dawn - 1) or tod > (dusk + 1)
	if not deep then
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
end

-- Sandbox TalismanDebug turns "a lot of them stayed" into a number. Costs a
-- single option read per minute when it is off.
local function tickCensus()
	if not FromZoid.isEnabled("TalismanDebug") then
		return
	end
	if not FromZoid.realTimeGate("census", 2000) then
		return
	end
	local n = { total = 0, hold = 0, loiter = 0, gather = 0, asleep = 0, outdoor = 0, hunting = 0, porch = 0, inside = 0, walking = 0, targeting = 0, leaving = 0, stuck = 0, yard = 0, whisper = 0 }
	local now = FromZoid.nowMs()
	-- The building the player is sealed inside, if any: "porch" counts who is
	-- still pressed against it, which is the number that has to fall at dawn.
	-- Measure against the sealed HOUSE, not "the building the player happens
	-- to be standing in". Keying off the player meant stepping outside to
	-- look at the porch crowd made atwall report 0 while they were still
	-- plainly there.
	local sealedList = FromZoid.sealedBuildings()
	local watch = sealedList[1] and sealedList[1].building or nil
	FromZoid.eachLoadedZombie(function(zombie)
		local md = zombie:getModData()
		n.total = n.total + 1
		if watch then
			local d = FromZoid.distToBuildingEdge(zombie, watch)
			if d then
				local zsq = FromZoid.zombieSquare(zombie)
				local zb = zsq and zsq.getBuilding and zsq:getBuilding() or nil
				if zb and FromZoid.buildingId(zb) == FromZoid.buildingId(watch) then
					n.inside = n.inside + 1
				elseif d <= 3 then
					n.porch = n.porch + 1
				elseif d <= 10 then
					n.yard = n.yard + 1
				end
			end
		end
		if md.fromzoidWalkTo then
			n.walking = n.walking + 1
		end
		-- Vanilla has the player acquired. Near a sealed house in daylight
		-- this is the window charge; it should stay at or near zero.
		if zombie.getTarget and zombie:getTarget() then
			n.targeting = n.targeting + 1
		end
		if FromZoid.isWhisperWalker(zombie) then
			n.whisper = n.whisper + 1
		end
		if md.fromzoidHold then
			n.hold = n.hold + 1
		end
		if md.fromzoidLoiter then
			n.loiter = n.loiter + 1
		end
		if md.fromzoidLeaveUntil and now < md.fromzoidLeaveUntil then
			n.leaving = n.leaving + 1
		end
		-- Tracked an escape but has not gained ground in a while: this is the
		-- "caught aggro and just stands there" case.
		if (md.fromzoidEscapeFails or 0) >= 3 then
			n.stuck = n.stuck + 1
		end
		if md.fromzoidGather then
			n.gather = n.gather + 1
		end
		if md.fromzoidAsleep then
			n.asleep = n.asleep + 1
		end
		if md.fromzoidHuntUntil and now < md.fromzoidHuntUntil then
			n.hunting = n.hunting + 1
		end
		if not FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
			n.outdoor = n.outdoor + 1
		end
	end)
	-- One-shot: report what skin textures live zombies are actually using.
	-- Overriding M_ZedBody* changes nothing if the game is drawing them from
	-- the human skin list (MaleBody0X) instead, and only the game can say.
	if not FromZoid._skinReported then
		local seen = {}
		local names = {}
		FromZoid.eachLoadedZombie(function(zombie)
			if #names >= 8 then
				return
			end
			pcall(function()
				local hv = zombie.getHumanVisual and zombie:getHumanVisual() or nil
				local tex = hv and hv.getSkinTexture and hv:getSkinTexture() or nil
				if tex then
					tex = tostring(tex)
					if not seen[tex] then
						seen[tex] = true
						names[#names + 1] = tex
					end
				end
			end)
		end)
		if #names > 0 then
			FromZoid._skinReported = true
			print("[FromZoid] zombie skin textures in use: " .. table.concat(names, ", "))
		end
	end
	local ns = FromZoid._nestStats or {}
	local parts = {}
	for _, k in ipairs({ "pathIssued", "enRoute", "bedded", "asleep", "arriving",
		"noTile", "wouldLaunch", "gaveUp", "inSkipBuilding", "hunting", "still" }) do
		if (ns[k] or 0) > 0 then
			parts[#parts + 1] = k .. "=" .. tostring(ns[k])
		end
	end
	if #parts > 0 then
		print("[FromZoid] nest: " .. table.concat(parts, " "))
	end
	FromZoid._nestStats = {}
	print(string.format(
		"[FromZoid] %s tod=%.1f dawn+%s | loaded=%d outdoor=%d indoor=%d atwall=%d yard=%d insidesealed=%d walking=%d targeting=%d hold=%d loiter=%d leaving=%d stuck=%d gather=%d hunt=%d whisper=%d",
		FromZoid.isClockNight() and "night" or "day",
		FromZoid.getTimeOfDayHours(),
		tostring(dawnMinute),
		n.total, n.outdoor, n.asleep, n.porch, n.yard, n.inside, n.walking, n.targeting, n.hold, n.loiter, n.leaving, n.stuck, n.gather, n.hunting, n.whisper))
end

Events.EveryOneMinute.Add(processSunCycle)
Events.EveryOneMinute.Add(herdIndoors)
Events.EveryOneMinute.Add(trickleOutside)
Events.EveryOneMinute.Add(tickTheStill)
Events.EveryOneMinute.Add(tickCensus)
Events.OnGameStart.Add(function()
	lastNight = nil
	dawnMinute = nil
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
