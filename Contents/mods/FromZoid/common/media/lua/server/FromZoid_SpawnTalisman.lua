if isClient() then
	return
end

Events.OnNewGame.Add(function(player, square)
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not player then
		return
	end
	square = square or player:getCurrentSquare()
	local building = square and square:getBuilding() or nil
	if building and not FromZoid.isBuildingSealed(building) then
		local door = FromZoid.firstDoorInBuilding(building)
		if door then
			FromZoid.hangTalismanOnDoor(nil, door)
		end
	end
	if FromZoid.isEnabled("StartWithSpareTalisman") then
		player:getInventory():AddItem(FromZoid.ITEM_TALISMAN)
	end
end)
