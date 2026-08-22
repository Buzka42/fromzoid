if isClient() then
	return
end

local function worldHours()
	local gt = getGameTime()
	if gt and gt.getWorldAgeHours then
		return gt:getWorldAgeHours()
	end
	if gt then
		return (gt:getNightsSurvived() * 24) + gt:getHour()
	end
	return 0
end

local function setPower(on)
	local world = getWorld()
	if world and world.setHydroPowerOn then
		pcall(function()
			world:setHydroPowerOn(on)
		end)
	end
end

local function getElecShut()
	if getSandboxOptions then
		local ok, value = pcall(function()
			return getSandboxOptions():getOptionByName("ElecShutModifier"):getValue()
		end)
		if ok and value ~= nil then
			return value
		end
	end
	return SandboxVars and SandboxVars.ElecShutModifier
end

local function setElecShut(value)
	if value == nil then
		return
	end
	if SandboxVars then
		SandboxVars.ElecShutModifier = value
	end
	if getSandboxOptions then
		pcall(function()
			getSandboxOptions():set("ElecShutModifier", value)
		end)
	end
end

local function powerShouldBeOn(saved)
	if saved == nil then
		return true
	end
	if saved < 0 then
		return true
	end
	local gt = getGameTime()
	local nights = gt and gt:getNightsSurvived() or 0
	return nights < saved
end

local function startBlackout(state)
	if state.savedElecShutModifier == nil then
		state.savedElecShutModifier = getElecShut()
	end
	setElecShut(-1)
	setPower(false)
end

local function endBlackout(state)
	local saved = state.savedElecShutModifier
	if saved ~= nil then
		setElecShut(saved)
	end
	setPower(powerShouldBeOn(saved))
	state.savedElecShutModifier = nil
end

local function scheduleOrTick()
	if not FromZoid.isEnabled("EnableDarkness") then
		return
	end
	local state = FromZoid.getState()
	local hours = worldHours()
	if state.darknessActive then
		if hours >= (state.darknessEnd or 0) then
			state.darknessActive = false
			state.darknessWarn = false
			state.darknessEnd = nil
			state.darknessStart = nil
			endBlackout(state)
		else
			startBlackout(state)
		end
		return
	end
	if state.darknessStart and hours >= state.darknessStart then
		state.darknessActive = true
		state.darknessWarn = false
		startBlackout(state)
		return
	end
	if state.darknessStart and hours >= (state.darknessStart - 6) then
		state.darknessWarn = true
	end
	local gt = getGameTime()
	if not gt then
		return
	end
	local hour = gt:getHour()
	local day = gt:getNightsSurvived()
	if state.rolledDay == day then
		return
	end
	if hour ~= 7 then
		return
	end
	state.rolledDay = day
	if state.darknessStart then
		return
	end
	local chance = FromZoid.getSandbox("DarknessDayChance", 8)
	if ZombRand(100) >= chance then
		return
	end
	state.savedElecShutModifier = getElecShut()
	local delay = 10 + ZombRand(8)
	local duration = 24 + ZombRand(49)
	state.darknessStart = hours + delay
	state.darknessEnd = state.darknessStart + duration
	state.darknessWarn = delay <= 6
end

Events.EveryHours.Add(scheduleOrTick)
Events.OnGameStart.Add(scheduleOrTick)
