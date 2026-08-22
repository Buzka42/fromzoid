FromZoid.WHISPER_LINES = {
	"It's cold out here...",
	"I can hear you breathing.",
	"Please. I live here.",
	"Just open it a little.",
	"Don't leave me with them.",
	"I know you're awake.",
	"Let me in. I'm not like the others.",
	"The sun's gone. You don't have to hide.",
	"I brought food. I swear.",
	"You're going to die in there.",
	"I saw your light.",
	"It's me. You know me.",
	"The door isn't locked for me. Only for you.",
	"I can wait all night.",
	"Please don't look out the window.",
}

local lastWhisper = 0

local function speak(zombie, line)
	if not zombie then
		return
	end
	if zombie.addLineChatElement then
		zombie:addLineChatElement(line)
	elseif zombie.Say then
		zombie:Say(line)
	end
end

local function nearOpening(zombie)
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return false
	end
	if FromZoid.squareHasOpening(sq) then
		return true
	end
	local cell = getCell()
	for dx = -1, 1 do
		for dy = -1, 1 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if FromZoid.squareHasOpening(n) then
				return true
			end
		end
	end
	return false
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
		for i = 1, #players do
			local player = players[i]
			if zombie:DistTo(player) < 10 and nearOpening(zombie) then
				if ZombRand(100) < chancePct then
					speak(zombie, FromZoid.WHISPER_LINES[ZombRand(#FromZoid.WHISPER_LINES) + 1])
					lastWhisper = now
					return
				end
			end
		end
	end)
end

Events.EveryOneMinute.Add(tryWhispers)
