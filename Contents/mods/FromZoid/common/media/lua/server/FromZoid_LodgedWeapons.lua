if isClient() then
	return
end

local WEAPONS = {
	"Base.Katana",
	"Base.Machete",
	"Base.WoodAxe",
	"Base.Axe",
	"Base.HandAxe",
	"Base.HuntingKnife",
	"Base.Nightstick",
}

local function itemExists(name)
	if not getScriptManager then
		return true
	end
	local sm = getScriptManager()
	if sm and sm.FindItem then
		return sm:FindItem(name) ~= nil
	end
	return true
end

local function pickWeapon()
	local katanaWeight = tonumber(FromZoid.getSandbox("LodgedKatanaWeight", 40)) or 40
	if itemExists("Base.Katana") and ZombRand(100) < katanaWeight then
		return "Base.Katana"
	end
	local usable = {}
	for i = 1, #WEAPONS do
		if itemExists(WEAPONS[i]) then
			table.insert(usable, WEAPONS[i])
		end
	end
	if #usable == 0 then
		return nil
	end
	return usable[ZombRand(#usable) + 1]
end

local function onCreate(zombie)
	if not FromZoid.isEnabled("EnableLodgedWeapons") then
		return
	end
	if not zombie or not instanceof(zombie, "IsoZombie") then
		return
	end
	local chance = tonumber(FromZoid.getSandbox("LodgedWeaponChance", 4)) or 4
	if ZombRand(100) >= chance then
		return
	end
	local name = pickWeapon()
	if not name then
		return
	end
	local inv = zombie.getInventory and zombie:getInventory() or nil
	if not inv then
		return
	end
	inv:AddItem(name)
end

Events.OnZombieCreate.Add(onCreate)
