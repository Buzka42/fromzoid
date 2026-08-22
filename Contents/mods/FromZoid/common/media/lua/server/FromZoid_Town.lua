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

local function addPlanks(target, count)
	if not target or not IsoBarricade or not IsoBarricade.AddBarricadeToObject then
		return
	end
	local barricade = IsoBarricade.AddBarricadeToObject(target, false)
	if not barricade then
		return
	end
	count = count or (1 + ZombRand(3))
	for _ = 1, count do
		if barricade.canAddPlank and not barricade:canAddPlank() then
			break
		end
		barricade:addPlank(nil, nil)
	end
	if barricade.transmitCompleteItemToClients then
		barricade:transmitCompleteItemToClients()
	end
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
	if not square:getBuilding() then
		return
	end
	if alreadyDone(square) then
		return
	end
	local smashChance = FromZoid.getSandbox("WindowSmashChance", 45)
	local boardChance = FromZoid.getSandbox("BarricadeChance", 28)
	local objects = square:getObjects()
	if not objects then
		return
	end
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if not isPlayerBuilt(obj) then
			if instanceof(obj, "IsoWindow") then
				if ZombRand(100) < smashChance then
					if obj.setSmashed then
						obj:setSmashed(true)
					elseif obj.smashWindow then
						obj:smashWindow()
					end
				end
				if ZombRand(100) < boardChance then
					addPlanks(obj, 1 + ZombRand(3))
				end
			elseif instanceof(obj, "IsoDoor") then
				if ZombRand(100) < boardChance then
					addPlanks(obj, 1 + ZombRand(2))
				end
			end
		end
	end
	if square:getRoom() and ZombRand(1000) < 8 then
		local junk = { "Base.Sheet", "Base.RippedSheets", "Base.EmptyTinCan", "Base.Newspaper" }
		square:AddWorldInventoryItem(junk[ZombRand(#junk) + 1], ZombRand(100) / 100, ZombRand(100) / 100, 0)
	end
	if square:getRoom() and ZombRand(1000) < 2 and createRandomDeadBody then
		pcall(createRandomDeadBody, square, 4)
	end
end

Events.LoadGridsquare.Add(processSquare)
