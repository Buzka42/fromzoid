require "MF_ISMoodle"

local NAME = "FromZoidSanity"

MF.createMoodle(NAME)

local function valueFor(player)
	if not player or not FromZoid.isEnabled("EnableSanity") then
		return 0.5
	end
	local tier = FromZoid.sanityTier(player)
	if tier >= 3 then
		return 0.15
	end
	if tier >= 2 then
		return 0.25
	end
	return 0.5
end

local function apply(player)
	if not player then
		return
	end
	local num = 0
	if player.getPlayerNum then
		num = player:getPlayerNum()
	end
	local moodle = MF.getMoodle(NAME, num)
	if not moodle or not moodle.setValue then
		return
	end
	moodle:setValue(valueFor(player))
end

local function tickShift(isoPlayer)
	local player = isoPlayer
	if not player or not player.getModData then
		player = getPlayer()
	end
	if not player then
		return
	end
	apply(player)
	local md = player:getModData()
	local shift = md.fromzoidSanityShift
	if not shift then
		return
	end
	md.fromzoidSanityShift = nil
	pcall(function()
		local emitter = player.getEmitter and player:getEmitter() or nil
		if emitter and emitter.playSound then
			emitter:playSound("ZombieSurprised")
		end
	end)
	local num = player.getPlayerNum and player:getPlayerNum() or 0
	local moodle = MF.getMoodle(NAME, num)
	if moodle and moodle.doWiggle then
		moodle:doWiggle()
	end
end

local shiftTick = 0

Events.OnPlayerUpdate.Add(function(isoPlayer)
	shiftTick = shiftTick + 1
	if shiftTick < 15 then
		return
	end
	shiftTick = 0
	tickShift(isoPlayer)
end)

Events.OnCreatePlayer.Add(function(_, isoPlayer)
	apply(isoPlayer or getPlayer())
end)
Events.OnGameStart.Add(function()
	apply(getPlayer())
end)
