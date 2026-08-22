local function refreshInvitations()
	FromZoid._openSeals = {}
	if not FromZoid.isEnabled("EnableTalismans") then
		return
	end
	if not FromZoid.isEnabled("InvitationRequired") then
		return
	end
	local cell = getCell()
	if not cell then
		return
	end
	local seen = {}
	for _, player in ipairs(FromZoid.playerList()) do
		local px = math.floor(player:getX())
		local py = math.floor(player:getY())
		for dx = -20, 20, 4 do
			for dy = -20, 20, 4 do
				local sq = cell:getGridSquare(px + dx, py + dy, 0)
				local building = sq and sq:getBuilding()
				local id = FromZoid.buildingId(building)
				if id and not seen[id] and FromZoid.isBuildingSealed(building) then
					seen[id] = true
					if FromZoid.scanBuildingInvitation(building) then
						FromZoid._openSeals[id] = true
					end
				end
			end
		end
	end
end

Events.EveryOneMinute.Add(refreshInvitations)
Events.OnGameStart.Add(refreshInvitations)
