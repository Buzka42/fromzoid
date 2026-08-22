local inviteTick = 0

local function refreshInvitations()
	inviteTick = inviteTick + 1
	if inviteTick < 12 then
		return
	end
	inviteTick = 0
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not FromZoid.isEnabled("InvitationRequired") then
		return
	end
	for _, player in ipairs(FromZoid.playerList()) do
		local sq = player:getCurrentSquare()
		local building = sq and sq:getBuilding() or nil
		if building and FromZoid.isBuildingSealed(building) then
			FromZoid.buildingHasInvitation(building)
		end
	end
end

Events.OnPlayerUpdate.Add(refreshInvitations)
Events.OnGameStart.Add(function()
	inviteTick = 12
	refreshInvitations()
end)
