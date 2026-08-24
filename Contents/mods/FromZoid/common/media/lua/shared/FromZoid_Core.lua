FromZoid = FromZoid or {}

FromZoid.ITEM_TALISMAN = "FromZoid.Talisman"
FromZoid.MD_STATE = "FromZoidState"
FromZoid.MD_TALISMANS = "FromZoidTalismans"
FromZoid.MD_SQUARES = "FromZoidSquares"
FromZoid.MD_CLUSTERS = "FromZoidClusters"

FromZoid.RESIDENTIAL = {
	bedroom = true,
	kitchen = true,
	livingroom = true,
	living = true,
	bathroom = true,
	hall = true,
	dining = true,
	diningroom = true,
	kidsbedroom = true,
}

function FromZoid.getSandbox(key, default)
	local page = SandboxVars and SandboxVars.FromZoid
	if not page then
		return default
	end
	local value = page[key]
	if value == nil then
		return default
	end
	return value
end

function FromZoid.isEnabled(key)
	local value = FromZoid.getSandbox(key, true)
	if value == true or value == 1 or value == 2 then
		return true
	end
	if value == false or value == 0 then
		return false
	end
	return not not value
end

FromZoid.TEXT = {
	IGUI_FromZoid_RadioWarn = "A weak radio voice: something is coming with the dark. Stay inside. Do not open the door.",
	IGUI_FromZoid_RadioStart = "The broadcast dies in static. The town goes black.",
	IGUI_FromZoid_RadioEnd = "The hiss on the radio fades. Morning might hold.",
	IGUI_FromZoid_TalismanHung = "The talisman hangs on the door. This house is sealed.",
	IGUI_FromZoid_TalismanRemoved = "The talisman comes down. The house is just a house.",
	IGUI_FromZoid_NeedBuilding = "Hang the talisman on a door of the house you want sealed.",
	IGUI_FromZoid_AlreadySealed = "A talisman is already hanging on a door of this house.",
	IGUI_FromZoid_NeedTalisman = "You need a talisman in your inventory.",
	IGUI_FromZoid_TalismanRefreshed = "The charm drinks the herbs. The house holds.",
	IGUI_FromZoid_NeedHerb = "You need sage or dried herbs to refresh the charm.",
	IGUI_FromZoid_NameBroadcast = "A dead channel: we are still looking for %1.",
	IGUI_FromZoid_TreesKnow = "The trees say %1. No mouth. No body.",
	IGUI_FromZoid_EmptyFootsteps = "Footsteps on a floor you are not standing on. Then nothing.",
	IGUI_FromZoid_CharmTicks = "The hanging charm ticks against the door. Nobody touched it.",
	IGUI_FromZoid_GlassName = "The window mouthing %1. Only glass.",
	IGUI_FromZoid_EmptyKnock = "Three knocks. The porch is empty.",
	IGUI_FromZoid_TheStill = "They all stop at once. Every face turns toward the house.",
	IGUI_FromZoid_FalseCrowd = "A crowd in the street. When you look, the street is a street.",
	IGUI_FromZoid_HouseSpeaks = "The house says %1 from a room with no one in it.",
	IGUI_FromZoid_NoSourceScream = "A scream with no throat behind it.",
	IGUI_FromZoid_SomeoneInside = "Someone is in the house. The rooms disagree.",
	IGUI_FromZoid_WoodsCall = "Farther in, %1. The trees are patient.",
	IGUI_FromZoid_ShiftDelusion = "The names start sticking.",
	IGUI_FromZoid_ShiftPsychosis = "The rooms are lying.",
	IGUI_FromZoid_ShiftSane = "The house is a house again.",
	IGUI_FromZoid_LightFlicker = "The bulb dies, then thinks better of it.",
	IGUI_FromZoid_DebugHelp = "/fromzoid sane | delusion | psychosis | +10 | 75 | status | fx",
	IGUI_FromZoid_DebugStatus = "Strain %1 (%2)",
	IGUI_FromZoid_DebugDenied = "Sanity debug is off for this character.",
	IGUI_FromZoid_DebugFx = "A false thing happens.",
	ContextMenu_FromZoid_HangTalisman = "Hang Talisman",
	ContextMenu_FromZoid_TakeTalisman = "Take Down Talisman",
	ContextMenu_FromZoid_RefreshTalisman = "Refresh Talisman",
	ContextMenu_FromZoid_Debug = "FromZoid sanity",
	ContextMenu_FromZoid_DebugStatus = "Sanity status",
	ContextMenu_FromZoid_DebugSane = "Set sane",
	ContextMenu_FromZoid_DebugDelusion = "Set delusion",
	ContextMenu_FromZoid_DebugPsychosis = "Set psychosis",
	ContextMenu_FromZoid_DebugPlus = "Strain +10",
	ContextMenu_FromZoid_DebugMinus = "Strain -10",
	ContextMenu_FromZoid_DebugFx = "Force a hallucination",
	Moodles_FromZoidSanity_Bad_lvl2 = "Delusion",
	Moodles_FromZoidSanity_Bad_desc_lvl2 = "The world has learned your name. Radios, glass, and trees repeat it when nobody is there.",
	Moodles_FromZoidSanity_Bad_lvl3 = "Psychosis",
	Moodles_FromZoidSanity_Bad_desc_lvl3 = "The rooms lie. Sleep will not hold. The dark has a mouth.",
	Moodles_FromZoidSanity_Bad_lvl2 = "Delusion",
	Moodles_FromZoidSanity_Bad_desc_lvl2 = "The world has learned your name. Radios, glass, and trees repeat it when nobody is there.",
	Moodles_FromZoidSanity_Bad_lvl3 = "Psychosis",
	Moodles_FromZoidSanity_Bad_desc_lvl3 = "The rooms lie. Sleep will not hold. The dark has a mouth.",
}

function FromZoid.text(key, a1, a2)
	local t = nil
	if getText then
		local ok, result = pcall(getText, key, a1, a2)
		if ok then
			t = result
		end
	end
	if not t or t == "" or t == key then
		t = FromZoid.TEXT[key] or key
	end
	if a1 ~= nil then
		t = string.gsub(t, "%%1", tostring(a1))
	end
	if a2 ~= nil then
		t = string.gsub(t, "%%2", tostring(a2))
	end
	return t
end

function FromZoid.getState()
	return ModData.getOrCreate(FromZoid.MD_STATE)
end

function FromZoid.getTalismanData()
	return ModData.getOrCreate(FromZoid.MD_TALISMANS)
end

function FromZoid.getSquareData()
	return ModData.getOrCreate(FromZoid.MD_SQUARES)
end

function FromZoid.getTimeOfDayHours()
	local gt = getGameTime()
	if not gt then
		return 12
	end
	if gt.getTimeOfDay then
		return gt:getTimeOfDay()
	end
	return gt:getHour() + (gt:getMinutes() / 60)
end

function FromZoid.nowMs()
	if getTimestampMs then
		return getTimestampMs()
	end
	return (os.time() * 1000)
end

function FromZoid.getDawnDusk()
	local now = FromZoid.nowMs()
	if FromZoid._dawnDusk and FromZoid._dawnDuskAt and (now - FromZoid._dawnDuskAt) < 1000 then
		return FromZoid._dawnDusk[1], FromZoid._dawnDusk[2]
	end
	local dawn = 6
	local dusk = 21
	local ok, season = pcall(function()
		return getClimateManager():getSeason()
	end)
	if ok and season then
		if season.getDawn then
			dawn = season:getDawn()
		end
		if season.getDusk then
			dusk = season:getDusk()
		end
	end
	local tod = 12
	local gt = getGameTime()
	if gt and gt.getTimeOfDay then
		tod = gt:getTimeOfDay()
	end
	if dawn <= 1.5 and dusk <= 1.5 and tod > 2 then
		dawn = dawn * 24
		dusk = dusk * 24
	end
	FromZoid._dawnDusk = { dawn, dusk }
	FromZoid._dawnDuskAt = now
	return dawn, dusk
end

function FromZoid.isNight()
	local now = FromZoid.nowMs()
	if FromZoid._nightAt and (now - FromZoid._nightAt) < 1000 then
		return FromZoid._night
	end
	local tod = FromZoid.getTimeOfDayHours()
	local dawn, dusk = FromZoid.getDawnDusk()
	local night = tod < dawn or tod > dusk
	FromZoid._clockNight = night
	if not night and FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state and state.darknessActive then
			night = true
		end
	end
	FromZoid._night = night
	FromZoid._nightAt = now
	return FromZoid._night
end

function FromZoid.isClockNight()
	FromZoid.isNight()
	return FromZoid._clockNight and true or false
end

function FromZoid.isDay()
	return not FromZoid.isClockNight()
end

function FromZoid.buildingIdFromDef(def)
	if not def then
		return nil
	end
	if def.getID then
		local id = def:getID()
		if id ~= nil then
			return "b" .. tostring(id)
		end
	end
	local x = def.getX and def:getX() or 0
	local y = def.getY and def:getY() or 0
	local x2 = def.getX2 and def:getX2() or x
	local y2 = def.getY2 and def:getY2() or y
	return string.format("%d_%d_%d_%d", x, y, x2, y2)
end

function FromZoid.buildingId(building)
	if not building then
		return nil
	end
	if instanceof(building, "BuildingDef") then
		return FromZoid.buildingIdFromDef(building)
	end
	if building.getDef then
		return FromZoid.buildingIdFromDef(building:getDef())
	end
	if building.getID then
		return "iso" .. tostring(building:getID())
	end
	return nil
end

function FromZoid.buildingFromSquare(square)
	if not square then
		return nil
	end
	local building = square.getBuilding and square:getBuilding() or nil
	if building then
		return building
	end
	local room = square.getRoom and square:getRoom() or nil
	if room and room.getBuilding then
		return room:getBuilding()
	end
	return nil
end

function FromZoid.isBuildingSealed(building)
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	local data = FromZoid.getTalismanData()
	local entry = data[id]
	return entry ~= nil and entry.sealed == true
end

function FromZoid.squareHasOpening(square)
	if not square then
		return false
	end
	local objects = square:getObjects()
	if not objects then
		return false
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoDoor") or instanceof(obj, "IsoWindow") then
			return true
		end
	end
	return false
end

function FromZoid.openingIsExterior(obj)
	if not obj then
		return false
	end
	if obj.isExterior then
		local ok, ext = pcall(function()
			return obj:isExterior()
		end)
		if ok and ext then
			return true
		end
	end
	local square = obj.getSquare and obj:getSquare() or nil
	local opp = obj.getOppositeSquare and obj:getOppositeSquare() or nil
	if not opp and square then
		local cell = getCell()
		if cell then
			local x, y, z = square:getX(), square:getY(), square:getZ()
			if obj.getNorth and obj:getNorth() then
				opp = cell:getGridSquare(x, y - 1, z) or cell:getGridSquare(x, y + 1, z)
			else
				opp = cell:getGridSquare(x - 1, y, z) or cell:getGridSquare(x + 1, y, z)
			end
		end
	end
	local r1 = square and square.getRoom and square:getRoom() or nil
	local r2 = opp and opp.getRoom and opp:getRoom() or nil
	if r1 and not r2 then
		return true
	end
	if r2 and not r1 then
		return true
	end
	local b1 = square and square.getBuilding and square:getBuilding() or nil
	local b2 = opp and opp.getBuilding and opp:getBuilding() or nil
	if r1 and r2 then
		local rb1 = r1.getBuilding and r1:getBuilding() or b1
		local rb2 = r2.getBuilding and r2:getBuilding() or b2
		if rb1 and rb2 and FromZoid.buildingId(rb1) ~= FromZoid.buildingId(rb2) then
			return true
		end
		return false
	end
	if b1 and not b2 then
		return true
	end
	if b2 and not b1 then
		return true
	end
	return false
end

function FromZoid.openingIsOpen(obj)
	if not obj then
		return false
	end
	if obj.isBarricaded and obj:isBarricaded() then
		return false
	end
	if instanceof(obj, "IsoWindow") then
		if obj.isSmashed and obj:isSmashed() then
			return false
		end
		if obj.isGlassRemoved and obj:isGlassRemoved() then
			return false
		end
	end
	if obj.IsOpen then
		return obj:IsOpen() and true or false
	end
	if obj.isOpen then
		return obj:isOpen() and true or false
	end
	return false
end

function FromZoid.squareHasOpenInvitation(square)
	if not square then
		return false
	end
	local objects = square:getObjects()
	if not objects then
		return false
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if obj and FromZoid.openingIsOpen(obj) and FromZoid.openingIsExterior(obj) then
			if instanceof(obj, "IsoDoor") or instanceof(obj, "IsoWindow") then
				return true
			end
			if instanceof(obj, "IsoThumpable") then
				local isDoor = (obj.isDoor and obj:isDoor()) or false
				local isWindow = (obj.isWindow and obj:isWindow()) or false
				if isDoor or isWindow then
					return true
				end
			end
		end
	end
	return false
end

FromZoid._openSeals = FromZoid._openSeals or {}
FromZoid._inviteScanAt = FromZoid._inviteScanAt or {}

local function scanRoomsForInvitation(rooms)
	if not rooms then
		return false
	end
	for r = 0, rooms:size() - 1 do
		local room = rooms:get(r)
		local squares = room and room.getSquares and room:getSquares()
		if squares then
			for s = 0, squares:size() - 1 do
				if FromZoid.squareHasOpenInvitation(squares:get(s)) then
					return true
				end
			end
		end
	end
	return false
end

function FromZoid.scanBuildingInvitation(building)
	if not building then
		return false
	end
	local rooms = building.getRooms and building:getRooms() or nil
	if scanRoomsForInvitation(rooms) then
		return true
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if def and def.getRooms and scanRoomsForInvitation(def:getRooms()) then
		return true
	end
	if not def or not def.getX or not cell then
		return false
	end
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local z1 = 0
	local z2 = 1
	if def.getMaxLevel then
		local maxZ = def:getMaxLevel()
		if maxZ and maxZ > z2 then
			z2 = maxZ
		end
	end
	for z = z1, z2 do
		for x = x1, x2 do
			for y = y1, y2 do
				if FromZoid.squareHasOpenInvitation(cell:getGridSquare(x, y, z)) then
					return true
				end
			end
		end
	end
	return false
end

function FromZoid.buildingHasOpenEntrance(building)
	if not building then
		return false
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	local now = getTimestampMs and getTimestampMs() or (os.time() * 1000)
	local last = FromZoid._inviteScanAt[id] or 0
	if now - last > 400 then
		FromZoid._inviteScanAt[id] = now
		if FromZoid.scanBuildingInvitation(building) then
			FromZoid._openSeals[id] = true
		else
			FromZoid._openSeals[id] = nil
		end
	end
	return FromZoid._openSeals[id] == true
end

function FromZoid.buildingHasInvitation(building)
	if not FromZoid.isEnabled("InvitationRequired") then
		return true
	end
	return FromZoid.buildingHasOpenEntrance(building)
end

function FromZoid.eachLoadedZombie(fn)
	local cell = getCell()
	if not cell or not cell.getZombieList then
		return
	end
	local list = cell:getZombieList()
	if not list then
		return
	end
	for i = 0, list:size() - 1 do
		local zombie = list:get(i)
		if zombie and zombie:isAlive() and instanceof(zombie, "IsoZombie") then
			fn(zombie, i)
		end
	end
end

function FromZoid.findNearestUnsealedBuilding(x, y, maxRange, residentialOnly, needBasement, allowNonNest)
	maxRange = maxRange or 48
	local cell = getCell()
	if not cell then
		return nil
	end
	local best = nil
	local bestD = maxRange * maxRange
	local step = 4
	local ix = math.floor(x)
	local iy = math.floor(y)
	for radius = 0, maxRange, step do
		for dx = -radius, radius, step do
			for dy = -radius, radius, step do
				if radius == 0 or math.abs(dx) == radius or math.abs(dy) == radius then
					local sq = cell:getGridSquare(ix + dx, iy + dy, 0)
					if sq then
						local building = sq:getBuilding()
						if building and not FromZoid.shouldSkipNest(building) and (allowNonNest or FromZoid.isNestHouse(building)) then
							if (not residentialOnly) or FromZoid.isResidentialBuilding(building) then
								if (not needBasement) or FromZoid.buildingHasBasement(building) then
									local d = dx * dx + dy * dy
									if d < bestD then
										bestD = d
										best = building
										if radius <= 8 then
											return best
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if best and radius >= 20 then
			return best
		end
	end
	return best
end

function FromZoid.playerInVehicle(player)
	player = player or getPlayer()
	if not player or not player.getVehicle then
		return false
	end
	return player:getVehicle() ~= nil
end

function FromZoid.playerAsleep(player)
	player = player or getPlayer()
	if not player then
		return false
	end
	if player.isAsleep then
		return player:isAsleep()
	end
	return false
end

function FromZoid.wakePlayer(player)
	if not player then
		return
	end
	local num = 0
	if player.getPlayerNum then
		num = player:getPlayerNum() or 0
	end
	pcall(function()
		if player.forceAwake then
			player:forceAwake()
		elseif player.setAsleep then
			player:setAsleep(false)
		end
		if player.setForceWakeUpTime then
			player:setForceWakeUpTime(-1)
		end
		if UIManager then
			if UIManager.setFadeBeforeUI then
				UIManager.setFadeBeforeUI(num, true)
			end
			if UIManager.FadeIn then
				UIManager.FadeIn(num, 1)
			end
		end
	end)
end

function FromZoid.nearbyNestBuildings(x, y, maxRange, residentialOnly, needBasement, allowNonNest)
	maxRange = maxRange or 72
	local now = FromZoid.nowMs()
	local key = math.floor(x / 32) .. "_" .. math.floor(y / 32) .. "_" .. tostring(maxRange) .. "_" .. tostring(residentialOnly) .. "_" .. tostring(needBasement) .. "_" .. tostring(allowNonNest)
	local cache = FromZoid._nestBuildings
	if cache and cache.key == key and (now - cache.at) < 15000 and cache.list and #cache.list > 0 then
		return cache.list
	end
	local cell = getCell()
	if not cell then
		return {}
	end
	local seen = {}
	local list = {}
	local step = 8
	local ix = math.floor(x)
	local iy = math.floor(y)
	for radius = 0, maxRange, step do
		for dx = -radius, radius, step do
			for dy = -radius, radius, step do
				if radius == 0 or math.abs(dx) == radius or math.abs(dy) == radius then
					local sq = cell:getGridSquare(ix + dx, iy + dy, 0)
					local building = sq and sq:getBuilding() or nil
					if building and not FromZoid.shouldSkipNest(building) and (allowNonNest or FromZoid.isNestHouse(building)) then
						if (not residentialOnly) or FromZoid.isResidentialBuilding(building) then
							if (not needBasement) or FromZoid.buildingHasBasement(building) then
								local id = FromZoid.buildingId(building) or tostring(building)
								if not seen[id] then
									seen[id] = true
									table.insert(list, building)
									if #list >= 10 then
										FromZoid._nestBuildings = { key = key, at = now, list = list }
										return list
									end
								end
							end
						end
					end
				end
			end
		end
	end
	FromZoid._nestBuildings = { key = key, at = now, list = list }
	return list
end

function FromZoid.pickNearbyNestBuilding(x, y, maxRange, residentialOnly, needBasement, allowNonNest)
	local list = FromZoid.nearbyNestBuildings(x, y, maxRange, residentialOnly, needBasement, allowNonNest)
	if #list == 0 then
		return nil
	end
	return list[ZombRand(#list) + 1]
end

function FromZoid.freeGroundTileInBuilding(building)
	if not building then
		return nil
	end
	local picks = {}
	local def = FromZoid.getBuildingDef(building)
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms then
			local n = rooms:size()
			local start = 0
			if n > 1 then
				start = ZombRand(n)
			end
			for k = 0, n - 1 do
				local room = rooms:get((start + k) % n)
				local z = 0
				if room and room.getZ then
					z = room:getZ() or 0
				end
				if z == 0 and getCell() and getCell().getFreeTile then
					local sq = getCell():getFreeTile(room)
					if sq and FromZoid.squareIsSafeNest(sq) and sq:getBuilding() then
						table.insert(picks, sq)
						if #picks >= 6 then
							break
						end
					end
				end
			end
		end
	end
	if #picks > 0 then
		return picks[ZombRand(#picks) + 1]
	end
	local tile = FromZoid.freeTileInBuilding(building)
	if tile and tile:getBuilding() and (not tile.getZ or tile:getZ() == 0) and FromZoid.squareIsSafeNest(tile) then
		return tile
	end
	return nil
end

function FromZoid.pickNestWalkSquare(zombie)
	if not zombie then
		return nil
	end
	local x = zombie:getX()
	local y = zombie:getY()
	local building = FromZoid.pickNearbyNestBuilding(x, y, 72, true, false)
	if not building then
		building = FromZoid.pickNearbyNestBuilding(x, y, 72, false, false)
	end
	if not building then
		building = FromZoid.pickNearbyNestBuilding(x, y, 96, false, false, true)
	end
	if not building then
		return nil
	end
	return FromZoid.freeGroundTileInBuilding(building)
end

function FromZoid.sendZombieToNest(zombie, teleport)
	if not zombie then
		return false
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	if md.fromzoidHuntUntil and now < md.fromzoidHuntUntil then
		if FromZoid.isClockNight() then
			return false
		end
		FromZoid.clearZombieHunt(zombie)
	end
	if md.fromzoidStillUntil and now < md.fromzoidStillUntil then
		return false
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	local sq = FromZoid.zombieSquare(zombie)
	if FromZoid.squareIsIndoorHide(sq) then
		if md.fromzoidAsleep and zombie:isUseless() then
			return true
		end
		if not FromZoid.zombieIsMoving(zombie) then
			FromZoid.putZombieToSleep(zombie)
			return true
		end
		return false
	end
	if zombie:isUseless() then
		FromZoid.wakeZombieBody(zombie)
	end
	local building = sq and sq.getBuilding and sq:getBuilding() or nil
	if building and FromZoid.shouldSkipNest(building) then
		if not (FromZoid.isEnabled("NestTeleport") and FromZoid.allowVisibleTeleport(zombie)) then
			return false
		end
		local tile = FromZoid.pickNestSquare(zombie)
		if not tile then
			return false
		end
		FromZoid.teleportZombieToSquare(zombie, tile)
		FromZoid.putZombieToSleep(zombie)
		return true
	end
	if teleport and not FromZoid.allowNestTeleport(zombie) then
		teleport = false
	end
	local tile = nil
	if building and not FromZoid.shouldSkipNest(building) then
		tile = FromZoid.freeGroundTileInBuilding(building)
	end
	if not tile then
		tile = FromZoid.pickNestWalkSquare(zombie)
	end
	if teleport then
		tile = tile or FromZoid.pickNestSquare(zombie)
		if not tile then
			return false
		end
		FromZoid.teleportZombieToSquare(zombie, tile)
		FromZoid.putZombieToSleep(zombie)
		return true
	end
	if not tile then
		return false
	end
	if FromZoid.pathWouldLaunch(zombie, tile) then
		return false
	end
	local moving = FromZoid.zombieIsMoving(zombie)
	local wait = moving and 10000 or 2000
	if md.fromzoidNestAt and (now - md.fromzoidNestAt) < wait then
		return true
	end
	md.fromzoidNestAt = now
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(true)
		end)
	end
	if zombie.setWalkType then
		local cur = zombie.getWalkType and zombie:getWalkType() or nil
		if cur == "slow1" then
			zombie:setWalkType("")
		end
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
	FromZoid.pathZombieToSquare(zombie, tile)
	return true
end

function FromZoid.pickNestSquare(zombie)
	local x = zombie:getX()
	local y = zombie:getY()
	local building = nil
	if FromZoid.isEnabled("PreferBasementNests") then
		building = FromZoid.pickNearbyNestBuilding(x, y, 64, true, true)
		if not building then
			building = FromZoid.pickNearbyNestBuilding(x, y, 64, false, true)
		end
		if building then
			local basement = FromZoid.findBasementSquare(building)
			if basement then
				return basement
			end
		end
	end
	building = FromZoid.pickNearbyNestBuilding(x, y, 72, true, false)
	if not building then
		building = FromZoid.pickNearbyNestBuilding(x, y, 72, false, false)
	end
	if not building then
		building = FromZoid.pickNearbyNestBuilding(x, y, 96, false, false, true)
	end
	if not building then
		return nil
	end
	local basement = FromZoid.findBasementSquare(building)
	if basement then
		return basement
	end
	local tile = FromZoid.freeGroundTileInBuilding(building)
	if tile and FromZoid.squareIsSafeNest(tile) then
		return FromZoid.wallAdjacentTile(tile)
	end
	return nil
end

function FromZoid.freeTileInBuilding(building)
	if not building then
		return nil
	end
	local def = building
	if not instanceof(building, "BuildingDef") and building.getDef then
		def = building:getDef()
	end
	if BuildingHelper and BuildingHelper.getFreeTileFromBuilding then
		local ok, sq = pcall(BuildingHelper.getFreeTileFromBuilding, def)
		if ok and sq then
			return sq
		end
	end
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms and rooms:size() > 0 then
			local room = rooms:get(ZombRand(rooms:size()))
			if room and getCell().getFreeTile then
				return getCell():getFreeTile(room)
			end
		end
	end
	return nil
end

function FromZoid.zeroZombieMotion(zombie)
	if not zombie then
		return
	end
	pcall(function()
		if zombie.setNx then
			zombie:setNx(0)
			zombie:setNy(0)
		end
		if zombie.setNz then
			zombie:setNz(0)
		end
		if zombie.setFallOnFront then
			zombie:setFallOnFront(false)
		end
		if zombie.setBumped then
			zombie:setBumped(false)
		end
		if zombie.setKnockedDown then
			zombie:setKnockedDown(false)
		end
		if zombie.setPath2 then
			zombie:setPath2(nil)
		end
		if zombie.setFakeDead and zombie.isFakeDead and zombie:isFakeDead() then
			zombie:setFakeDead(false)
		end
	end)
end

function FromZoid.teleportZombieToSquare(zombie, square)
	if not zombie or not square then
		return
	end
	if not FromZoid.squareIsSafeNest(square) and square.getZ and square:getZ() ~= 0 then
		return
	end
	local x = square:getX() + 0.5
	local y = square:getY() + 0.5
	local z = square:getZ()
	zombie:setX(x)
	zombie:setY(y)
	zombie:setZ(z)
	if zombie.setLx then
		zombie:setLx(x)
		zombie:setLy(y)
		zombie:setLz(z)
	end
	if zombie.setCurrent then
		pcall(function()
			zombie:setCurrent(square)
		end)
	end
	FromZoid.zeroZombieMotion(zombie)
end

function FromZoid.pathWouldLaunch(zombie, square)
	if not zombie or not square then
		return true
	end
	local zsq = FromZoid.zombieSquare(zombie)
	if not zsq then
		return true
	end
	local z1 = zsq.getZ and zsq:getZ() or 0
	local z2 = square.getZ and square:getZ() or 0
	if z1 ~= z2 then
		return FromZoid.zombieNearPlayers(zombie, 40)
	end
	local db = square.getBuilding and square:getBuilding() or nil
	local dx = (square:getX() + 0.5) - zombie:getX()
	local dy = (square:getY() + 0.5) - zombie:getY()
	if (dx * dx + dy * dy) <= 256 and not db then
		return false
	end
	local zb = zsq.getBuilding and zsq:getBuilding() or nil
	if zb or db then
		if FromZoid.buildingId(zb) ~= FromZoid.buildingId(db) then
			return FromZoid.zombieNearPlayers(zombie, 40)
		end
	end
	return false
end

function FromZoid.streetSquareAway(zombie, dist)
	if not zombie then
		return nil
	end
	dist = dist or 12
	local cell = getCell()
	if not cell then
		return nil
	end
	local zx = math.floor(zombie:getX())
	local zy = math.floor(zombie:getY())
	local zz = math.floor(zombie:getZ() or 0)
	local tries = { dist, 8, 4, 16, 20 }
	local dirs = {
		{ 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
		{ 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
	}
	for t = 1, #tries do
		local d = tries[t]
		for i = 1, #dirs do
			local sq = cell:getGridSquare(zx + dirs[i][1] * d, zy + dirs[i][2] * d, zz)
			if sq and sq.isFree and sq:isFree(false) and not sq:getBuilding() then
				if not FromZoid.getDoorOnSquare(sq) and not FromZoid.getWindowOnSquare(sq) then
					return sq
				end
			end
		end
	end
	return nil
end

function FromZoid.standoffSquare(building, x, y)
	if not building then
		return nil
	end
	local porch = FromZoid.nearestPorchSquare(building, x, y)
	if not porch then
		return nil
	end
	local def = FromZoid.getBuildingDef(building)
	if not def or not def.getX then
		return porch
	end
	local x2 = def.getX2 and def:getX2() or def:getX()
	local y2 = def.getY2 and def:getY2() or def:getY()
	local cx = (def:getX() + x2) / 2
	local cy = (def:getY() + y2) / 2
	local px = porch:getX()
	local py = porch:getY()
	local dx = px - cx
	local dy = py - cy
	local ox, oy = 0, 0
	if math.abs(dx) >= math.abs(dy) then
		ox = dx >= 0 and 2 or -2
	else
		oy = dy >= 0 and 2 or -2
	end
	local cell = getCell()
	if not cell then
		return porch
	end
	local sq = cell:getGridSquare(px + ox, py + oy, porch:getZ())
	if sq and sq.isFree and sq:isFree(false) and not sq:getBuilding() then
		if not FromZoid.getDoorOnSquare(sq) and not FromZoid.getWindowOnSquare(sq) then
			return sq
		end
	end
	return porch
end

function FromZoid.walkAwayFromHouse(zombie)
	if not zombie then
		return false
	end
	local dest = FromZoid.streetSquareAway(zombie, 12)
	if not dest then
		dest = FromZoid.streetSquareAway(zombie, 8)
	end
	if not dest then
		return false
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	if md.fromzoidNestAt and (now - md.fromzoidNestAt) < 2000 then
		return false
	end
	md.fromzoidNestAt = now
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(true)
		end)
	end
	FromZoid.pathZombieToSquare(zombie, dest)
	return true
end

function FromZoid.pathZombieToSquare(zombie, square)
	if not zombie or not square then
		return
	end
	if FromZoid.pathWouldLaunch(zombie, square) then
		return
	end
	FromZoid.stripLaunchPoses(zombie)
	local x = square:getX()
	local y = square:getY()
	local z = square:getZ()
	if zombie.pathToLocation then
		zombie:pathToLocation(x, y, z)
		return
	end
	if zombie.getPathFindBehavior2 then
		local pfb = zombie:getPathFindBehavior2()
		if pfb then
			if pfb.pathToLocation then
				pcall(function()
					pfb:pathToLocation(x, y, z)
				end)
				return
			end
			if pfb.pathToLocationF then
				pcall(function()
					pfb:pathToLocationF(x + 0.5, y + 0.5, z)
				end)
				return
			end
		end
	end
	if zombie.pathToLocationF then
		zombie:pathToLocationF(x + 0.5, y + 0.5, z)
	end
end

function FromZoid.zombieSquare(zombie)
	if not zombie then
		return nil
	end
	if zombie.getCurrentSquare then
		local sq = zombie:getCurrentSquare()
		if sq then
			return sq
		end
	end
	if zombie.getSquare then
		return zombie:getSquare()
	end
	return getCell():getGridSquare(math.floor(zombie:getX()), math.floor(zombie:getY()), math.floor(zombie:getZ()))
end

function FromZoid.playerList()
	local players = {}
	if getNumActivePlayers then
		for i = 0, getNumActivePlayers() - 1 do
			local p = getSpecificPlayer(i)
			if p and p:isAlive() then
				table.insert(players, p)
			end
		end
	else
		local p = getPlayer()
		if p and p:isAlive() then
			table.insert(players, p)
		end
	end
	return players
end

FromZoid.TICK_SLICE = 10
FromZoid._frame = 0

if Events and Events.OnTick then
	Events.OnTick.Add(function()
		FromZoid._frame = (FromZoid._frame or 0) + 1
	end)
end

function FromZoid.dist2ToPlayer(zombie, player)
	local dx = zombie:getX() - player:getX()
	local dy = zombie:getY() - player:getY()
	return dx * dx + dy * dy
end

function FromZoid.refreshTickContext()
	local now = FromZoid.nowMs()
	local frame = FromZoid._frame or 0
	if frame < 1 then
		frame = math.floor(now / 16)
	end
	if FromZoid._tick and FromZoid._tick.frame == frame then
		return FromZoid._tick
	end
	local players = FromZoid.playerList()
	local infos = {}
	local anySealedUninvited = false
	local gunshot = FromZoid._gunshotUntil and now < FromZoid._gunshotUntil
	local loud = nil
	if FromZoid._loudUntil and now < FromZoid._loudUntil then
		loud = FromZoid._loud
	end
	for i = 1, #players do
		local p = players[i]
		local sq = p:getCurrentSquare()
		local b = FromZoid.buildingFromSquare(sq)
		local sprinting = false
		if p.isSprinting and p:isSprinting() then
			sprinting = true
		elseif p.isRunning and p:isRunning() then
			sprinting = true
		end
		local shouting = false
		pcall(function()
			if p.isShouting and p:isShouting() then
				shouting = true
			elseif p.getVariableBoolean and (p:getVariableBoolean("bShouting") or p:getVariableBoolean("bCallingOut")) then
				shouting = true
			end
		end)
		if shouting then
			FromZoid.markLoudSound(p:getX(), p:getY(), p.getZ and p:getZ() or 0, 26)
			loud = FromZoid._loud
		end
		local sealed = b and FromZoid.isBuildingSealed(b)
		local invited = false
		if sealed then
			invited = FromZoid.buildingHasInvitation(b)
			if not invited then
				anySealedUninvited = true
			end
		end
		infos[i] = {
			player = p,
			square = sq,
			building = b,
			bid = FromZoid.buildingId(b),
			x = p:getX(),
			y = p:getY(),
			sprinting = sprinting,
			sealed = sealed and true or false,
			invited = invited,
			asleep = (p.isAsleep and p:isAsleep()) or false,
		}
	end
	FromZoid._slice = ((FromZoid._slice or 0) + 1) % FromZoid.TICK_SLICE
	FromZoid._tick = {
		frame = frame,
		at = now,
		night = FromZoid.isNight(),
		players = players,
		infos = infos,
		anySealedUninvited = anySealedUninvited,
		gunshot = gunshot,
		loud = loud,
		slice = FromZoid._slice,
		darkness = false,
		watchBuilding = nil,
		watchPorch = nil,
	}
	if FromZoid.isEnabled("EnableDarkness") then
		local state = FromZoid.getState()
		if state and state.darknessActive then
			FromZoid._tick.darkness = true
		end
	end
	if anySealedUninvited and FromZoid.cachedPorchSquare then
		for i = 1, #infos do
			local info = infos[i]
			if info.sealed and not info.invited and info.building then
				FromZoid._tick.watchBuilding = info.building
				FromZoid._tick.watchPorch = FromZoid.cachedPorchSquare(info.building, info.x, info.y)
				break
			end
		end
	end
	return FromZoid._tick
end

function FromZoid.inSlice(zombie, ctx)
	if not ctx then
		return true
	end
	local id = 0
	if zombie.getID then
		id = zombie:getID() or 0
	end
	if id < 0 then
		id = -id
	end
	return (id % FromZoid.TICK_SLICE) == ctx.slice
end

function FromZoid.markLoudSound(x, y, z, radius)
	if not x or not y then
		return
	end
	radius = tonumber(radius) or 30
	if radius < 20 then
		return
	end
	FromZoid._loudUntil = FromZoid.nowMs() + 2500
	FromZoid._loud = { x = x, y = y, z = z or 0, r2 = radius * radius }
end

function FromZoid.markGunshot(source)
	FromZoid._gunshotUntil = FromZoid.nowMs() + 4000
	local x, y, z = nil, nil, nil
	if source and source.getX then
		x = source:getX()
		y = source:getY()
		z = source.getZ and source:getZ() or 0
	end
	if not x then
		local p = getPlayer and getPlayer() or nil
		if p and p.getX then
			x = p:getX()
			y = p:getY()
			z = p.getZ and p:getZ() or 0
		end
	end
	if x then
		FromZoid.markLoudSound(x, y, z, 50)
	end
end

function FromZoid.isNestHouse(building)
	if not building then
		return false
	end
	if not FromZoid.isEnabled("NestEveryOtherHouse") then
		return true
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return true
	end
	local spawnId = FromZoid.getState().spawnBuildingId
	if spawnId and spawnId == id then
		return false
	end
	local h = 0
	for i = 1, #id do
		h = h + id:byte(i) * i
	end
	return (h % 2) == 0
end

function FromZoid.getBuildingDef(building)
	if not building then
		return nil
	end
	if instanceof(building, "BuildingDef") then
		return building
	end
	if building.getDef then
		return building:getDef()
	end
	return nil
end

function FromZoid.clearZombieHunt(zombie)
	if not zombie then
		return
	end
	local md = zombie:getModData()
	md.fromzoidHuntUntil = nil
	md.fromzoidGather = nil
	md.fromzoidGatherAt = nil
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
end

function FromZoid.zombieAgainstBuilding(zombie, building)
	if not zombie or not building then
		return false
	end
	if FromZoid.zombieNearOpening(zombie) then
		return true
	end
	local def = FromZoid.getBuildingDef(building)
	if not def or not def.getX then
		return false
	end
	local x = zombie:getX()
	local y = zombie:getY()
	local x1 = def:getX() - 2
	local y1 = def:getY() - 2
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 2
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 2
	return x >= x1 and x <= (x2 + 1) and y >= y1 and y <= (y2 + 1)
end

function FromZoid.sameUnsealedBuilding(zombie, player)
	if not zombie or not player then
		return false
	end
	local zs = FromZoid.zombieSquare(zombie)
	local ps = player.getCurrentSquare and player:getCurrentSquare() or nil
	local zb = zs and zs.getBuilding and zs:getBuilding() or nil
	local pb = ps and ps.getBuilding and ps:getBuilding() or nil
	if not zb or not pb then
		return false
	end
	if FromZoid.buildingId(zb) ~= FromZoid.buildingId(pb) then
		return false
	end
	if FromZoid.isBuildingSealed(zb) and not FromZoid.buildingHasInvitation(zb) then
		return false
	end
	return true
end

function FromZoid.roomNameIsResidential(name)
	if not name then
		return false
	end
	local n = string.lower(tostring(name))
	n = string.gsub(n, "%s+", "")
	return FromZoid.RESIDENTIAL[n] == true
end

function FromZoid.isResidentialBuilding(building)
	local id = FromZoid.buildingId(building)
	local cache = FromZoid._resCache
	if not cache then
		cache = {}
		FromZoid._resCache = cache
	end
	if id and cache[id] ~= nil then
		return cache[id]
	end
	local ok = false
	local def = FromZoid.getBuildingDef(building)
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms then
			for i = 0, rooms:size() - 1 do
				local room = rooms:get(i)
				local name = nil
				if room.getName then
					name = room:getName()
				elseif room.getRoomName then
					name = room:getRoomName()
				end
				if FromZoid.roomNameIsResidential(name) then
					ok = true
					break
				end
			end
		end
	end
	if id then
		cache[id] = ok
	end
	return ok
end

function FromZoid.getDoorOnSquare(square)
	if not square then
		return nil
	end
	local objects = square:getObjects()
	if not objects then
		return nil
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoDoor") then
			return obj
		end
	end
	return nil
end

function FromZoid.getWindowOnSquare(square)
	if not square then
		return nil
	end
	local objects = square:getObjects()
	if not objects then
		return nil
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if instanceof(obj, "IsoWindow") then
			return obj
		end
	end
	return nil
end

function FromZoid.squareHasHungTalisman(square)
	if not square then
		return false
	end
	local worldObjects = square:getWorldObjects()
	if not worldObjects then
		return false
	end
	for i = 0, worldObjects:size() - 1 do
		local wo = worldObjects:get(i)
		local item = wo.getItem and wo:getItem() or nil
		if item then
			local md = item.getModData and item:getModData() or nil
			local full = item.getFullType and item:getFullType() or ""
			if (md and md.fromzoid_talisman) or full == FromZoid.ITEM_TALISMAN then
				return true
			end
		end
	end
	return false
end

function FromZoid.openingPorchSquare(opening, steps)
	if not opening then
		return nil
	end
	steps = steps or 4
	local square = opening.getSquare and opening:getSquare() or nil
	local opp = opening.getOppositeSquare and opening:getOppositeSquare() or nil
	local indoor = nil
	local outdoor = nil
	if square and square:getBuilding() then
		indoor = square
	elseif opp and opp:getBuilding() then
		indoor = opp
	end
	if opp and not opp:getBuilding() then
		outdoor = opp
	elseif square and not square:getBuilding() then
		outdoor = square
	end
	if not outdoor then
		return nil
	end
	if not indoor then
		return outdoor
	end
	local dx = outdoor:getX() - indoor:getX()
	local dy = outdoor:getY() - indoor:getY()
	if dx ~= 0 then
		dx = dx > 0 and 1 or -1
	end
	if dy ~= 0 then
		dy = dy > 0 and 1 or -1
	end
	local cell = getCell()
	local best = outdoor
	for i = 1, steps do
		local n = cell:getGridSquare(outdoor:getX() + dx * i, outdoor:getY() + dy * i, outdoor:getZ())
		if not n or n:getBuilding() then
			break
		end
		if FromZoid.getWindowOnSquare(n) or FromZoid.getDoorOnSquare(n) then
			break
		end
		if n.isFree and not n:isFree(false) then
			break
		end
		best = n
	end
	return best
end

function FromZoid.stepOffOpening(zombie)
	if not zombie then
		return false
	end
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return false
	end
	local opening = FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq)
	if not opening then
		return false
	end
	local dest = FromZoid.openingPorchSquare(opening, 2)
	if not dest or dest == sq then
		if opening.getOppositeSquare then
			local opp = opening:getOppositeSquare()
			if opp and not opp:getBuilding() and opp.isFree and opp:isFree(false) then
				if not FromZoid.getDoorOnSquare(opp) and not FromZoid.getWindowOnSquare(opp) then
					dest = opp
				end
			end
		end
	end
	if not dest or dest == sq then
		return false
	end
	if dest:getBuilding() then
		return false
	end
	local x = dest:getX() + 0.5
	local y = dest:getY() + 0.5
	local z = dest:getZ()
	zombie:setX(x)
	zombie:setY(y)
	zombie:setZ(z)
	if zombie.setLx then
		zombie:setLx(x)
		zombie:setLy(y)
		zombie:setLz(z)
	end
	if zombie.setCurrent then
		pcall(function()
			zombie:setCurrent(dest)
		end)
	end
	FromZoid.zeroZombieMotion(zombie)
	return true
end

function FromZoid.nearestPorchSquare(building, x, y)
	if not building then
		return nil
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if not def or not def.getX or not cell then
		return nil
	end
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local best = nil
	local bestD = nil
	local function consider(sq)
		if not sq then
			return
		end
		local opening = FromZoid.getDoorOnSquare(sq) or FromZoid.getWindowOnSquare(sq)
		local porch = FromZoid.openingPorchSquare(opening)
		if not porch then
			return
		end
		local dx = porch:getX() + 0.5 - x
		local dy = porch:getY() + 0.5 - y
		local d = dx * dx + dy * dy
		if not bestD or d < bestD then
			bestD = d
			best = porch
		end
	end
	for z = 0, 1 do
		for px = x1, x2 do
			consider(cell:getGridSquare(px, y1, z))
			consider(cell:getGridSquare(px, y2, z))
		end
		for py = y1 + 1, y2 - 1 do
			consider(cell:getGridSquare(x1, py, z))
			consider(cell:getGridSquare(x2, py, z))
		end
	end
	return best
end

function FromZoid.doorHangSquare(door)
	if not door then
		return nil
	end
	local square = door.getSquare and door:getSquare() or nil
	local opp = door.getOppositeSquare and door:getOppositeSquare() or nil
	if square and square:getBuilding() then
		return square
	end
	if opp and opp:getBuilding() then
		return opp
	end
	return square or opp
end

function FromZoid.doorIsExterior(door)
	return FromZoid.openingIsExterior(door)
end

function FromZoid.doorHangOffset(door, square)
	local ox, oy, oz = 0.5, 0.5, 1.2
	if not door or not square then
		return ox, oy, oz
	end
	local doorSq = door.getSquare and door:getSquare() or nil
	local onDoorTile = doorSq and doorSq:getX() == square:getX() and doorSq:getY() == square:getY()
	local north = door.getNorth and door:getNorth()
	if north then
		oy = onDoorTile and 0.12 or 0.88
	else
		ox = onDoorTile and 0.12 or 0.88
	end
	return ox, oy, oz
end

function FromZoid.firstDoorInBuilding(building)
	if not building then
		return nil
	end
	local function consider(door, preferExterior)
		if not door then
			return nil
		end
		local hang = FromZoid.doorHangSquare(door)
		if not hang then
			return nil
		end
		if preferExterior and not FromZoid.doorIsExterior(door) then
			return nil
		end
		return door
	end
	local found = nil
	local rooms = building.getRooms and building:getRooms() or nil
	if not rooms then
		local def = FromZoid.getBuildingDef(building)
		if def and def.getRooms then
			rooms = def:getRooms()
		end
	end
	if rooms then
		for r = 0, rooms:size() - 1 do
			local room = rooms:get(r)
			local squares = room and room.getSquares and room:getSquares()
			if squares then
				for s = 0, squares:size() - 1 do
					local door = FromZoid.getDoorOnSquare(squares:get(s))
					local ext = consider(door, true)
					if ext then
						return ext
					end
					if not found then
						found = consider(door, false)
					end
				end
			end
		end
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if def and def.getX and cell then
		local x1 = def:getX() - 1
		local y1 = def:getY() - 1
		local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
		local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, 0)
				local door = FromZoid.getDoorOnSquare(sq)
				local ext = consider(door, true)
				if ext then
					return ext
				end
				if not found then
					found = consider(door, false)
				end
			end
		end
	end
	return found
end

function FromZoid.squareIsSafeNest(square)
	if not square then
		return false
	end
	if square.getZ and square:getZ() < 0 then
		local hasFloor = false
		if square.Has and IsoFlagType and IsoFlagType.solidfloor then
			hasFloor = square:Has(IsoFlagType.solidfloor)
		end
		if not hasFloor and square.getFloor then
			hasFloor = square:getFloor() ~= nil
		end
		if not hasFloor then
			return false
		end
	end
	if square.isFree then
		return square:isFree(false)
	end
	return true
end

function FromZoid.findBasementSquare(building)
	local cell = getCell()
	if not cell then
		return nil
	end
	local def = FromZoid.getBuildingDef(building)
	if def and def.getX and def.getY then
		local x1 = def:getX()
		local y1 = def:getY()
		local x2 = def.getX2 and def:getX2() or (x1 + 8)
		local y2 = def.getY2 and def:getY2() or (y1 + 8)
		if x2 < x1 then
			x1, x2 = x2, x1
		end
		if y2 < y1 then
			y1, y2 = y2, y1
		end
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, -1)
				if sq and FromZoid.squareIsSafeNest(sq) then
					local b = sq:getBuilding()
					if not b or not FromZoid.shouldSkipNest(b) then
						return sq
					end
				end
			end
		end
	end
	if def and def.getRooms then
		local rooms = def:getRooms()
		if rooms then
			for i = 0, rooms:size() - 1 do
				local room = rooms:get(i)
				local z = 0
				if room.getZ then
					z = room:getZ()
				end
				if z < 0 and getCell().getFreeTile then
					local sq = getCell():getFreeTile(room)
					if sq and FromZoid.squareIsSafeNest(sq) then
						return sq
					end
				end
			end
		end
	end
	return nil
end

function FromZoid.buildingHasBasement(building)
	local id = FromZoid.buildingId(building)
	local now = FromZoid.nowMs()
	if not FromZoid._basementCache or (now - (FromZoid._basementAt or 0)) > 30000 then
		FromZoid._basementCache = {}
		FromZoid._basementAt = now
	end
	if id and FromZoid._basementCache[id] ~= nil then
		return FromZoid._basementCache[id]
	end
	local has = FromZoid.findBasementSquare(building) ~= nil
	if id then
		FromZoid._basementCache[id] = has
	end
	return has
end

function FromZoid.wallAdjacentTile(square)
	if not square then
		return square
	end
	local cell = getCell()
	if not cell then
		return square
	end
	local b = square:getBuilding()
	local bid = FromZoid.buildingId(b)
	local dirs = { {1, 0}, {-1, 0}, {0, 1}, {0, -1} }
	for i = 1, #dirs do
		local n = cell:getGridSquare(square:getX() + dirs[i][1], square:getY() + dirs[i][2], square:getZ())
		if n and n.isFree and n:isFree(false) then
			local nb = n:getBuilding()
			if bid then
				if nb and FromZoid.buildingId(nb) == bid then
					return n
				end
			elseif nb then
				return n
			end
		end
	end
	return square
end

function FromZoid.isZombieOffscreen(zombie)
	if not zombie then
		return true
	end
	if zombie.isOnScreen and zombie:isOnScreen() then
		return false
	end
	local players = (FromZoid._tick and FromZoid._tick.players) or FromZoid.playerList()
	for i = 1, #players do
		local p = players[i]
		if FromZoid.dist2ToPlayer(zombie, p) < 324 then
			if (not p.CanSee) or p:CanSee(zombie) then
				return false
			end
		end
	end
	return true
end

function FromZoid.zombieNearPlayers(zombie, tiles)
	if not zombie then
		return false
	end
	tiles = tiles or 24
	local r2 = tiles * tiles
	local players = (FromZoid._tick and FromZoid._tick.players) or FromZoid.playerList()
	for i = 1, #players do
		if FromZoid.dist2ToPlayer(zombie, players[i]) <= r2 then
			return true
		end
	end
	return false
end

function FromZoid.allowVisibleTeleport(zombie)
	if not zombie then
		return false
	end
	if FromZoid.zombieNearPlayers(zombie, 40) then
		return false
	end
	return FromZoid.isZombieOffscreen(zombie)
end

function FromZoid.allowNestTeleport(zombie)
	if not zombie then
		return false
	end
	if not FromZoid.isEnabled("NestTeleport") then
		return false
	end
	local md = zombie:getModData()
	if md.fromzoidAsleep or md.fromzoidHold then
		return false
	end
	local sq = FromZoid.zombieSquare(zombie)
	if sq and sq.getBuilding and sq:getBuilding() then
		return false
	end
	return FromZoid.allowVisibleTeleport(zombie)
end

function FromZoid.clusterKey(x, y)
	return math.floor(x / 64) .. "_" .. math.floor(y / 64)
end

function FromZoid.getClusterKind(x, y)
	local data = ModData.getOrCreate(FromZoid.MD_CLUSTERS)
	local key = FromZoid.clusterKey(x, y)
	if data[key] then
		return data[key]
	end
	local boarded = FromZoid.getSandbox("NeighborhoodBoardedChance", 22)
	local damaged = FromZoid.getSandbox("NeighborhoodDamagedChance", 22)
	local kind = "none"
	if ZombRand(100) < boarded then
		kind = "boarded"
	elseif ZombRand(100) < damaged then
		kind = "damaged"
	end
	data[key] = kind
	return kind
end

function FromZoid.squareIsIndoorHide(square)
	if not square then
		return false
	end
	local building = FromZoid.buildingFromSquare(square)
	if not building then
		return false
	end
	if FromZoid.shouldKeepZombiesOut(building) then
		return false
	end
	if square.getRoom then
		return square:getRoom() ~= nil
	end
	return false
end

function FromZoid.zombieIsMoving(zombie)
	if not zombie or not zombie.isMoving then
		return false
	end
	local ok, moving = pcall(function()
		return zombie:isMoving()
	end)
	return ok and moving and true or false
end

function FromZoid.zombieIsOnGround(zombie)
	if not zombie then
		return false
	end
	if zombie.isOnFloor and zombie:isOnFloor() then
		return true
	end
	if zombie.isKnockedDown and zombie:isKnockedDown() then
		return true
	end
	return false
end

function FromZoid.stripLaunchPoses(zombie)
	if not zombie then
		return
	end
	pcall(function()
		if zombie.setFakeDead and zombie.isFakeDead and zombie:isFakeDead() then
			zombie:setFakeDead(false)
		end
		if zombie.setCrawler and zombie.isCrawler and zombie:isCrawler() then
			zombie:setCrawler(false)
		end
		if zombie.setKnockedDown and zombie.isKnockedDown and zombie:isKnockedDown() then
			zombie:setKnockedDown(false)
		end
		if zombie.setFallOnFront then
			zombie:setFallOnFront(false)
		end
	end)
end

function FromZoid.pinZombieSleepPose(zombie)
	if not zombie then
		return
	end
	FromZoid.stripLaunchPoses(zombie)
	if not zombie:isUseless() then
		zombie:setUseless(true)
	end
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(false)
		end)
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
end

function FromZoid.putZombieToSleep(zombie)
	if not zombie then
		return
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	if md.fromzoidHuntUntil and now < md.fromzoidHuntUntil then
		return
	end
	if md.fromzoidStillUntil and now < md.fromzoidStillUntil then
		return
	end
	if not FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
		return
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	if md.fromzoidAsleep and zombie:isUseless() then
		FromZoid.stripLaunchPoses(zombie)
		return
	end
	if FromZoid.zombieIsMoving(zombie) then
		md.fromzoidSleepWait = md.fromzoidSleepWait or now
		if (now - md.fromzoidSleepWait) < 8000 then
			return
		end
	end
	md.fromzoidSleepWait = nil
	md.fromzoidAsleep = true
	if zombie.setPath2 then
		pcall(function()
			zombie:setPath2(nil)
		end)
	end
	FromZoid.pinZombieSleepPose(zombie)
end

function FromZoid.wakeZombieBody(zombie)
	if not zombie then
		return
	end
	zombie:getModData().fromzoidAsleep = nil
	zombie:getModData().fromzoidSleepAt = nil
	zombie:getModData().fromzoidSleepWait = nil
	if zombie.setFakeDead then
		pcall(function()
			zombie:setFakeDead(false)
		end)
	end
	if zombie.setCrawler then
		pcall(function()
			zombie:setCrawler(false)
		end)
	end
	if zombie.setOnFloor then
		pcall(function()
			zombie:setOnFloor(false)
		end)
	end
	if zombie.setSitOnGround then
		pcall(function()
			zombie:setSitOnGround(false)
		end)
	end
	zombie:setUseless(false)
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(true)
		end)
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
	FromZoid.zeroZombieMotion(zombie)
end

function FromZoid.holdAtGlass(zombie)
	if not zombie then
		return
	end
	local md = zombie:getModData()
	if md.fromzoidStillUntil and FromZoid.nowMs() < md.fromzoidStillUntil then
		return
	end
	md.fromzoidHold = true
	md.fromzoidHuntUntil = nil
	zombie:setUseless(true)
	if zombie.setCrawler then
		zombie:setCrawler(false)
	end
	if zombie.setSitOnGround then
		pcall(function()
			zombie:setSitOnGround(false)
		end)
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(false)
		end)
	end
	if zombie.setThumpFlag then
		pcall(function()
			zombie:setThumpFlag(0)
		end)
	end
	if zombie.setThumpTarget then
		pcall(function()
			zombie:setThumpTarget(nil)
		end)
	end
	if zombie.setPath2 then
		pcall(function()
			zombie:setPath2(nil)
		end)
	end
	if zombie.setNx then
		pcall(function()
			zombie:setNx(0)
			zombie:setNy(0)
		end)
	end
end

function FromZoid.releaseHold(zombie)
	if not zombie then
		return
	end
	local md = zombie:getModData()
	if not md.fromzoidHold then
		return
	end
	md.fromzoidHold = nil
	FromZoid.wakeZombieBody(zombie)
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
end

function FromZoid.zombieNearOpening(zombie)
	local sq = FromZoid.zombieSquare(zombie)
	if not sq then
		return false
	end
	local cell = getCell()
	if not cell then
		return false
	end
	for dx = -1, 1 do
		for dy = -1, 1 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if FromZoid.getDoorOnSquare(n) or FromZoid.getWindowOnSquare(n) then
				return true
			end
		end
	end
	return false
end

function FromZoid.applyStillPose(zombie, player)
	if not zombie then
		return
	end
	if zombie.setTarget then
		zombie:setTarget(nil)
	end
	zombie:setUseless(true)
	if zombie.setSitOnGround then
		pcall(function()
			zombie:setSitOnGround(false)
		end)
	end
	if player then
		if zombie.faceThisObject then
			pcall(function()
				zombie:faceThisObject(player)
			end)
		elseif zombie.faceLocation then
			pcall(function()
				zombie:faceLocation(player:getX(), player:getY())
			end)
		end
	end
end

function FromZoid.reconcileZombieState(zombie, ctx)
	if not zombie then
		return
	end
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	if md.fromzoidStillUntil then
		if now < md.fromzoidStillUntil then
			return
		end
		md.fromzoidStillUntil = nil
		FromZoid.wakeZombieBody(zombie)
	end
	local clockNight = FromZoid.isClockNight()
	local hunting = md.fromzoidHuntUntil and now < md.fromzoidHuntUntil
	if hunting then
		if clockNight and ctx and ctx.anySealedUninvited then
			return
		end
		if md.fromzoidHold then
			FromZoid.releaseHold(zombie)
		elseif zombie:isUseless() then
			FromZoid.wakeZombieBody(zombie)
		end
		return
	end
	if md.fromzoidHold then
		local keep = clockNight and ctx and ctx.anySealedUninvited
		if keep then
			keep = FromZoid.zombieNearOpening(zombie)
				or (ctx.watchBuilding and FromZoid.zombieAgainstBuilding(zombie, ctx.watchBuilding))
		end
		if not keep then
			FromZoid.releaseHold(zombie)
		end
		return
	end
	if md.fromzoidAsleep and not clockNight and FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
		FromZoid.stripLaunchPoses(zombie)
		return
	end
	if not zombie:isUseless() then
		return
	end
	if clockNight then
		FromZoid.wakeZombieBody(zombie)
		return
	end
	if not FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie)) then
		FromZoid.wakeZombieBody(zombie)
	end
end

function FromZoid.occupiedBuildingIds()
	local now = getTimestampMs and getTimestampMs() or 0
	if FromZoid._occupiedCache and now - (FromZoid._occupiedAt or 0) < 250 then
		return FromZoid._occupiedCache
	end
	local ids = {}
	for _, player in ipairs(FromZoid.playerList()) do
		local sq = player:getCurrentSquare()
		local building = FromZoid.buildingFromSquare(sq)
		local id = FromZoid.buildingId(building)
		if id then
			ids[id] = building
		end
	end
	FromZoid._occupiedCache = ids
	FromZoid._occupiedAt = now
	return ids
end

function FromZoid.shouldSkipNest(building)
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed(building) then
		return true
	end
	local id = FromZoid.buildingId(building)
	if id and FromZoid.occupiedBuildingIds()[id] then
		return true
	end
	return false
end

function FromZoid.shouldKeepZombiesOut(building)
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed(building) and not FromZoid.buildingHasInvitation(building) then
		return true
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	local spawnId = FromZoid.getState().spawnBuildingId
	if spawnId and spawnId == id then
		local gt = getGameTime()
		if not gt or gt:getNightsSurvived() <= 0 then
			if not FromZoid.buildingHasOpenEntrance(building) then
				return true
			end
		end
	end
	return false
end

function FromZoid.removeZombieQuiet(zombie)
	if not zombie then
		return
	end
	pcall(function()
		if zombie.setTarget then
			zombie:setTarget(nil)
		end
		if zombie.removeFromWorld then
			zombie:removeFromWorld()
		end
		if zombie.removeFromSquare then
			zombie:removeFromSquare()
		end
	end)
end

function FromZoid.evictZombiesFromBuilding(buildingOrId)
	local id = buildingOrId
	if type(buildingOrId) ~= "string" then
		id = FromZoid.buildingId(buildingOrId)
	end
	if not id then
		return
	end
	local toRemove = {}
	FromZoid.eachLoadedZombie(function(zombie)
		local sq = FromZoid.zombieSquare(zombie)
		local b = sq and sq:getBuilding() or nil
		if b and FromZoid.buildingId(b) == id then
			table.insert(toRemove, zombie)
		end
	end)
	for i = 1, #toRemove do
		FromZoid.removeZombieQuiet(toRemove[i])
	end
end
