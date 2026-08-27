local lastWhisper = 0
local lastHeard = {}
local lastDispatch = 0

local function pad2(n)
	if n < 10 then
		return "0" .. tostring(n)
	end
	return tostring(n)
end

local function genderPool(zombie)
	if zombie.isFemale and zombie:isFemale() then
		return { "Roxie", "Annie", "Zelda" }
	end
	return { "Vlad", "Miles", "Knox" }
end

local function voiceFits(zombie, name)
	if not name then
		return false
	end
	local pool = genderPool(zombie)
	for i = 1, #pool do
		if pool[i] == name then
			return true
		end
	end
	return false
end

local function clipsFor(voice)
	local clips = FromZoid.VOICE_CLIPS and FromZoid.VOICE_CLIPS[voice]
	if not clips or #clips == 0 then
		return nil
	end
	return clips
end

local function nearKind(zombie)
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return nil
	end
	local cell = getCell()
	local hasWindow = false
	local hasDoor = false
	for dx = -1, 1 do
		for dy = -1, 1 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if FromZoid.getWindowOnSquare(n) then
				hasWindow = true
			end
			if FromZoid.getDoorOnSquare(n) then
				hasDoor = true
			end
		end
	end
	if hasWindow then
		return "window"
	end
	if hasDoor then
		return "door"
	end
	return nil
end

local function voiceFor(zombie)
	local md = zombie:getModData()
	local name = md.fromzoidVoice
	if not voiceFits(zombie, name) or not clipsFor(name) then
		local pool = genderPool(zombie)
		local usable = {}
		for i = 1, #pool do
			if clipsFor(pool[i]) then
				table.insert(usable, pool[i])
			end
		end
		if #usable == 0 then
			return nil
		end
		name = usable[ZombRand(#usable) + 1]
		md.fromzoidVoice = name
	end
	return name
end

local function playVoice(zombie, soundId)
	local played = false
	pcall(function()
		local sm = getSoundManager and getSoundManager() or nil
		local x = zombie:getX()
		local y = zombie:getY()
		local z = zombie:getZ() or 0
		if sm and sm.PlayWorldSoundImpl then
			sm:PlayWorldSoundImpl(soundId, false, x, y, z, 0, 28, 1.2, false)
			played = true
			return
		end
		local sq = FromZoid.zombieSquare(zombie)
		if sm and sm.PlayWorldSound and sq then
			sm:PlayWorldSound(soundId, sq, 0, 28, 1.2, false)
			played = true
		end
	end)
	if played then
		return
	end
	pcall(function()
		local emitter = zombie.getEmitter and zombie:getEmitter() or nil
		if emitter and emitter.playSound then
			emitter:playSound(soundId)
		elseif zombie.playSound then
			zombie:playSound(soundId)
		end
	end)
end

local function walkableStand(obj)
	if not obj then
		return nil
	end
	local function usable(sq)
		if not sq then
			return false
		end
		if sq.getBuilding and sq:getBuilding() then
			return false
		end
		if FromZoid.getWindowOnSquare(sq) or FromZoid.getDoorOnSquare(sq) then
			return false
		end
		if sq.isFree and not sq:isFree(false) then
			return false
		end
		return true
	end
	local porch = FromZoid.openingPorchSquare(obj, 2)
	if usable(porch) then
		return porch
	end
	local stand = FromZoid.openingStandSquare(obj)
	if usable(stand) then
		return stand
	end
	if stand then
		local cell = getCell()
		if cell then
			for dx = -1, 1 do
				for dy = -1, 1 do
					if dx ~= 0 or dy ~= 0 then
						local n = cell:getGridSquare(stand:getX() + dx, stand:getY() + dy, stand:getZ())
						if usable(n) then
							return n
						end
					end
				end
			end
		end
	end
	return porch or stand
end

local function nearestOpening(player)
	local tsq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
	local tb = tsq and tsq:getBuilding() or nil
	local cell = getCell()
	if not tsq or not tb or not cell then
		return nil, nil, nil
	end
	local def = FromZoid.getBuildingDef(tb)
	if not def or not def.getX then
		return nil, nil, nil
	end
	local bid = FromZoid.buildingId(tb)
	local px, py, pz = tsq:getX(), tsq:getY(), tsq:getZ()
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local zTop = 1
	if def.getMaxLevel then
		local m = def:getMaxLevel()
		if m and m > zTop then
			zTop = m
		end
	end
	local bestObj, bestStand, bestKind, bestD = nil, nil, nil, nil
	for z = 0, zTop do
		for x = x1, x2 do
			for y = y1, y2 do
				local n = cell:getGridSquare(x, y, z)
				if n then
					local win = FromZoid.getWindowOnSquare(n)
					local door = FromZoid.getDoorOnSquare(n)
					local obj = win or door
					if obj then
						local stand = walkableStand(obj)
						if stand then
							local ob = n.getBuilding and n:getBuilding() or nil
							local opp = obj.getOppositeSquare and obj:getOppositeSquare() or nil
							local ob2 = opp and opp.getBuilding and opp:getBuilding() or nil
							local same = (ob and FromZoid.buildingId(ob) == bid) or (ob2 and FromZoid.buildingId(ob2) == bid)
							if same then
								local dz = (z - pz)
								local d = (x - px) * (x - px) + (y - py) * (y - py) + dz * dz * 4
								if not bestD or d < bestD then
									bestD = d
									bestObj = obj
									bestStand = stand
									bestKind = win and "window" or "door"
								end
							end
						end
					end
				end
			end
		end
	end
	return bestObj, bestStand, bestKind
end

local function speak(zombie, voice, index, line)
	if line then
		if zombie.addLineChatElement then
			zombie:addLineChatElement(line)
		elseif zombie.Say then
			zombie:Say(line)
		end
	end
	playVoice(zombie, "FromZoid_" .. voice .. "_" .. pad2(index))
end

local function atSealedHouse(zombie, building)
	if not zombie or not building then
		return false
	end
	if FromZoid.isWhisperWalker(zombie) then
		return false
	end
	local md = zombie:getModData()
	if zombie:isUseless() and not md.fromzoidHold then
		return false
	end
	local zsq = FromZoid.zombieSquare(zombie)
	local zb = zsq and zsq.getBuilding and zsq:getBuilding() or nil
	if zb and FromZoid.buildingId(zb) == FromZoid.buildingId(building) then
		return false
	end
	-- Gather tags people still walking in from across town. Distance to
	-- THIS house is what matters, or we send someone 80 tiles away.
	local d = FromZoid.distToBuildingEdge(zombie, building)
	return d ~= nil and d <= ((FromZoid.RING_MAX or 5) + 3)
end

local function fillMissingVoices(candidates)
	local function fill(pool)
		local counts = {}
		local ofPool = {}
		for i = 1, #candidates do
			local voice = candidates[i].voice
			for p = 1, #pool do
				if voice == pool[p] then
					counts[voice] = (counts[voice] or 0) + 1
					table.insert(ofPool, candidates[i])
					break
				end
			end
		end
		if #ofPool == 0 then
			return
		end
		for p = 1, #pool do
			local name = pool[p]
			if (counts[name] or 0) == 0 then
				local donor = nil
				for i = 1, #ofPool do
					local c = ofPool[i]
					if (counts[c.voice] or 0) >= 2 then
						if name ~= "Knox" or c.kind == "window" then
							donor = c
							break
						end
					end
				end
				if donor then
					counts[donor.voice] = counts[donor.voice] - 1
					counts[name] = 1
					donor.voice = name
					donor.zombie:getModData().fromzoidVoice = name
				end
			end
		end
	end
	fill({ "Vlad", "Miles", "Knox" })
	fill({ "Roxie", "Annie", "Zelda" })
end

local function pickLeastHeard(candidates)
	local bestT = nil
	for i = 1, #candidates do
		local t = lastHeard[candidates[i].voice]
		if t == nil then
			t = -1
		end
		if bestT == nil or t < bestT then
			bestT = t
		end
	end
	local tied = {}
	for i = 1, #candidates do
		local t = lastHeard[candidates[i].voice]
		if t == nil then
			t = -1
		end
		if t == bestT then
			table.insert(tied, candidates[i])
		end
	end
	return tied[ZombRand(#tied) + 1]
end

local function speakAndFinish(zombie, voice)
	local clips = clipsFor(voice)
	if not clips then
		FromZoid.finishWhisperWalk(zombie)
		return
	end
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	local idx = clips[ZombRand(#clips) + 1]
	local lines = FromZoid.VOICES and FromZoid.VOICES[voice]
	local line = lines and lines[idx] or nil
	speak(zombie, voice, idx, line)
	lastHeard[voice] = now
	lastWhisper = now
	FromZoid.finishWhisperWalk(zombie)
	local player = getPlayer()
	if player and FromZoid.isEnabled("WhispersBreakSleep") and FromZoid.playerAsleep(player) then
		FromZoid.wakePlayer(player)
	end
end

local lastSkipAt = 0
local lastSkipMsg = nil

local function whisperSkip(msg)
	if not FromZoid.isEnabled("TalismanDebug") then
		return
	end
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	if msg == lastSkipMsg and now - lastSkipAt < 20000 then
		return
	end
	lastSkipAt = now
	lastSkipMsg = msg
	print("[FromZoid] whisper: " .. tostring(msg))
end

local function findActiveWalker()
	local found = nil
	FromZoid.eachLoadedZombie(function(zombie)
		if found or not instanceof(zombie, "IsoZombie") then
			return
		end
		local md = zombie:getModData()
		if md.fromzoidWhisperUntil and FromZoid.nowMs() < md.fromzoidWhisperUntil then
			found = zombie
		end
	end)
	return found
end

local function findAnyWalker()
	local found = nil
	FromZoid.eachLoadedZombie(function(zombie)
		if found or not instanceof(zombie, "IsoZombie") then
			return
		end
		if FromZoid.isWhisperWalker(zombie) then
			found = zombie
		end
	end)
	return found
end

local function nearDest(zombie)
	if not FromZoid.whispererArrived(zombie) then
		return false
	end
	return true
end

local function tickWhisperWalk()
	local walker = findActiveWalker()
	if not walker then
		return
	end
	if not FromZoid.isNight() then
		FromZoid.clearWhisperWalk(walker)
		return
	end
	-- Only the porch they were sent to. nearKind used to fire on any window
	-- in a 3x3, so a gatherer 80 tiles away "whispered" at a stranger's house.
	if not nearDest(walker) then
		return
	end
	local voice = voiceFor(walker)
	local kind = walker:getModData().fromzoidWhisperKind or nearKind(walker)
	if voice == "Knox" and kind ~= "window" then
		FromZoid.clearWhisperWalk(walker)
		return
	end
	if voice then
		speakAndFinish(walker, voice)
	else
		FromZoid.clearWhisperWalk(walker)
	end
end

local function tryDispatch()
	if not FromZoid.isEnabled("EnableWhispers") then
		return
	end
	if not FromZoid.isNight() then
		whisperSkip("not night")
		return
	end
	if findAnyWalker() then
		return
	end
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	if now - lastWhisper < 45000 then
		return
	end
	if now - lastDispatch < 14000 then
		return
	end
	-- First line of the night always goes out. Chance only spaces the rest.
	if lastWhisper > 0 then
		local chancePct = FromZoid.getSandbox("WhisperChance", 18)
		if FromZoid.isGatheringNight and FromZoid.isGatheringNight() then
			chancePct = math.min(100, chancePct + 22)
		end
		if ZombRand(100) >= chancePct then
			whisperSkip("chance miss (" .. tostring(chancePct) .. "%)")
			return
		end
	end
	local players = FromZoid.playerList()
	if #players == 0 then
		return
	end
	local building, stand, openingKind = nil, nil, nil
	for i = 1, #players do
		local player = players[i]
		local tsq = player:getCurrentSquare()
		local tb = tsq and tsq:getBuilding() or nil
		if tb and FromZoid.isBuildingSealed(tb) then
			local _, st, kind = nearestOpening(player)
			if st and kind then
				building = tb
				stand = st
				openingKind = kind
				break
			elseif not building then
				building = tb
			end
		end
	end
	if not building then
		whisperSkip("no sealed house")
		return
	end
	if not stand or not openingKind then
		whisperSkip("no exterior opening on house")
		return
	end
	local candidates = {}
	local ringN = 0
	FromZoid.eachLoadedZombie(function(zombie)
		if not instanceof(zombie, "IsoZombie") then
			return
		end
		local md = zombie:getModData()
		if md.fromzoidLoiter or md.fromzoidGather or md.fromzoidHold then
			ringN = ringN + 1
		end
		if zombie:isUseless() and not md.fromzoidHold then
			return
		end
		if FromZoid.isWhisperWalker(zombie) then
			return
		end
		if not atSealedHouse(zombie, building) then
			return
		end
		local voice = voiceFor(zombie)
		if not voice then
			return
		end
		if voice == "Knox" and openingKind ~= "window" then
			return
		end
		table.insert(candidates, { zombie = zombie, voice = voice, kind = openingKind })
	end)
	if #candidates == 0 then
		whisperSkip("no ring candidates (tagged=" .. tostring(ringN) .. ")")
		return
	end
	fillMissingVoices(candidates)
	-- Prefer someone a few tiles off the glass so they peel out of the yard.
	-- Never pick the farthest gatherer in the cell (that was 80+ tiles away).
	local closest, mid = nil, nil
	local closestD, midD = 99999, 99999
	for i = 1, #candidates do
		local z = candidates[i].zombie
		local dx = z:getX() - (stand:getX() + 0.5)
		local dy = z:getY() - (stand:getY() + 0.5)
		local d = dx * dx + dy * dy
		if d < closestD then
			closestD = d
			closest = candidates[i]
		end
		if d >= 9 and d <= 100 and d < midD then
			midD = d
			mid = candidates[i]
		end
	end
	local pick = mid or closest
	if not pick then
		return
	end
	local pickD = mid and midD or closestD
	if FromZoid.isEnabled("TalismanDebug") then
		print("[FromZoid] whisper: walk " .. tostring(pick.voice) .. " to " .. openingKind
			.. " at " .. tostring(stand:getX()) .. "," .. tostring(stand:getY())
			.. " from " .. string.format("%.1f", math.sqrt(pickD)) .. " tiles")
	end
	FromZoid.startWhisperWalk(pick.zombie, stand, openingKind)
	lastDispatch = now
end

local function onPlayerUpdate()
	if not FromZoid.isEnabled("EnableWhispers") then
		return
	end
	if not FromZoid.realTimeGate or FromZoid.realTimeGate("whisperDispatch", 15000) then
		tryDispatch()
	end
	if FromZoid.realTimeGate and not FromZoid.realTimeGate("whisperWalk", 400) then
		return
	end
	tickWhisperWalk()
end

Events.EveryOneMinute.Add(tryDispatch)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
