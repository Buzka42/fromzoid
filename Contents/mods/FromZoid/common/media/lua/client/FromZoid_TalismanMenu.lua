require "TimedActions/ISBaseTimedAction"

FromZoidHangTalismanAction = ISBaseTimedAction:derive("FromZoidHangTalismanAction")

function FromZoidHangTalismanAction:isValid()
	if not self.square or not self.character then
		return false
	end
	if not self.square:getBuilding() then
		return false
	end
	local inv = self.character:getInventory()
	return inv:getFirstTypeRecurse(FromZoid.ITEM_TALISMAN) ~= nil
end

function FromZoidHangTalismanAction:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function FromZoidHangTalismanAction:update()
	self.character:faceLocation(self.square:getX(), self.square:getY())
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
	FromZoid.hangTalismanOnSquare(self.character, self.square)
	HaloTextHelper.addGoodText(self.character, getText("IGUI_FromZoid_TalismanHung"))
	ISBaseTimedAction.perform(self)
end

function FromZoidHangTalismanAction:new(character, square)
	local o = ISBaseTimedAction.new(self, character)
	o.square = square
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
		if item and item:getModData() and item:getModData().fromzoid_talisman then
			return true
		end
	end
	return false
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
	local square = nil
	if worldobjects then
		for i = 1, #worldobjects do
			local obj = worldobjects[i]
			if obj and obj.getSquare then
				square = obj:getSquare()
				if square then
					break
				end
			end
		end
	end
	if not square then
		square = player:getCurrentSquare()
	end
	if not square then
		return
	end
	if squareHasHungTalisman(square) then
		context:addOption(getText("ContextMenu_FromZoid_TakeTalisman"), square, function(sq)
			ISTimedActionQueue.add(FromZoidTakeTalismanAction:new(player, sq))
		end)
		return
	end
	local hasItem = player:getInventory():getFirstTypeRecurse(FromZoid.ITEM_TALISMAN) ~= nil
	if not hasItem then
		return
	end
	if not square:getBuilding() then
		return
	end
	local option = context:addOption(getText("ContextMenu_FromZoid_HangTalisman"), square, function(sq)
		if FromZoid.isBuildingSealed(sq:getBuilding()) then
			HaloTextHelper.addBadText(player, getText("IGUI_FromZoid_AlreadySealed"))
			return
		end
		ISTimedActionQueue.add(FromZoidHangTalismanAction:new(player, sq))
	end)
	if FromZoid.isBuildingSealed(square:getBuilding()) then
		option.notAvailable = true
		local tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description = getText("IGUI_FromZoid_AlreadySealed")
		option.toolTip = tooltip
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
