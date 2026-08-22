local function applyFx(active)
	local clim = getClimateManager()
	if not clim then
		return
	end
	if active then
		if clim.setViewDistance then
			clim:setViewDistance(8)
		end
		if clim.setNightStrength then
			clim:setNightStrength(0.92)
		end
		if clim.setDayLightStrength then
			clim:setDayLightStrength(0.08)
		end
		if clim.setDesaturation then
			clim:setDesaturation(0.45)
		end
		if clim.setAmbient then
			clim:setAmbient(0.12)
		end
		local cell = getCell()
		if cell and cell.getWeatherFX then
			local fx = cell:getWeatherFX()
			if fx and fx.setFogIntensity then
				fx:setFogIntensity(0.85)
			end
		end
	else
		if clim.setDesaturation then
			clim:setDesaturation(0)
		end
		local cell = getCell()
		if cell and cell.getWeatherFX then
			local fx = cell:getWeatherFX()
			if fx and fx.setFogIntensity then
				fx:setFogIntensity(0)
			end
		end
	end
end

local function radioLine(player, text)
	if not player then
		return
	end
	HaloTextHelper.addBadText(player, text)
	if player.addLineChatElement then
		player:addLineChatElement(text)
	end
end

local lastPhase = nil

local function tickDarknessClient()
	if not FromZoid.isEnabled("EnableDarkness") then
		return
	end
	local state = FromZoid.getState()
	local phase = "none"
	if state.darknessActive then
		phase = "active"
	elseif state.darknessWarn then
		phase = "warn"
	end
	applyFx(phase == "active")
	if phase == lastPhase then
		return
	end
	local player = getPlayer()
	if phase == "warn" and lastPhase ~= "warn" then
		radioLine(player, getText("IGUI_FromZoid_RadioWarn"))
	elseif phase == "active" and lastPhase ~= "active" then
		radioLine(player, getText("IGUI_FromZoid_RadioStart"))
	elseif phase == "none" and lastPhase == "active" then
		if player then
			HaloTextHelper.addGoodText(player, getText("IGUI_FromZoid_RadioEnd"))
		end
	end
	lastPhase = phase
end

Events.EveryOneMinute.Add(tickDarknessClient)
Events.OnGameStart.Add(function()
	lastPhase = nil
	tickDarknessClient()
end)
