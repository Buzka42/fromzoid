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
	if now - lastWhisper < 8000 then
		return
	end
	local chancePct = FromZoid.getSandbox("WhisperChance", 18)
	local players = FromZoid.playerList()
	if #players == 0 then
		return
	end
	FromZoid.eachLoadedZombie(function(zombie)
		if not instanceof(zombie, "IsoZombie") then
			return
		end
		if zombie:isUseless() then
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
		for i = 1, #players do
			local player = players[i]
			if zombie:DistTo(player) < 10 then
				if ZombRand(100) < chancePct then
					local clips = clipsFor(voice)
					if clips then
						local idx = clips[ZombRand(#clips) + 1]
						local lines = FromZoid.VOICES and FromZoid.VOICES[voice]
						local line = lines and lines[idx] or nil
						speak(zombie, voice, idx, line)
						lastWhisper = now
					end
					return
				end
			end
		end
	end)
end

Events.EveryOneMinute.Add(tryWhispers)
