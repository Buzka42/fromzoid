local fxSnap = nil
local lastPhase = nil

local function weatherFx()
	local cell = getCell()
	if cell and cell.getWeatherFX then
		return cell:getWeatherFX()
	end
	return nil
end

local function readFx()
	local clim = getClimateManager()
	local snap = {}
	if clim then
		if clim.getViewDistance then
			snap.viewDistance = clim:getViewDistance()
		end
		if clim.getNightStrength then
			snap.nightStrength = clim:getNightStrength()
		end
		if clim.getDayLightStrength then
			snap.dayLightStrength = clim:getDayLightStrength()
		end
		if clim.getDesaturation then
			snap.desaturation = clim:getDesaturation()
		end
		if clim.getAmbient then
			snap.ambient = clim:getAmbient()
		end
	end
	local fx = weatherFx()
	if fx and fx.getFogIntensity then
		snap.fog = fx:getFogIntensity()
	end
	return snap
end

local function applySnap(snap)
	if not snap then
		return
	end
	local clim = getClimateManager()
	if clim then
		if snap.viewDistance ~= nil and clim.setViewDistance then
			clim:setViewDistance(snap.viewDistance)
		end
		if snap.nightStrength ~= nil and clim.setNightStrength then
			clim:setNightStrength(snap.nightStrength)
		end
		if snap.dayLightStrength ~= nil and clim.setDayLightStrength then
			clim:setDayLightStrength(snap.dayLightStrength)
		end
		if snap.desaturation ~= nil and clim.setDesaturation then
			clim:setDesaturation(snap.desaturation)
		end
		if snap.ambient ~= nil and clim.setAmbient then
			clim:setAmbient(snap.ambient)
		end
	end
	local fx = weatherFx()
	if fx and snap.fog ~= nil and fx.setFogIntensity then
		fx:setFogIntensity(snap.fog)
	end
end

local function mixWanted()
	local player = getPlayer()
	local wanted = nil
	local function take(view, fog, night, day, desat, ambient)
		if not wanted then
			wanted = {
				view = view,
				fog = fog,
				night = night,
				day = day,
				desat = desat,
				ambient = ambient,
			}
			return
		end
		if view and (not wanted.view or view < wanted.view) then
			wanted.view = view
		end
		if fog and (not wanted.fog or fog > wanted.fog) then
			wanted.fog = fog
		end
		if night and (not wanted.night or night > wanted.night) then
			wanted.night = night
		end
		if day and (not wanted.day or day < wanted.day) then
			wanted.day = day
		end
		if desat and (not wanted.desat or desat > wanted.desat) then
			wanted.desat = desat
		end
		if ambient and (not wanted.ambient or ambient < wanted.ambient) then
			wanted.ambient = ambient
		end
	end
	local state = FromZoid.getState()
	if FromZoid.isEnabled("EnableDarkness") and state and state.darknessActive then
		take(8, 0.85, 0.92, 0.08, 0.45, 0.12)
	end
	if player and FromZoid.inTheWoods and FromZoid.inTheWoods(player) then
		take(12, 0.55, nil, nil, 0.28, nil)
	end
	return wanted
end

local function applyWanted(wanted)
	local clim = getClimateManager()
	if not clim then
		return
	end
	if wanted then
		if not fxSnap then
			fxSnap = readFx()
		end
		if wanted.view and clim.setViewDistance then
			clim:setViewDistance(wanted.view)
		end
		if wanted.night and clim.setNightStrength then
			clim:setNightStrength(wanted.night)
		end
		if wanted.day and clim.setDayLightStrength then
			clim:setDayLightStrength(wanted.day)
		end
		if wanted.desat and clim.setDesaturation then
			clim:setDesaturation(wanted.desat)
		end
		if wanted.ambient and clim.setAmbient then
			clim:setAmbient(wanted.ambient)
		end
		local fx = weatherFx()
		if fx and wanted.fog and fx.setFogIntensity then
			fx:setFogIntensity(wanted.fog)
		end
	else
		if fxSnap then
			applySnap(fxSnap)
			fxSnap = nil
		end
	end
end

local function radioLine(player, text)
	if text then
		print("[FromZoid] " .. tostring(text))
	end
end

local function tickRadioPhase()
	if not FromZoid.isEnabled("EnableDarkness") then
		return
	end
	local player = getPlayer()
	if FromZoid.playerInVehicle and FromZoid.playerInVehicle(player) then
		return
	end
	local state = FromZoid.getState()
	local phase = "none"
	if state.darknessActive then
		phase = "active"
	elseif state.darknessWarn then
		phase = "warn"
	end
	if phase == lastPhase then
		return
	end
	if phase == "warn" and lastPhase ~= "warn" then
		radioLine(player, FromZoid.text("IGUI_FromZoid_RadioWarn"))
	elseif phase == "active" and lastPhase ~= "active" then
		radioLine(player, FromZoid.text("IGUI_FromZoid_RadioStart"))
	elseif phase == "none" and lastPhase == "active" then
		print("[FromZoid] " .. FromZoid.text("IGUI_FromZoid_RadioEnd"))
	end
	lastPhase = phase
end

local function tickClimate()
	local player = getPlayer()
	if not player or not player:isAlive() then
		return
	end
	if FromZoid.playerAsleep and FromZoid.playerAsleep(player) then
		return
	end
	if FromZoid.playerInVehicle and FromZoid.playerInVehicle(player) then
		if fxSnap then
			applySnap(fxSnap)
			fxSnap = nil
		end
		return
	end
	local wanted = mixWanted()
	if not wanted and not fxSnap then
		return
	end
	applyWanted(wanted)
end

Events.OnPlayerUpdate.Add(tickClimate)
Events.EveryOneMinute.Add(tickRadioPhase)
Events.OnGameStart.Add(function()
	lastPhase = nil
	fxSnap = nil
end)
