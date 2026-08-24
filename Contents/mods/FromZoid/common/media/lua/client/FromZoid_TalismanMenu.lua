require "TimedActions/ISBaseTimedAction"

FromZoidHangTalismanAction = ISBaseTimedAction:derive("FromZoidHangTalismanAction")

function FromZoidHangTalismanAction:isValid()
	if not self.door or not self.character then
		return false
	end
	if not FromZoid.findTalismanInInventory(self.character:getInventory()) then
		return false
	end
	local building = FromZoid.buildingFromDoor(self.door)
	if building and FromZoid.isBuildingSealed(building) then
		return false
	end
	return true
end

function FromZoidHangTalismanAction:waitToStart()
	local square = self.door:getSquare()
	if square then
		self.character:faceLocation(square:getX(), square:getY())
	end
	return self.character:shouldBeTurning()
end

function FromZoidHangTalismanAction:update()
	local square = self.door:getSquare()
	if square then
		self.character:faceLocation(square:getX(), square:getY())
	end
	self.character:setMetabolicTarget(Metabolics.LightWork)
end

function FromZoidHangTalismanAction:start()
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "High")
end

function FromZoidHangTalismanAction:stop()
	ISBaseTimedAction.stop(self)
end

function FromZoidHangTalismanAction:perform()
	if FromZoid.hangTalismanOnDoor(self.character, self.door) then
		HaloTextHelper.addGoodText(self.character, FromZoid.text("IGUI_FromZoid_TalismanHung"))
	else
		HaloTextHelper.addBadText(self.character, FromZoid.text("IGUI_FromZoid_AlreadySealed"))
	end
	ISBaseTimedAction.perform(self)
end

function FromZoidHangTalismanAction:new(character, door)
	local o = ISBaseTimedAction.new(self, character)
	o.door = door
	o.maxTime = 50
	o.stopOnWalk = true
	o.stopOnRun = true
	return o
end

FromZoidTakeTalismanAction = ISBaseTimedAction:derive("FromZoidTakeTalismanAction")

function FromZoidTakeTalismanAction:isValid()
	return self.square ~= nil and self.character ~= nil and FromZoid.squareHasHungTalisman(self.square)
end

function FromZoidTakeTalismanAction:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function FromZoidTakeTalismanAction:start()
	self:setActionAnim("Loot")
end

function FromZoidTakeTalismanAction:stop()
	ISBaseTimedAction.stop(self)
end

function FromZoidTakeTalismanAction:perform()
	if FromZoid.takeTalismanFromSquare(self.character, self.square) then
		HaloTextHelper.addBadText(self.character, FromZoid.text("IGUI_FromZoid_TalismanRemoved"))
	end
	ISBaseTimedAction.perform(self)
end

function FromZoidTakeTalismanAction:new(character, square)
	local o = ISBaseTimedAction.new(self, character)
	o.square = square
	o.maxTime = 30
	o.stopOnWalk = true
	o.stopOnRun = true
	return o
end

FromZoidRefreshTalismanAction = ISBaseTimedAction:derive("FromZoidRefreshTalismanAction")

function FromZoidRefreshTalismanAction:isValid()
	return self.square ~= nil and self.character ~= nil and FromZoid.squareHasHungTalisman(self.square) and FromZoid.findRefreshHerb(self.character:getInventory()) ~= nil
end

function FromZoidRefreshTalismanAction:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function FromZoidRefreshTalismanAction:start()
	self:setActionAnim("Loot")
end

function FromZoidRefreshTalismanAction:stop()
	ISBaseTimedAction.stop(self)
end

function FromZoidRefreshTalismanAction:perform()
	if FromZoid.refreshTalismanOnSquare(self.character, self.square) then
		HaloTextHelper.addGoodText(self.character, FromZoid.text("IGUI_FromZoid_TalismanRefreshed"))
	else
		HaloTextHelper.addBadText(self.character, FromZoid.text("IGUI_FromZoid_NeedHerb"))
	end
	ISBaseTimedAction.perform(self)
end

function FromZoidRefreshTalismanAction:new(character, square)
	local o = ISBaseTimedAction.new(self, character)
	o.square = square
	o.maxTime = 40
	o.stopOnWalk = true
	o.stopOnRun = true
	return o
end

local function doorFromContext(worldobjects)
	if not worldobjects then
		return nil
	end
	for i = 1, #worldobjects do
		local obj = worldobjects[i]
		if instanceof(obj, "IsoDoor") then
			return obj
		end
	end
	return nil
end

local function onFillWorld(playerIndex, context, worldobjects, test)
	if test then
		return
	end
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	local player = getSpecificPlayer(playerIndex)
	if not player then
		return
	end
	local door = doorFromContext(worldobjects)
	if not door then
		return
	end
	local square = door:getSquare()
	if not square then
		return
	end
	local hangSq = FromZoid.doorHangSquare(door) or square
	if FromZoid.squareHasHungTalisman(hangSq) or FromZoid.squareHasHungTalisman(square) then
		context:addOption(FromZoid.text("ContextMenu_FromZoid_TakeTalisman"), hangSq, function(sq)
			ISTimedActionQueue.add(FromZoidTakeTalismanAction:new(player, sq))
		end)
		if FromZoid.isEnabled("EnableWornCharms") then
			local herb = FromZoid.findRefreshHerb(player:getInventory())
			local opt = context:addOption(FromZoid.text("ContextMenu_FromZoid_RefreshTalisman"), hangSq, function(sq)
				ISTimedActionQueue.add(FromZoidRefreshTalismanAction:new(player, sq))
			end)
			if not herb then
				opt.notAvailable = true
				local tooltip = ISWorldObjectContextMenu.addToolTip()
				tooltip.description = FromZoid.text("IGUI_FromZoid_NeedHerb")
				opt.toolTip = tooltip
			end
		end
		return
	end
	if not FromZoid.findTalismanInInventory(player:getInventory()) then
		return
	end
	local building = FromZoid.buildingFromDoor(door)
	if not building then
		return
	end
	local option = context:addOption(FromZoid.text("ContextMenu_FromZoid_HangTalisman"), door, function(d)
		if FromZoid.isBuildingSealed(FromZoid.buildingFromDoor(d)) then
			HaloTextHelper.addBadText(player, FromZoid.text("IGUI_FromZoid_AlreadySealed"))
			return
		end
		ISTimedActionQueue.add(FromZoidHangTalismanAction:new(player, d))
	end)
	if FromZoid.isBuildingSealed(building) then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = FromZoid.text("IGUI_FromZoid_AlreadySealed")
		option.toolTip = tooltip
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
