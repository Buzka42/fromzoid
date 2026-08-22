local lastWhisper = 0

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

local function speak(zombie, voice, index, line)
	if line then
		if zombie.addLineChatElement then
			zombie:addLineChatElement(line)
		elseif zombie.Say then
			zombie:Say(line)
		end
	end
	local soundId = "FromZoid_" .. voice .. "_" .. pad2(index)
	pcall(function()
		local emitter = zombie.getEmitter and zombie:getEmitter() or nil
		if emitter and emitter.playSound then
			emitter:playSound(soundId)
		elseif zombie.playSound then
			zombie:playSound(soundId)
		end
	end)
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
	return zombie:getModData().fromzoidHold == true
end

local function tryWhispers()
	if not FromZoid.isEnabled("EnableWhispers") then
		return
	end
	if not FromZoid.isNight() then
		local state = FromZoid.getState()
		if not (state and state.darknessActive) then
			return
		end
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
	local candidates = {}
	FromZoid.eachLoadedZombie(function(zombie)
		if not instanceof(zombie, "IsoZombie") then
			return
		end
		if zombie:isUseless() and not zombie:getModData().fromzoidHold then
			return
		end
		if not loiteringAtSealed(zombie, players) then
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
		table.insert(candidates, { zombie = zombie, voice = voice })
	end)
	if #candidates == 0 then
		return
	end
	local pick = candidates[ZombRand(#candidates) + 1]
	local clips = clipsFor(pick.voice)
	if not clips then
		return
	end
	local idx = clips[ZombRand(#clips) + 1]
	local lines = FromZoid.VOICES and FromZoid.VOICES[pick.voice]
	local line = lines and lines[idx] or nil
	if line and FromZoid.isEnabled("TheyKnowYourName") then
		local player = getPlayer()
		if player and FromZoid.sanityLevel then
			local level = FromZoid.sanityLevel(player)
			if level == "delusion" or level == "psychosis" then
				line = line .. "  " .. FromZoid.playerForename(player) .. "."
			end
		end
	end
	speak(pick.zombie, pick.voice, idx, line)
	lastWhisper = now
	local player = getPlayer()
	if player and FromZoid.isEnabled("WhispersBreakSleep") and player.isAsleep and player:isAsleep() then
		pcall(function()
			if player.setAsleep then
				player:setAsleep(false)
			end
			if player.forceAwake then
				player:forceAwake()
			end
		end)
	end
end

Events.EveryOneMinute.Add(tryWhispers)
