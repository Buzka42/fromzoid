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
		hungNight = (getGameTime() and getGameTime():getNightsSurvived()) or 0,
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
	local building, doorSquare = FromZoid.buildingFromDoor(door)
	if not building then
		return false
	end
	local square = FromZoid.doorHangSquare(door) or doorSquare
	if not square then
		return false
	end
	if FromZoid.isBuildingSealed(building) then
		return false
	end
	local item = nil
	local inv = nil
	if player then
		inv = player:getInventory()
		item = FromZoid.findTalismanInInventory(inv)
		if not item then
			return false
		end
	end
	local hungItem = instanceItem(FromZoid.ITEM_TALISMAN)
	if not hungItem then
		return false
	end
	local ox, oy, oz = FromZoid.doorHangOffset(door, square)
	local hung = square:AddWorldInventoryItem(hungItem, ox, oy, oz)
	if not hung then
		return false
	end
	if inv and item then
		inv:Remove(item)
	end
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

function FromZoid.findRefreshHerb(inv)
	if not inv then
		return nil
	end
	local names = {
		"Base.Sage",
		"Base.DriedSage",
		"Base.DriedHerbs",
		"Base.CommonMallow",
		"Base.BlackSage",
		"Base.Ginseng",
		"Base.Plantain",
		"Base.WildGarlic2",
	}
	for i = 1, #names do
		local item = inv:getFirstTypeRecurse(names[i])
		if item then
			return item
		end
	end
	return nil
end

function FromZoid.refreshTalismanOnSquare(player, square)
	if not player or not square then
		return false
	end
	if not FromZoid.squareHasHungTalisman(square) then
		return false
	end
	local herb = FromZoid.findRefreshHerb(player:getInventory())
	if not herb then
		return false
	end
	local building = square:getBuilding()
	if not building then
		local door = FromZoid.getDoorOnSquare(square)
		building = FromZoid.buildingFromDoor(door)
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return false
	end
	player:getInventory():Remove(herb)
	local nights = (getGameTime() and getGameTime():getNightsSurvived()) or 0
	local data = FromZoid.getTalismanData()
	local entry = data[id]
	if type(entry) == "table" then
		entry.sealed = true
		entry.hungNight = nights
		entry.wilted = nil
	else
		FromZoid.sealBuilding(building, square)
	end
	local worldObjects = square:getWorldObjects()
	if worldObjects then
		for i = 0, worldObjects:size() - 1 do
			local wo = worldObjects:get(i)
			local item = wo.getItem and wo:getItem() or nil
			if item and item.getModData then
				local md = item:getModData()
				if md.fromzoid_talisman or (item.getFullType and item:getFullType() == FromZoid.ITEM_TALISMAN) then
					md.fromzoid_wilted = nil
					if item.transmitModData then
						item:transmitModData()
					end
				end
			end
		end
	end
	return true
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
	local function takeFrom(sq)
		if not sq then
			return false, nil
		end
		local worldObjects = sq:getWorldObjects()
		local taken = false
		local buildingId = nil
		if not worldObjects then
			return false, nil
		end
		for i = worldObjects:size() - 1, 0, -1 do
			local wo = worldObjects:get(i)
			local item = wo.getItem and wo:getItem() or nil
			if item then
				local md = item.getModData and item:getModData() or nil
				local full = item.getFullType and item:getFullType() or ""
				local isTalisman = (md and md.fromzoid_talisman) or full == FromZoid.ITEM_TALISMAN
				if isTalisman then
					buildingId = md and md.fromzoid_building or nil
					if sq.removeWorldObject then
						sq:removeWorldObject(wo)
					elseif wo.removeFromSquare then
						wo:removeFromSquare()
					end
					player:getInventory():AddItem(item)
					taken = true
				end
			end
		end
		return taken, buildingId
	end
	local taken, buildingId = takeFrom(square)
	local door = FromZoid.getDoorOnSquare(square)
	if door then
		local other = FromZoid.doorHangSquare(door)
		if other and other ~= square then
			local taken2, id2 = takeFrom(other)
			taken = taken or taken2
			buildingId = buildingId or id2
		end
		local opp = door.getOppositeSquare and door:getOppositeSquare() or nil
		if opp and opp ~= square then
			local taken3, id3 = takeFrom(opp)
			taken = taken or taken3
			buildingId = buildingId or id3
		end
	end
	if not taken then
		return false
	end
	if not buildingId then
		buildingId = FromZoid.buildingId(square:getBuilding())
	end
	FromZoid.unsealBuildingId(buildingId)
	return true
end
