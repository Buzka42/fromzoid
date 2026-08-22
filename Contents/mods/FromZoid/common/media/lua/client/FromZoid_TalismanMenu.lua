require "TimedActions/ISBaseTimedAction"

FromZoidHangTalismanAction = ISBaseTimedAction:derive("FromZoidHangTalismanAction")

function FromZoidHangTalismanAction:isValid()
	if not self.door or not self.character then
		return false
	end
	return FromZoid.findTalismanInInventory(self.character:getInventory()) ~= nil
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
	FromZoid.hangTalismanOnDoor(self.character, self.door)
	HaloTextHelper.addGoodText(self.character, getText("IGUI_FromZoid_TalismanHung"))
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
	return self.square ~= nil and self.character ~= nil
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
	FromZoid.takeTalismanFromSquare(self.character, self.square)
	HaloTextHelper.addBadText(self.character, getText("IGUI_FromZoid_TalismanRemoved"))
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

local function squareHasHungTalisman(square)
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
	if squareHasHungTalisman(square) then
		context:addOption(getText("ContextMenu_FromZoid_TakeTalisman"), square, function(sq)
			ISTimedActionQueue.add(FromZoidTakeTalismanAction:new(player, sq))
		end)
		return
	end
	if not FromZoid.findTalismanInInventory(player:getInventory()) then
		return
	end
	local building = FromZoid.buildingFromDoor(door)
	if not building then
		return
	end
	local option = context:addOption(getText("ContextMenu_FromZoid_HangTalisman"), door, function(d)
		if FromZoid.isBuildingSealed(FromZoid.buildingFromDoor(d)) then
			HaloTextHelper.addBadText(player, getText("IGUI_FromZoid_AlreadySealed"))
			return
		end
		ISTimedActionQueue.add(FromZoidHangTalismanAction:new(player, d))
	end)
	if FromZoid.isBuildingSealed(building) then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("IGUI_FromZoid_AlreadySealed")
		option.toolTip = tooltip
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
