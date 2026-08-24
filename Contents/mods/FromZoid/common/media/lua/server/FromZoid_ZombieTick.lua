if isClient() then
	return
end

Events.OnZombieUpdate.Add(function(zombie)
	if not zombie or not zombie:isAlive() then
		return
	end
	local ctx = FromZoid.refreshTickContext()
	local sliced = FromZoid.inSlice(zombie, ctx)
	local md = zombie:getModData()
	local now = FromZoid.nowMs()
	local indoor = FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie))
	if md.fromzoidAsleep and not indoor then
		FromZoid.wakeZombieBody(zombie)
	elseif not indoor then
		FromZoid.stripLaunchPoses(zombie)
	end
	if md.fromzoidStillUntil then
		if now < md.fromzoidStillUntil then
			local player = ctx.players and ctx.players[1] or nil
			FromZoid.applyStillPose(zombie, player)
			return
		end
		md.fromzoidStillUntil = nil
		FromZoid.wakeZombieBody(zombie)
	end
	if sliced then
		FromZoid.reconcileZombieState(zombie, ctx)
	elseif not indoor and zombie:isUseless() and not md.fromzoidHold then
		if not (md.fromzoidStillUntil and now < md.fromzoidStillUntil) then
			FromZoid.wakeZombieBody(zombie)
		end
	end
	if FromZoid.enforceTalisman then
		FromZoid.enforceTalisman(zombie, ctx, sliced)
	end
	if not sliced then
		if md.fromzoidHold and FromZoid.isClockNight() then
			return
		end
		if indoor and zombie:isUseless() then
			if not (md.fromzoidHuntUntil and now < md.fromzoidHuntUntil) then
				if not (ctx.loud or ctx.gunshot) then
					return
				end
			end
		end
	end
	if FromZoid.onDayZombieUpdate then
		FromZoid.onDayZombieUpdate(zombie, ctx, sliced)
	end
	if FromZoid.onCalmZombieUpdate then
		FromZoid.onCalmZombieUpdate(zombie, ctx, sliced)
	end
end)
