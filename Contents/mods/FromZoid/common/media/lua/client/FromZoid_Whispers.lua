local lastWhisper = 0
local lastHeard = {}

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

local function loiteringAtSealed(zombie, players)
	local zsq = FromZoid.zombieSquare(zombie)
	local zb = zsq and zsq:getBuilding() or nil
	for i = 1, #players do
		local player = players[i]
		if zombie:DistTo(player) >= 12 then
			-- too far
		else
			local tsq = player:getCurrentSquare()
			local tb = tsq and tsq:getBuilding() or nil
			if tb and FromZoid.isBuildingSealed(tb) then
				if zb and FromZoid.buildingId(zb) == FromZoid.buildingId(tb) then
					-- inside the sealed house, not loitering
				else
					return true
				end
			end
		end
	end
	return false
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

local function tryWhispers()
	if not FromZoid.isEnabled("EnableWhispers") then
		return
	end
	if not FromZoid.isNight() then
		return
	end
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	if now - lastWhisper < 45000 then
		return
	end
	local chancePct = FromZoid.getSandbox("WhisperChance", 18)
	if FromZoid.isGatheringNight and FromZoid.isGatheringNight() then
		chancePct = math.min(100, chancePct + 22)
	end
	if ZombRand(100) >= chancePct then
		return
	end
	local players = FromZoid.playerList()
	if #players == 0 then
		return
	end
	local sealedPlayers = {}
	for i = 1, #players do
		local player = players[i]
		local tsq = player:getCurrentSquare()
		local tb = tsq and tsq:getBuilding() or nil
		if tb and FromZoid.isBuildingSealed(tb) then
			table.insert(sealedPlayers, player)
		end
	end
	if #sealedPlayers == 0 then
		return
	end
	local candidates = {}
	FromZoid.eachLoadedZombie(function(zombie)
		if not instanceof(zombie, "IsoZombie") then
			return
		end
		if zombie:isUseless() and not zombie:getModData().fromzoidHold then
			return
		end
		if not loiteringAtSealed(zombie, sealedPlayers) then
			return
		end
		local kind = nearKind(zombie)
		if not kind then
			return
		end
		local voice = voiceFor(zombie)
		if not voice then
			return
		end
		if voice == "Knox" and kind ~= "window" then
			return
		end
		table.insert(candidates, { zombie = zombie, voice = voice, kind = kind })
	end)
	if #candidates == 0 then
		return
	end
	fillMissingVoices(candidates)
	local pick = pickLeastHeard(candidates)
	local clips = clipsFor(pick.voice)
	if not clips then
		return
	end
	local idx = clips[ZombRand(#clips) + 1]
	local lines = FromZoid.VOICES and FromZoid.VOICES[pick.voice]
	local line = lines and lines[idx] or nil
	speak(pick.zombie, pick.voice, idx, line)
	lastHeard[pick.voice] = now
	lastWhisper = now
	local player = getPlayer()
	if player and FromZoid.isEnabled("WhispersBreakSleep") and FromZoid.playerAsleep(player) then
		FromZoid.wakePlayer(player)
	end
end

Events.EveryOneMinute.Add(tryWhispers)
