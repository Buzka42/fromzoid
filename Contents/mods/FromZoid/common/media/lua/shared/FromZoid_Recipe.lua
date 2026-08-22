FromZoid_Recipe = FromZoid_Recipe or {}

function FromZoid_Recipe.canCraftTalisman(recipe, character, item)
	if not FromZoid or not FromZoid.isEnabled then
		return true
	end
	if not FromZoid.isEnabled("EnableTalismans") then
		return false
	end
	return FromZoid.isEnabled("TalismanCraftable")
end
