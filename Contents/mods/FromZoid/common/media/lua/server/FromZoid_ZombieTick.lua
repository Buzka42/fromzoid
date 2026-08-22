if isClient() then
	return
end

Events.OnZombieUpdate.Add(function(zombie)
	if not zombie or not zombie:isAlive() then
		return
	end
	local ctx = FromZoid.refreshTickContext()
	local sliced = FromZoid.inSlice(zombie, ctx)
	if FromZoid.enforceTalisman then
		FromZoid.enforceTalisman(zombie, ctx, sliced)
	end
	if FromZoid.onDayZombieUpdate then
		FromZoid.onDayZombieUpdate(zombie, ctx, sliced)
	end
	if FromZoid.onCalmZombieUpdate then
		FromZoid.onCalmZombieUpdate(zombie, ctx, sliced)
	end
end)
