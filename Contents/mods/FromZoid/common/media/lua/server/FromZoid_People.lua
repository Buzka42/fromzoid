local OUTFITS = {
	"Generic01",
	"Generic02",
	"Generic03",
	"Student",
	"Young",
	"DressLong",
	"OfficeWorker",
	"Classy",
	"HonorStudent",
}

local MALE_VOICES = { "Vlad", "Miles", "Knox" }
local FEMALE_VOICES = { "Roxie", "Annie", "Zelda" }
local maleNext = 0
local femaleNext = 0

local function pickOutfit()
	return OUTFITS[ZombRand(#OUTFITS) + 1]
end

local function nextVoice(female)
	if female then
		femaleNext = femaleNext + 1
		if femaleNext > #FEMALE_VOICES then
			femaleNext = 1
		end
		return FEMALE_VOICES[femaleNext]
	end
	maleNext = maleNext + 1
	if maleNext > #MALE_VOICES then
		maleNext = 1
	end
	return MALE_VOICES[maleNext]
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
	md.fromzoidVoice = nextVoice(female)
end

local function wornCount(zombie)
	if not zombie.getWornItems then
		return 0
	end
	local worn = zombie:getWornItems()
	if not worn or not worn.size then
		return 0
	end
	return worn:size()
end

local function wornItem(worn, i)
	if worn.getItemByIndex then
		return worn:getItemByIndex(i)
	end
	local slot = worn:get(i)
	if slot and slot.getItem then
		return slot:getItem()
	end
	return slot
end

local function wipeBlood(zombie)
	local hv = zombie.getHumanVisual and zombie:getHumanVisual() or nil
	if hv then
		if hv.removeBlood then
			hv:removeBlood()
		end
		if BloodBodyPartType and BloodBodyPartType.MAX then
			for i = 0, BloodBodyPartType.MAX:index() - 1 do
				local part = BloodBodyPartType.FromIndex(i)
				if hv.setBlood then
					hv:setBlood(part, 0)
				end
				if hv.setDirt then
					hv:setDirt(part, 0)
				end
			end
		end
	end
	local worn = zombie.getWornItems and zombie:getWornItems() or nil
	if worn then
		for i = 0, worn:size() - 1 do
			local item = wornItem(worn, i)
			if item and instanceof(item, "Clothing") and item.getBloodClothingType and BloodClothingType then
				local covered = BloodClothingType.getCoveredParts(item:getBloodClothingType())
				if covered then
					for j = 0, covered:size() - 1 do
						local part = covered:get(j)
						if item.setBlood then
							item:setBlood(part, 0)
						end
						if item.setDirt then
							item:setDirt(part, 0)
						end
					end
				end
			elseif item and item.setBloodLevel then
				item:setBloodLevel(0)
			end
		end
	end
	if zombie.resetModelNextFrame then
		zombie:resetModelNextFrame()
	end
end

local function dressLikePerson(zombie)
	if not zombie or not instanceof(zombie, "IsoZombie") then
		return
	end
	if zombie.dressInNamedOutfit then
		zombie:dressInNamedOutfit(pickOutfit())
	end
	if wornCount(zombie) < 2 and zombie.dressInRandomOutfit then
		zombie:dressInRandomOutfit()
	end
	wipeBlood(zombie)
	if zombie.setCrawler then
		zombie:setCrawler(false)
	end
	if zombie.setCanWalk then
		zombie:setCanWalk(true)
	end
	if zombie.setCanOpenDoors then
		pcall(function()
			zombie:setCanOpenDoors(true)
		end)
	end
	assignVoice(zombie)
end

Events.OnZombieCreate.Add(dressLikePerson)
