local OUTFITS = { "Generic01", "Student", "Young", "HonorStudent" }

local MALE_VOICES = { "Vlad", "Miles", "Knox" }
local FEMALE_VOICES = { "Roxie", "Annie", "Zelda" }

local function pickOutfit()
	return OUTFITS[ZombRand(#OUTFITS) + 1]
end

local function assignVoice(zombie)
	local md = zombie:getModData()
	local female = zombie.isFemale and zombie:isFemale()
	local pool = female and FEMALE_VOICES or MALE_VOICES
	local current = md.fromzoidVoice
	if current then
		for i = 1, #pool do
			if pool[i] == current then
				return
			end
		end
	end
	md.fromzoidVoice = pool[ZombRand(#pool) + 1]
end

local function cleanVisuals(zombie)
	pcall(function()
		local hv = zombie:getHumanVisual()
		if hv then
			if hv.removeBlood then
				hv:removeBlood()
			end
			if hv.removeDirt then
				hv:removeDirt()
			end
			if hv.setBlood then
				hv:setBlood(0)
			end
			if hv.setDirt then
				hv:setDirt(0)
			end
		end
	end)
	pcall(function()
		local visuals = zombie:getItemVisuals()
		if visuals then
			for i = 0, visuals:size() - 1 do
				local vis = visuals:get(i)
				if vis then
					if vis.setBlood then
						vis:setBlood(0)
					end
					if vis.setDirt then
						vis:setDirt(0)
					end
					if vis.removeBlood then
						vis:removeBlood()
					end
				end
			end
		end
	end)
	if zombie.resetModelNextFrame then
		pcall(function()
			zombie:resetModelNextFrame()
		end)
	end
end

local function dressLikePerson(zombie)
	if not zombie or not instanceof(zombie, "IsoZombie") then
		return
	end
	pcall(function()
		zombie:dressInNamedOutfit(pickOutfit())
	end)
	cleanVisuals(zombie)
	if zombie.setReanimatedPlayer then
		pcall(function()
			zombie:setReanimatedPlayer(true)
		end)
	end
	if zombie.setCrawler then
		zombie:setCrawler(false)
	end
	if zombie.setCanWalk then
		pcall(function()
			zombie:setCanWalk(true)
		end)
	end
	assignVoice(zombie)
end

Events.OnZombieCreate.Add(dressLikePerson)
