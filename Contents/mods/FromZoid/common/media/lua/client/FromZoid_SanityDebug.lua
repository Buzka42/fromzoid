pcall(require, "Chat/ISChat")

local function allowed()
	if getDebug and getDebug() then
		return true
	end
	if not isClient() then
		return true
	end
	local player = getPlayer()
	if player and player.getAccessLevel then
		local access = player:getAccessLevel()
		if access and access ~= "" and access ~= "None" and access ~= "none" then
			return true
		end
	end
	return false
end

local function tell(player, text, bad)
	if not text then
		return
	end
	print("[FromZoid] " .. tostring(text))
end

local function statusLine(player)
	local strain = math.floor((FromZoid.getStrain(player) or 0) + 0.5)
	return FromZoid.text("IGUI_FromZoid_DebugStatus", tostring(strain), FromZoid.sanityLevel(player))
end

local function applyStrain(player, value)
	FromZoid.setStrain(player, value)
	tell(player, statusLine(player))
end

local function splitPrefix(cmd)
	if string.sub(cmd, 1, 9) == "/fromzoid" then
		local c = string.sub(cmd, 10, 10)
		if c == "" or c == " " then
			return string.gsub(string.sub(cmd, 10), "^%s+", "")
		end
	end
	if string.sub(cmd, 1, 3) == "/fz" then
		local c = string.sub(cmd, 4, 4)
		if c == "" or c == " " then
			return string.gsub(string.sub(cmd, 4), "^%s+", "")
		end
	end
	return nil
end

local function runDebug(player, arg)
	arg = tostring(arg or "")
	arg = string.lower((string.gsub(string.gsub(arg, "^%s+", ""), "%s+$", "")))
	arg = string.gsub(arg, "^/+", "")
	arg = string.gsub(arg, "^fromzoid%s*", "")
	arg = string.gsub(arg, "^fz%s*", "")
	if arg == "" or arg == "help" or arg == "?" then
		tell(player, FromZoid.text("IGUI_FromZoid_DebugHelp"))
		if player then
			tell(player, statusLine(player))
		end
		return true
	end
	if not player then
		print("[FromZoid] no player")
		return true
	end
	if arg == "status" or arg == "info" then
		tell(player, statusLine(player))
		return true
	end
	if arg == "sane" or arg == "sanity" or arg == "0" or arg == "1" then
		applyStrain(player, 0)
		return true
	end
	if arg == "delusion" or arg == "2" then
		applyStrain(player, FromZoid.strainForTier(2))
		return true
	end
	if arg == "psychosis" or arg == "3" then
		applyStrain(player, FromZoid.strainForTier(3))
		return true
	end
	if arg == "fx" or arg == "event" then
		if FromZoid.forceSanityFx then
			FromZoid.forceSanityFx(player)
		end
		print("[FromZoid] hallucination")
		return true
	end
	local sign, num = string.match(arg, "^([%+%-])(%d+)$")
	if sign and num then
		local delta = tonumber(num) or 0
		if sign == "-" then
			delta = -delta
		end
		applyStrain(player, FromZoid.getStrain(player) + delta)
		return true
	end
	local absolute = tonumber(arg)
	if absolute then
		applyStrain(player, absolute)
		return true
	end
	tell(player, FromZoid.text("IGUI_FromZoid_DebugHelp"), true)
	return true
end

function FromZoid.debug(what)
	return runDebug(getPlayer(), what)
end

function FromZoid.handleDebugChat(raw)
	if not raw then
		return false
	end
	local cmd = string.lower((string.gsub(string.gsub(raw, "^%s+", ""), "%s+$", "")))
	local arg = splitPrefix(cmd)
	if arg == nil then
		return false
	end
	local player = getPlayer()
	if not player then
		return true
	end
	if not allowed() then
		tell(player, FromZoid.text("IGUI_FromZoid_DebugDenied"), true)
		return true
	end
	runDebug(player, arg)
	return true
end

local hooked = false

local function hookChat()
	if hooked or not ISChat or not ISChat.onCommandEntered then
		return
	end
	hooked = true
	local original = ISChat.onCommandEntered
	function ISChat:onCommandEntered()
		local raw = ""
		if ISChat.instance and ISChat.instance.textEntry then
			raw = ISChat.instance.textEntry:getText() or ""
		end
		if FromZoid.handleDebugChat(raw) then
			local chat = ISChat.instance
			if chat then
				chat:unfocus()
				if chat.textEntry then
					chat.textEntry:setText("")
				end
				chat.timerTextEntry = 20
			end
			if doKeyPress then
				doKeyPress(false)
			end
			return
		end
		return original(self)
	end
end

local function onFillWorld(playerIndex, context, worldobjects, test)
	if test then
		return
	end
	if isClient() and not (getDebug and getDebug()) then
		return
	end
	local player = getSpecificPlayer(playerIndex)
	if not player then
		return
	end
	local option = context:addOption(FromZoid.text("ContextMenu_FromZoid_Debug"), worldobjects, nil)
	local sub = ISContextMenu:getNew(context)
	context:addSubMenu(option, sub)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugStatus"), player, function(p)
		tell(p, statusLine(p))
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugSane"), player, function(p)
		applyStrain(p, 0)
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugDelusion"), player, function(p)
		applyStrain(p, FromZoid.strainForTier(2))
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugPsychosis"), player, function(p)
		applyStrain(p, FromZoid.strainForTier(3))
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugPlus"), player, function(p)
		applyStrain(p, FromZoid.getStrain(p) + 10)
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugMinus"), player, function(p)
		applyStrain(p, FromZoid.getStrain(p) - 10)
	end)
	sub:addOption(FromZoid.text("ContextMenu_FromZoid_DebugFx"), player, function(p)
		if FromZoid.forceSanityFx then
			FromZoid.forceSanityFx(p)
		end
		print("[FromZoid] hallucination")
	end)
end

Events.OnGameStart.Add(hookChat)
Events.OnCreatePlayer.Add(hookChat)
Events.OnFillWorldObjectContextMenu.Add(onFillWorld)

print("[FromZoid] Lua console: FromZoid.debug(\"psychosis\")  or  FromZoid.debug(\"delusion\")  or  FromZoid.debug(\"sane\")")
