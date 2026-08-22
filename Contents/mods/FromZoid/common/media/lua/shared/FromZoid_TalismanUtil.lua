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
	if FromZoid.isEnabled("TalismanDebug") then
		print("[FromZoid] sealed " .. tostring(id) .. " at " .. square:getX() .. "," .. square:getY() .. "," .. square:getZ())
	end
	return true
end

function FromZoid.buildingFromDoor(door)
	if not door then
		return nil, nil
	end
	local square = door.getSquare and door:getSquare() or nil
	if square and square:getBuilding() then
		return square:getBuilding(), square
	end
	local opp = door.getOppositeSquare and door:getOppositeSquare() or nil
	if opp and opp:getBuilding() then
		return opp:getBuilding(), square or opp
	end
	return nil, square
end

function FromZoid.findTalismanInInventory(inv)
	if not inv then
		return nil
	end
	local item = inv:getFirstTypeRecurse(FromZoid.ITEM_TALISMAN)
	if item then
		return item
	end
	if inv.getFirstTypeRecurse then
		item = inv:getFirstTypeRecurse("Talisman")
		if item then
			return item
		end
	end
	if inv.getFirstTagRecurse then
		item = inv:getFirstTagRecurse("fromzoidtalisman")
		if item then
			return item
		end
	end
	if not inv.getItems then
		return nil
	end
	local items = inv:getItems()
	if not items then
		return nil
	end
	for i = 0, items:size() - 1 do
		local it = items:get(i)
		if it then
			local full = it.getFullType and it:getFullType() or ""
			if full == FromZoid.ITEM_TALISMAN or (it.hasTag and it:hasTag("fromzoidtalisman")) then
				return it
			end
			if it.getInventory then
				local nested = FromZoid.findTalismanInInventory(it:getInventory())
				if nested then
					return nested
				end
			end
		end
	end
	return nil
end

function FromZoid.hangTalismanOnDoor(player, door)
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	if not door or not instanceof(door, "IsoDoor") then
		return false
	end
	local building, square = FromZoid.buildingFromDoor(door)
	if not building or not square then
		return false
	end
	if FromZoid.isBuildingSealed(building) then
		return false
	end
	local item = nil
	if player then
		local inv = player:getInventory()
		item = FromZoid.findTalismanInInventory(inv)
		if not item then
			return false
		end
		inv:Remove(item)
	else
		item = instanceItem(FromZoid.ITEM_TALISMAN)
	end
	if not item then
		return false
	end
	local hung = square:AddWorldInventoryItem(item, 0.45, 0.08, 0.85)
	local worldItem = hung
	if hung and hung.getItem then
		worldItem = hung:getItem() or hung
	end
	if worldItem and worldItem.getModData then
		local md = worldItem:getModData()
		md.fromzoid_talisman = true
		md.fromzoid_building = FromZoid.buildingId(building)
		if worldItem.transmitModData then
			worldItem:transmitModData()
		end
	end
	return FromZoid.sealBuilding(building, square)
end

function FromZoid.hangTalismanOnSquare(player, square)
	local door = FromZoid.getDoorOnSquare(square)
	if not door then
		return false
	end
	return FromZoid.hangTalismanOnDoor(player, door)
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
			if item then
				local md = item.getModData and item:getModData() or nil
				local full = item.getFullType and item:getFullType() or ""
				local isTalisman = (md and md.fromzoid_talisman) or full == FromZoid.ITEM_TALISMAN
				if isTalisman then
					buildingId = md and md.fromzoid_building or nil
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
	end
	if not buildingId then
		buildingId = FromZoid.buildingId(square:getBuilding())
	end
	FromZoid.unsealBuildingId(buildingId)
	return taken
end
