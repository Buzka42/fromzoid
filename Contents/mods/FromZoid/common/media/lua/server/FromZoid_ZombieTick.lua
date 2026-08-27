if isClient() then
	return
end

Events.OnZombieUpdate.Add(function(zombie)
	if not zombie or not zombie:isAlive() then
		return
	end
	local md = zombie:getModData()
	-- Never removeFromWorld inside OnZombieCreate; that can hard-crash while
	-- a cell is streaming. Flag there, drop them on the first real tick.
	if md.fromzoidEvict then
		FromZoid.removeZombieQuiet(zombie)
		return
	end
	local ctx = FromZoid.refreshTickContext()
	local sliced = FromZoid.inSlice(zombie, ctx)
	local now = FromZoid.nowMs()
	local indoor = FromZoid.squareIsIndoorHide(FromZoid.zombieSquare(zombie))
	local wakeSleeper = md.fromzoidAsleep and indoor and FromZoid.sleeperShouldWake(zombie, ctx)
	if md.fromzoidAsleep and (not indoor or wakeSleeper) then
		FromZoid.wakeZombieBody(zombie)
		if wakeSleeper then
			local nearest, nearestD = nil, 99
			if ctx.players then
				for i = 1, #ctx.players do
					local p = ctx.players[i]
					local d = zombie.DistTo and zombie:DistTo(p) or 99
					if d < nearestD then
						nearestD = d
						nearest = p
					end
				end
			end
			if nearest and zombie.setTarget then
				zombie:setTarget(nearest)
			end
			if FromZoid.markZombieHunting then
				FromZoid.markZombieHunting(zombie, 25000)
			end
		end
	elseif md.fromzoidAsleep then
		FromZoid.pinZombieSleepPose(zombie)
	elseif not indoor then
		FromZoid.stripLaunchPoses(zombie)
	end
	if FromZoid.onUltraStrongUpdate then
		FromZoid.onUltraStrongUpdate(zombie)
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
	-- Vanilla defaults canOpenDoors to false and may reset it. Keep ordinary
	-- doors usable except while the talisman field has them held or loitering.
	if sliced and not md.fromzoidHold and not md.fromzoidLoiter and not FromZoid.isWhisperWalker(zombie) then
		if zombie.setCanOpenDoors then
			pcall(function()
				zombie:setCanOpenDoors(true)
			end)
		end
	end
	-- Held means enforceTalisman just froze them in the talisman field, day
	-- or night. Nothing downstream may undo that: the day pass used to
	-- release the hold every tick, which is what left them free to charge.
	if md.fromzoidHold then
		return
	end
	if not sliced then
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
