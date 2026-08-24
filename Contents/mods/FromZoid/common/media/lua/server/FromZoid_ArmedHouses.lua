if isClient() then
	return
end

local HANDGUNS = {
	{ gun = "Base.Pistol", ammo = "Base.Bullets9mm", box = "Base.Bullets9mmBox", mag = "Base.9mmClip" },
	{ gun = "Base.Pistol2", ammo = "Base.Bullets45", box = "Base.Bullets45Box", mag = "Base.45Clip" },
	{ gun = "Base.Pistol3", ammo = "Base.Bullets44", box = "Base.Bullets44Box", mag = "Base.44Clip" },
	{ gun = "Base.Revolver", ammo = "Base.Bullets45", box = "Base.Bullets45Box" },
	{ gun = "Base.Revolver_Short", ammo = "Base.Bullets38", box = "Base.Bullets38Box" },
	{ gun = "Base.Revolver_Long", ammo = "Base.Bullets44", box = "Base.Bullets44Box" },
}

local LONGS = {
	{ gun = "Base.Shotgun", ammo = "Base.ShotgunShells", box = "Base.ShotgunShellsBox" },
	{ gun = "Base.DoubleBarrelShotgun", ammo = "Base.ShotgunShells", box = "Base.ShotgunShellsBox" },
	{ gun = "Base.HuntingRifle", ammo = "Base.308Bullets", box = "Base.308Box" },
	{ gun = "Base.VarmintRifle", ammo = "Base.556Bullets", box = "Base.556Box" },
	{ gun = "Base.AssaultRifle", ammo = "Base.556Bullets", box = "Base.556Box", mag = "Base.556Clip" },
	{ gun = "Base.AssaultRifle2", ammo = "Base.308Bullets", box = "Base.308Box", mag = "Base.M14Clip" },
}

local function itemExists(name)
	if not name or not getScriptManager then
		return false
	end
	local sm = getScriptManager()
	if sm and sm.FindItem then
		return sm:FindItem(name) ~= nil
	end
	return true
end

local function pickValid(list)
	local usable = {}
	for i = 1, #list do
		if itemExists(list[i].gun) then
			table.insert(usable, list[i])
		end
	end
	if #usable == 0 then
		return nil
	end
	return usable[ZombRand(#usable) + 1]
end

local function isGunContainer(container)
	if not container then
		return false
	end
	local typ = ""
	if container.getType then
		typ = string.lower(tostring(container:getType() or ""))
	end
	if typ == "" and container.getContainerType then
		typ = string.lower(tostring(container:getContainerType() or ""))
	end
	if typ:find("fridge") or typ:find("freezer") or typ:find("stove") or typ:find("microwave") or typ:find("oven") then
		return false
	end
	return typ:find("dresser") or typ:find("wardrobe") or typ:find("crate") or typ:find("sidetable") or typ:find("counter") or typ:find("shelf") or typ:find("desk") or typ == ""
end

local function addLoadedMag(container, magType)
	if not magType or not itemExists(magType) then
		return
	end
	local mag = container:AddItem(magType)
	if mag then
		pcall(function()
			local max = mag.getMaxAmmo and mag:getMaxAmmo() or 0
			if max and max > 0 and mag.setCurrentAmmoCount then
				mag:setCurrentAmmoCount(max)
			end
		end)
	end
end

local function addKit(container, kit, reloads)
	if not kit then
		return
	end
	container:AddItem(kit.gun)
	reloads = math.max(1, reloads or 1)
	if kit.mag and itemExists(kit.mag) then
		for _ = 1, reloads do
			addLoadedMag(container, kit.mag)
		end
	end
	if kit.box and itemExists(kit.box) then
		for _ = 1, reloads do
			container:AddItem(kit.box)
		end
		return
	end
	if kit.ammo and itemExists(kit.ammo) then
		for _ = 1, 8 do
			container:AddItem(kit.ammo)
		end
	end
end

local function armedData()
	return ModData.getOrCreate("FromZoidArmed")
end

local function processSquare(square)
	if not square or isClient() then
		return
	end
	if not FromZoid.isEnabled("EnableArmedHouses") then
		return
	end
	local building = square:getBuilding()
	if not building or not FromZoid.isResidentialBuilding(building) then
		return
	end
	local id = FromZoid.buildingId(building)
	if not id then
		return
	end
	local data = armedData()
	if data[id] then
		return
	end
	local objects = square:getObjects()
	if not objects then
		return
	end
	local container = nil
	for i = 0, objects:size() - 1 do
		local obj = objects:get(i)
		if obj and obj.getContainer then
			local c = obj:getContainer()
			if c and isGunContainer(c) then
				container = c
				break
			end
		end
	end
	if not container then
		return
	end
	data[id] = true
	local armedPct = tonumber(FromZoid.getSandbox("HandgunHouseChance", 25)) or 25
	if ZombRand(100) >= armedPct then
		return
	end
	local reloads = tonumber(FromZoid.getSandbox("GunAmmoReloads", 1)) or 1
	local longPct = tonumber(FromZoid.getSandbox("LongGunHouseChance", 12)) or 12
	local kit = nil
	if ZombRand(100) < longPct then
		kit = pickValid(LONGS) or pickValid(HANDGUNS)
	else
		kit = pickValid(HANDGUNS) or pickValid(LONGS)
	end
	addKit(container, kit, reloads)
end

Events.LoadGridsquare.Add(processSquare)
