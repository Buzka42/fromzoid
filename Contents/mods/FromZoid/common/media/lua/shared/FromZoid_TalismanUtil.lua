function FromZoid.unsealBuildingId(id)
	if not id then
		return
	end
	FromZoid.getTalismanData()[id] = nil
end

function FromZoid.sealBuilding(building, square)
	local id = FromZoid.buildingId(building)
	if not id or not square then
		return false
	end
	FromZoid.getTalismanData()[id] = {
		sealed = true,
		x = square:getX(),
		y = square:getY(),
		z = square:getZ(),
	}
	return true
end

function FromZoid.hangTalismanOnSquare(player, square)
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	if not player or not square then
		return false
	end
	local building = square:getBuilding()
	if not building then
		return false
	end
	if FromZoid.isBuildingSealed(building) then
		return false
	end
	local inv = player:getInventory()
	local item = inv:getFirstTypeRecurse(FromZoid.ITEM_TALISMAN)
	if not item and inv.getFirstTagRecurse then
		item = inv:getFirstTagRecurse("fromzoidtalisman")
	end
	if not item then
		return false
	end
	inv:Remove(item)
	local worldItem = square:AddWorldInventoryItem(item, 0.2, 0.2, 0.6)
	if worldItem then
		worldItem:getModData().fromzoid_talisman = true
		worldItem:getModData().fromzoid_building = FromZoid.buildingId(building)
		if worldItem.transmitModData then
			worldItem:transmitModData()
		end
	end
	return FromZoid.sealBuilding(building, square)
end

function FromZoid.takeTalismanFromSquare(player, square)
	if not player or not square then
		return false
	end
	local worldObjects = square:getWorldObjects()
	local taken = false
	local buildingId = nil
	if worldObjects then
		for i = worldObjects:size() - 1, 0, -1 do
			local wo = worldObjects:get(i)
			local item = wo.getItem and wo:getItem() or nil
			if item and item:getModData() and item:getModData().fromzoid_talisman then
				buildingId = item:getModData().fromzoid_building
				if square.removeWorldObject then
					square:removeWorldObject(wo)
				elseif wo.removeFromSquare then
					wo:removeFromSquare()
				end
				player:getInventory():AddItem(item)
				taken = true
			end
		end
	end
	if not buildingId then
		buildingId = FromZoid.buildingId(square:getBuilding())
	end
	FromZoid.unsealBuildingId(buildingId)
	return taken
end
