if isClient() then
	return
end

local function alreadyDone(square)
	local data = FromZoid.getSquareData()
	local key = square:getX() .. "_" .. square:getY() .. "_" .. square:getZ()
	if data[key] then
		return true
	end
	data[key] = true
	return false
end

local function isPlayerBuilt(obj)
	if not obj then
		return false
	end
	if obj.isPlayerPlaced and obj:isPlayerPlaced() then
		return true
	end
	if instanceof(obj, "IsoThumpable") then
		return true
	end
	return false
end

-- Returns true only if planks actually went on, so callers can tell the
-- difference between "boarded it" and "silently did nothing".
local function addPlanks(target, count)
	if not target or not IsoBarricade or not IsoBarricade.AddBarricadeToObject then
		return false
	end
	if target.isBarricadeAllowed then
		local ok, allowed = pcall(function()
			return target:isBarricadeAllowed()
		end)
		if ok and not allowed then
			return false
		end
	end
	if target.isBarricaded then
		local ok, already = pcall(function()
			return target:isBarricaded()
		end)
		if ok and already then
			return false
		end
	end
	local barricade = IsoBarricade.AddBarricadeToObject(target, false)
	if not barricade then
		return false
	end
	count = count or (1 + ZombRand(3))
	local planked = 0
	for _ = 1, count do
		if barricade.canAddPlank and not barricade:canAddPlank() then
			break
		end
		barricade:addPlank(nil, nil)
		planked = planked + 1
	end
	if barricade.transmitCompleteItemToClients then
		barricade:transmitCompleteItemToClients()
	end
	return planked > 0
end

local function smashWindow(obj)
	if obj.setSmashed then
		obj:setSmashed(true)
	elseif obj.smashWindow then
		obj:smashWindow()
	end
end

-- Board the spawn house so the survivor wakes in a place someone already
-- fortified. One exterior door is deliberately left clear: barricades need a
-- hammer to remove, and a fresh character has nothing, so boarding every way
-- out would seal them in their own start house.
function FromZoid.boardUpBuilding(building)
	if not building then
		return 0
	end
	if not IsoBarricade or not IsoBarricade.AddBarricadeToObject then
		return 0
	end
	local def = FromZoid.getBuildingDef(building)
	local cell = getCell()
	if not def or not def.getX or not cell then
		return 0
	end
	local x1 = def:getX() - 1
	local y1 = def:getY() - 1
	local x2 = (def.getX2 and def:getX2() or def:getX()) + 1
	local y2 = (def.getY2 and def:getY2() or def:getY()) + 1
	local zTop = 1
	if def.getMaxLevel then
		local m = def:getMaxLevel()
		if m and m > zTop then
			zTop = m
		end
	end
	local doors = {}
	local windows = {}
	for z = 0, zTop do
		for x = x1, x2 do
			for y = y1, y2 do
				local sq = cell:getGridSquare(x, y, z)
				local objects = sq and sq:getObjects() or nil
				if objects then
					for i = 0, objects:size() - 1 do
						local obj = objects:get(i)
						if not isPlayerBuilt(obj) and FromZoid.openingIsExterior(obj) then
							if instanceof(obj, "IsoDoor") then
								doors[#doors + 1] = obj
							elseif instanceof(obj, "IsoWindow") then
								windows[#windows + 1] = obj
							end
						end
					end
				end
			end
		end
	end
	if #doors == 0 and #windows == 0 then
		return 0
	end
	-- Prefer leaving the talisman door clear, so the one way out is the one
	-- the charm hangs on.
	local free = nil
	local talismanDoor = FromZoid.firstDoorInBuilding(building)
	for i = 1, #doors do
		if doors[i] == talismanDoor then
			free = doors[i]
			break
		end
	end
	if not free and #doors > 0 then
		free = doors[1]
	end
	-- No exterior door at all: board windows only rather than risk trapping.
	local n = 0
	for i = 1, #doors do
		if doors[i] ~= free and addPlanks(doors[i], 2 + ZombRand(3)) then
			n = n + 1
		end
	end
	for i = 1, #windows do
		if addPlanks(windows[i], 2 + ZombRand(3)) then
			n = n + 1
		end
	end
	return n
end

local function processSquare(square)
	if not square then
		return
	end
	if isClient() then
		return
	end
	if not FromZoid.isEnabled("EnableTown") then
		return
	end
	if square:getZ() ~= 0 then
		return
	end
	local building = square:getBuilding()
	if not building then
		return
	end
	if FromZoid.isBuildingSealed(building) then
		return
	end
	local spawnId = FromZoid.getState().spawnBuildingId
	if spawnId and FromZoid.buildingId(building) == spawnId then
		return
	end
	if not FromZoid.isResidentialBuilding(building) then
		return
	end
	local kind = FromZoid.getClusterKind(square:getX(), square:getY())
	if kind == "none" then
		return
	end
	if alreadyDone(square) then
		return
	end
	local objects = square:getObjects()
	if not objects then
		return
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if not isPlayerBuilt(obj) then
			if kind == "boarded" then
				if instanceof(obj, "IsoWindow") or instanceof(obj, "IsoDoor") then
					addPlanks(obj, 2 + ZombRand(3))
				end
			elseif kind == "damaged" then
				if instanceof(obj, "IsoWindow") then
					smashWindow(obj)
				end
			end
		end
	end
	if kind == "damaged" and square:getRoom() then
		if ZombRand(100) < 12 then
			local junk = { "Base.Sheet", "Base.RippedSheets", "Base.EmptyTinCan", "Base.Newspaper" }
			square:AddWorldInventoryItem(junk[ZombRand(#junk) + 1], ZombRand(100) / 100, ZombRand(100) / 100, 0)
		end
		if ZombRand(1000) < 4 and createRandomDeadBody then
			pcall(createRandomDeadBody, square, 4)
		end
	end
end

Events.LoadGridsquare.Add(processSquare)
