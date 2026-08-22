local LOOT_TABLES = {
	"BedroomDresser",
	"BedroomDresserClassy",
	"BedroomDresserRedneck",
	"KitchenRandom",
	"BathroomCabinet",
	"OfficeDeskHome",
	"WardrobeRedneck",
	"WardrobeGeneric",
	"DresserGeneric",
}

local function add(procName, item, weight)
	local list = ProceduralDistributions and ProceduralDistributions.list
	if not list then
		return
	end
	local proc = list[procName]
	if not proc or not proc.items then
		return
	end
	table.insert(proc.items, item)
	table.insert(proc.items, weight)
end

Events.OnPreDistributionMerge.Add(function()
	for i = 1, #LOOT_TABLES do
		add(LOOT_TABLES[i], "FromZoid.Talisman", 0.35)
	end
end)
