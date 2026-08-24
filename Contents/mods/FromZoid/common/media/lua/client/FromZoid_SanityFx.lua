local lastEvent = 0
local lastWoods = 0
local flareUntil = 0

local function offsetAround(player, minDist, maxDist)
	minDist = minDist or 8
	maxDist = maxDist or 14
	local dist = minDist + ZombRand(math.max(1, maxDist - minDist + 1))
	local ang = ZombRand(360) * 0.0174533
	local z = 0
	if player.getZ then
		z = player:getZ() or 0
	end
	return player:getX() + math.cos(ang) * dist, player:getY() + math.sin(ang) * dist, z
end

local function playWorld(player, sound)
	if not sound or not player or not player.getX then
		return
	end
	local x, y, z = offsetAround(player, 8, 14)
	pcall(function()
		local sm = getSoundManager and getSoundManager() or nil
		if sm and sm.PlayWorldSoundImpl then
			sm:PlayWorldSoundImpl(sound, false, x, y, z, 0, 50, 1.25, false)
			return
		end
		if sm and sm.PlayWorldSound and player.getCurrentSquare then
			sm:PlayWorldSound(sound, player:getCurrentSquare(), 0, 50, 1.25, false)
			return
		end
		local world = getWorld and getWorld() or nil
		if world and world.getFreeEmitter then
			local emitter = world:getFreeEmitter(x, y, z)
			if emitter and emitter.playSound then
				emitter:playSound(sound)
			end
		end
	end)
end

local function playNameWhisper(player)
	playWorld(player, string.format("FromZoid_Name_%02d", ZombRand(12) + 1))
end

local function flare()
	flareUntil = (FromZoid.nowMs and FromZoid.nowMs() or 0) + 2200
end

local function findRadio(player)
	local sq = player:getCurrentSquare()
	local cell = getCell()
	if not sq or not cell then
		return nil
	end
	for dx = -3, 3 do
		for dy = -3, 3 do
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

local function turnOnRadio(obj, player)
	if not obj then
		return
	end
	pcall(function()
		local dd = obj.getDeviceData and obj:getDeviceData() or nil
		if dd and dd.setIsTurnedOn then
			dd:setIsTurnedOn(true)
		end
	end)
	playNameWhisper(player)
end

local function flickerLights(player)
	local sq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
	local cell = getCell()
	if not sq or not cell then
		return
	end
	local switches = {}
	for dx = -4, 4 do
		for dy = -4, 4 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if n and n.getObjects then
				local objs = n:getObjects()
				if objs then
					for i = 0, objs:size() - 1 do
						local obj = objs:get(i)
						if obj and instanceof(obj, "IsoLightSwitch") then
							table.insert(switches, obj)
						end
					end
				end
			end
		end
	end
	if #switches == 0 then
		playWorld(player, "LightSwitch")
		return
	end
	local light = switches[ZombRand(#switches) + 1]
	pcall(function()
		if light.toggle then
			light:toggle()
		elseif light.setActive then
			local on = true
			if light.isActivated then
				on = light:isActivated()
			elseif light.isActive then
				on = light:isActive()
			end
			light:setActive(not on)
		end
	end)
	playWorld(player, "LightSwitch")
end

local function stoveIsOn(obj)
	if not obj then
		return false
	end
	if obj.Activated then
		return obj:Activated() and true or false
	end
	if obj.isActivated then
		return obj:isActivated() and true or false
	end
	return false
end

local function findStove(player)
	local sq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
	local cell = getCell()
	if not sq or not cell then
		return nil
	end
	local found = {}
	for dx = -8, 8 do
		for dy = -8, 8 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			if n and n.getObjects then
				local objs = n:getObjects()
				if objs then
					for i = 0, objs:size() - 1 do
						local obj = objs:get(i)
						if obj and instanceof(obj, "IsoStove") and not stoveIsOn(obj) then
							table.insert(found, obj)
						end
					end
				end
			end
		end
	end
	if #found == 0 then
		return nil
	end
	return found[ZombRand(#found) + 1]
end

local function turnOnStove(obj)
	if not obj then
		return false
	end
	local ok = false
	pcall(function()
		if stoveIsOn(obj) then
			return
		end
		if obj.Toggle then
			obj:Toggle()
			ok = true
		end
	end)
	return ok
end

local function doorBlocked(door)
	if not door then
		return true
	end
	if door.isDestroyed and door:isDestroyed() then
		return true
	end
	if door.isBarricaded and door:isBarricaded() then
		return true
	end
	local function planks(bar)
		if not bar then
			return false
		end
		if bar.getNumPlanks then
			return (bar:getNumPlanks() or 0) > 0
		end
		return true
	end
	if door.getBarricadeOnSameSquare and planks(door:getBarricadeOnSameSquare()) then
		return true
	end
	if door.getBarricadeOnOppositeSquare and planks(door:getBarricadeOnOppositeSquare()) then
		return true
	end
	return false
end

local function toggleUnsealedDoor(player)
	local sq = player and player.getCurrentSquare and player:getCurrentSquare() or nil
	local cell = getCell()
	if not sq or not cell then
		return false
	end
	local building = FromZoid.buildingFromSquare and FromZoid.buildingFromSquare(sq) or sq:getBuilding()
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed and FromZoid.isBuildingSealed(building) then
		return false
	end
	local bid = FromZoid.buildingId and FromZoid.buildingId(building) or nil
	local doors = {}
	for dx = -10, 10 do
		for dy = -10, 10 do
			local n = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
			local door = n and FromZoid.getDoorOnSquare and FromZoid.getDoorOnSquare(n) or nil
			if door and not doorBlocked(door) then
				local dsq = door.getSquare and door:getSquare() or n
				local db = FromZoid.buildingFromSquare and FromZoid.buildingFromSquare(dsq) or (dsq and dsq.getBuilding and dsq:getBuilding())
				local same = db == building
				if not same and bid and FromZoid.buildingId then
					same = FromZoid.buildingId(db) == bid
				end
				if same then
					table.insert(doors, door)
				end
			end
		end
	end
	if #doors == 0 then
		return false
	end
	local door = doors[ZombRand(#doors) + 1]
	local ok = false
	pcall(function()
		if door.ToggleDoorSilent then
			door:ToggleDoorSilent()
			ok = true
		elseif door.ToggleDoor then
			door:ToggleDoor(player)
			ok = true
		end
	end)
	return ok
end

local function delusionTrick(player)
	local roll = ZombRand(7)
	if roll == 0 then
		local radio = findRadio(player)
		if radio then
			turnOnRadio(radio, player)
		else
			playNameWhisper(player)
		end
	elseif roll == 1 then
		playNameWhisper(player)
	elseif roll == 2 then
		playWorld(player, "ZombieSurprisedPlayer")
	elseif roll == 3 then
		playWorld(player, "HumanFootstepsCombined")
	elseif roll == 4 then
		playWorld(player, "DoorIsLocked")
	elseif roll == 5 then
		flickerLights(player)
	else
		playNameWhisper(player)
	end
end

local function delusionEvent(player)
	flare()
	delusionTrick(player)
end

local function psychosisEvent(player)
	flare()
	local roll = ZombRand(10)
	if roll <= 5 then
		delusionTrick(player)
	elseif roll == 6 then
		if not turnOnStove(findStove(player)) then
			delusionTrick(player)
		end
	elseif roll == 7 then
		if not toggleUnsealedDoor(player) then
			delusionTrick(player)
		end
	elseif roll == 8 then
		playWorld(player, "MetaScream")
	else
		playNameWhisper(player)
		playWorld(player, "ZombieSurprisedPlayer")
	end
end

local function tickSanityFx()
	local player = getPlayer()
	if not player or not player:isAlive() then
		return
	end
	if FromZoid.playerInVehicle and FromZoid.playerInVehicle(player) then
		return
	end
	local now = FromZoid.nowMs()
	if FromZoid.inTheWoods(player) and FromZoid.isEnabled("TheyKnowYourName") then
		if now - lastWoods >= 90000 and ZombRand(100) < 18 then
			playNameWhisper(player)
			lastWoods = now
		end
	end
	if not FromZoid.isEnabled("EnableSanity") then
		return
	end
	local level = FromZoid.sanityLevel(player)
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
	lastWoods = 0
	flareUntil = 0
end)

function FromZoid.forceSanityFx(player)
	player = player or getPlayer()
	if not player then
		return
	end
	local level = FromZoid.sanityLevel(player)
	if level == "psychosis" then
		psychosisEvent(player)
	else
		delusionEvent(player)
	end
	lastEvent = FromZoid.nowMs()
end

require "ISUI/ISPanel"

local function washFor(player)
	if not player or not player:isAlive() then
		return nil
	end
	if FromZoid.playerAsleep and FromZoid.playerAsleep(player) then
		return nil
	end
	if not FromZoid.isEnabled("EnableSanity") then
		return nil
	end
	local level = FromZoid.sanityLevel(player)
	local now = FromZoid.nowMs and FromZoid.nowMs() or getTimestampMs()
	local flare = flareUntil > 0 and now < flareUntil
	if level == "psychosis" and FromZoid.isEnabled("EnablePsychosis") then
		local pulse = 0.06 * math.sin(now / 700)
		return {
			a = 0.34 + pulse + (flare and 0.10 or 0),
			r = 0.22,
			g = 0.02,
			b = 0.10,
		}
	end
	if level == "delusion" and FromZoid.isEnabled("EnableDelusions") then
		return {
			a = 0.20 + (flare and 0.08 or 0),
			r = 0.14,
			g = 0.18,
			b = 0.04,
		}
	end
	return nil
end

FromZoidSanityVeil = ISPanel:derive("FromZoidSanityVeil")

function FromZoidSanityVeil:new()
	local o = ISPanel:new(-8, -8, 1, 1)
	setmetatable(o, self)
	self.__index = self
	o.background = false
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	o.keepOnScreen = false
	o.wantMouseEvents = false
	o.wantKeyEvents = false
	o.moveWithMouse = false
	o.playerNum = 0
	o.wash = nil
	o.washX = 0
	o.washY = 0
	o.washW = 0
	o.washH = 0
	return o
end

function FromZoidSanityVeil:containsPoint(x, y)
	return false
end

function FromZoidSanityVeil:containsPointLocal(x, y)
	return false
end

function FromZoidSanityVeil:isMouseOver()
	return false
end

function FromZoidSanityVeil:onMouseDown(x, y)
	return false
end

function FromZoidSanityVeil:onMouseUp(x, y)
	return false
end

function FromZoidSanityVeil:onRightMouseDown(x, y)
	return false
end

function FromZoidSanityVeil:onRightMouseUp(x, y)
	return false
end

function FromZoidSanityVeil:onMouseMove(dx, dy)
	return false
end

function FromZoidSanityVeil:onMouseWheel(delta)
	return false
end

function FromZoidSanityVeil:prerender()
	local player = getSpecificPlayer(self.playerNum) or getPlayer()
	self.wash = washFor(player)
	if not self.wash then
		if self:isVisible() then
			self:setVisible(false)
		end
		return
	end
	if not self:isVisible() then
		self:setVisible(true)
	end
	local n = self.playerNum or 0
	self.washX = getPlayerScreenLeft(n)
	self.washY = getPlayerScreenTop(n)
	self.washW = getPlayerScreenWidth(n)
	self.washH = getPlayerScreenHeight(n)
	if self:getX() ~= -8 then
		self:setX(-8)
	end
	if self:getY() ~= -8 then
		self:setY(-8)
	end
	if self:getWidth() ~= 1 then
		self:setWidth(1)
	end
	if self:getHeight() ~= 1 then
		self:setHeight(1)
	end
end

function FromZoidSanityVeil:render()
	local wash = self.wash
	if not wash or not self:isVisible() then
		return
	end
	self:drawRect(self.washX + 8, self.washY + 8, self.washW, self.washH, wash.a, wash.r, wash.g, wash.b)
end

local function clickThrough(veil)
	if not veil then
		return
	end
	veil.wantMouseEvents = false
	if veil.setWantMouseEvents then
		veil:setWantMouseEvents(false)
	end
	if veil.javaObject and veil.javaObject.setConsumeMouseEvents then
		veil.javaObject:setConsumeMouseEvents(false)
	end
end

local function ensureVeil()
	if FromZoid._veil then
		clickThrough(FromZoid._veil)
		return
	end
	local veil = FromZoidSanityVeil:new()
	veil:initialise()
	veil:addToUIManager()
	clickThrough(veil)
	if veil.backMost then
		veil:backMost()
	end
	veil:setVisible(true)
	clickThrough(veil)
	FromZoid._veil = veil
end

local function pokeVeil()
	ensureVeil()
	local veil = FromZoid._veil
	if not veil then
		return
	end
	clickThrough(veil)
	if washFor(getPlayer()) then
		if not veil:isVisible() then
			veil:setVisible(true)
		end
	elseif veil:isVisible() then
		veil:setVisible(false)
	end
end

if FromZoid._veil then
	pcall(function()
		FromZoid._veil:setVisible(false)
		FromZoid._veil:removeFromUIManager()
	end)
	FromZoid._veil = nil
end

Events.OnCreatePlayer.Add(function(playerIndex)
	if FromZoid._veil then
		FromZoid._veil.playerNum = playerIndex or 0
	end
	ensureVeil()
end)
Events.OnGameStart.Add(function()
	ensureVeil()
	pokeVeil()
end)

local veilTick = 0
local wasAsleep = false
Events.OnPlayerUpdate.Add(function()
	local player = getPlayer()
	local asleep = FromZoid.playerAsleep and FromZoid.playerAsleep(player)
	if wasAsleep and not asleep then
		FromZoid.wakePlayer(player)
		pokeVeil()
	end
	wasAsleep = asleep and true or false
	if asleep then
		if FromZoid._veil and FromZoid._veil:isVisible() then
			FromZoid._veil:setVisible(false)
		end
		return
	end
	veilTick = veilTick + 1
	if veilTick < 30 then
		return
	end
	veilTick = 0
	pokeVeil()
end)
