local lastEvent = 0

local function playQuiet(player, sound)
	if not player then
		return
	end
	pcall(function()
		local emitter = player.getEmitter and player:getEmitter() or nil
		if emitter and emitter.playSound then
			emitter:playSound(sound)
		elseif player.playSound then
			player:playSound(sound)
		end
	end)
end

local function namedLine(player, key)
	local name = FromZoid.playerForename(player)
	local text = getText(key, name)
	if not text or text == "" or text == key then
		text = getText(key)
	end
	text = tostring(text or key)
	text = (string.gsub(text, "{name}", name))
	return text
end

local function sayLine(player, text)
	if not player or not text then
		return
	end
	text = tostring(text)
	pcall(function()
		HaloTextHelper.addBadText(player, text)
	end)
	if player.addLineChatElement then
		player:addLineChatElement(text)
	end
end

local function findDevice(player)
	local sq = player:getCurrentSquare()
	local cell = getCell()
	if not sq or not cell then
		return nil
	end
	for dx = -6, 6 do
		for dy = -6, 6 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if n and n.getObjects then
				local objs = n:getObjects()
				if objs then
					for i = 0, objs:size() - 1 do
						local obj = objs:get(i)
						if obj and (instanceof(obj, "IsoRadio") or instanceof(obj, "IsoTelevision") or (obj.getDeviceData and obj:getDeviceData())) then
							return obj
						end
					end
				end
			end
		end
	end
	return nil
end

local function turnOnDevice(obj)
	if not obj then
		return
	end
	pcall(function()
		local dd = obj.getDeviceData and obj:getDeviceData() or nil
		if dd and dd.setIsTurnedOn then
			dd:setIsTurnedOn(true)
		end
		if obj.AddDeviceText then
			local line = namedLine(getPlayer(), "IGUI_FromZoid_NameBroadcast")
			obj:AddDeviceText(line, 0.8, 0.8, 0.85, 1, "radio", 40)
		end
	end)
end

local function delusionEvent(player)
	local roll = ZombRand(6)
	if roll == 0 then
		local dev = findDevice(player)
		turnOnDevice(dev)
		sayLine(player, namedLine(player, "IGUI_FromZoid_NameBroadcast"))
		playQuiet(player, "RadioButton")
	elseif roll == 1 then
		sayLine(player, namedLine(player, "IGUI_FromZoid_TreesKnow"))
		playQuiet(player, "ZombieVoiceMaleHungry")
	elseif roll == 2 then
		playQuiet(player, "ZombieSurprised")
	elseif roll == 3 then
		sayLine(player, getText("IGUI_FromZoid_EmptyFootsteps"))
	elseif roll == 4 then
		sayLine(player, getText("IGUI_FromZoid_CharmTicks"))
		playQuiet(player, "DoorIsLocked")
	else
		sayLine(player, namedLine(player, "IGUI_FromZoid_GlassName"))
	end
end

local function psychosisEvent(player)
	local roll = ZombRand(5)
	if roll == 0 then
		sayLine(player, getText("IGUI_FromZoid_EmptyKnock"))
		playQuiet(player, "DoorIsLocked")
	elseif roll == 1 then
		sayLine(player, getText("IGUI_FromZoid_FalseCrowd"))
		playQuiet(player, "ZombieVoiceMaleHungry")
	elseif roll == 2 then
		sayLine(player, namedLine(player, "IGUI_FromZoid_HouseSpeaks"))
	elseif roll == 3 then
		playQuiet(player, "ZombieSurprised")
		sayLine(player, getText("IGUI_FromZoid_NoSourceScream"))
	else
		sayLine(player, getText("IGUI_FromZoid_SomeoneInside"))
	end
end

local function tickSanityFx()
	local player = getPlayer()
	if not player or not player:isAlive() then
		return
	end
	if not FromZoid.isEnabled("EnableSanity") then
		return
	end
	local now = FromZoid.nowMs()
	local level = FromZoid.sanityLevel(player)
	if FromZoid.inTheWoods(player) then
		if ZombRand(100) < 22 then
			sayLine(player, namedLine(player, "IGUI_FromZoid_WoodsCall"))
			playQuiet(player, "ZombieVoiceMaleHungry")
		end
	end
	if level == "delusion" and FromZoid.isEnabled("EnableDelusions") then
		if now - lastEvent < 90000 then
			return
		end
		if ZombRand(100) < 28 then
			delusionEvent(player)
			lastEvent = now
		end
	elseif level == "psychosis" and FromZoid.isEnabled("EnablePsychosis") then
		if now - lastEvent < 50000 then
			return
		end
		if ZombRand(100) < 55 then
			psychosisEvent(player)
			lastEvent = now
		end
	end
end

Events.EveryOneMinute.Add(tickSanityFx)
Events.OnGameStart.Add(function()
	lastEvent = 0
end)
