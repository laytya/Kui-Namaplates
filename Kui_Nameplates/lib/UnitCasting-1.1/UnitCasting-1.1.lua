local MAJOR, MINOR = 'UnitCasting-1.1', 6
local uc = LibStub:NewLibrary(MAJOR, MINOR)
if not uc then
	-- already registered
	return
end
local B = LibStub("LibBabble-Spell-3.0")
local BS = B:GetLookupTable()
--local BS = AceLibrary("Babble-Spell-2.3")
uc.callbacks = uc.callbacks or LibStub("CallbackHandler-1.0"):New(uc)
LibStub("AceTimer-3.0"):Embed(uc)
LibStub("AceHook-3.0"):Embed(uc)

local ttName = "UnitCastingTT"
local tt = CreateFrame("GameTooltip", ttName, nil, "GameTooltipTemplate")
tt:SetOwner(WorldFrame, "ANCHOR_NONE")
tt:SetScript("OnHide", function()
	this:SetOwner(WorldFrame, "ANCHOR_NONE")
end)
uc.tt = tt


local f = CreateFrame 'Frame'
----------------------------------------------- 
-- Callbacks:
-- EndDRBuff, Buff
-- CastOrBuff, buff or cast
-- NewCast, cast
-- NewBuff, buff
-- NewHeal, heal
-- Hit, info
-- Death, info
-- Fear. -
-------------------------------------------------



uc.parser = ParserLib:GetInstance('1.1')


uc.SpellcastsToTrack = {}
uc.ChanneledHealsSpellcastsToTrack = {}
uc.ChanneledSpellcastsToTrack = {}
uc.InstantSpellcastsToTrack = {}
uc.TimeModifierBuffsToTrack = {}
uc.InterruptsToTrack = {}
uc.BuffsToTrack = {}
uc.DebuffsToTrack = {}
uc.SpellSchoolColors = {}
uc.RGBBorderDebuffsColors = {}
uc.BuffsToTrack = {}
uc.DebuffRefreshingSpells = {}
uc.InstantSpellcastsToTrack = {}
uc.RootSnares = {}
uc.InterruptBuffsToTrack = {}
uc.UniqueDebuffs = {}

-- written by kuurtzen (& modernist)

local Cast = {}
local casts = {}
local Heal = {}
local heals = {}
local InstaBuff = {}
local iBuffs = {}
local buff          = {}
local buffList      = {}
local dreturns      = {}
local dreturnsList  = {}
local buffQueue     = {}
local buffQueueList = {}
Cast.__index = spellCast
Heal.__index = Heal
InstaBuff.__index = InstaBuff
buff.__index        = buff
buffQueue.__index   = buffQueue
dreturns.__index    = dreturns

local playerName = UnitName 'player'

Cast.create = function(caster, spell, info, timeMod, time, inv)
	local acnt = {}
	setmetatable(acnt, spellCast)
	acnt.caster    = caster
	acnt.spell     = spell
	acnt.icon      = B:GetSpellIcon(spell)
	acnt.timeStart = time
	acnt.timeEnd   = time + info['casttime'] * timeMod
	acnt.tick      = info.tick and info.tick or 0
	acnt.nextTick  = info.tick and time + acnt.tick or acnt.timeEnd
	acnt.inverse   = inv
	acnt.class     = info.class
	acnt.school    = info.school and uc.SpellSchoolColors[info.school]
	acnt.borderClr = info.immune and { .3, .3, .3 } or { .1, .1, .1 }
	return acnt
end

Heal.create = function(n, no, crit, time)
	local acnt = {}
	setmetatable(acnt, Heal)
	acnt.target    = n
	acnt.amount    = no
	acnt.crit      = crit
	acnt.timeStart = time
	acnt.timeEnd   = time + 2
	acnt.y         = 0
	return acnt
end

InstaBuff.create = function(c, b, list, time)
	local acnt = {}
	setmetatable(acnt, InstaBuff)
	acnt.caster    = c
	acnt.buff      = b
	acnt.timeMod   = list.mod
	acnt.spellList = list.list
	acnt.timeStart = time
	acnt.timeEnd   = time + 10 --planned obsolescence
	return acnt
end

buff.create = function(tar, spell, s, buffType, factor, time)
	local acnt = {}
	setmetatable(acnt, buff)
	acnt.target    = tar
	acnt.caster    = tar -- facilitate entry removal
	acnt.spell     = spell
	acnt.stacks    = s
	acnt.icon      = B:GetSpellIcon(spell)
	acnt.timeStart = time
	if not buffType.duration then print('buff with nil duration: ' .. spell) end
	buffType.duration = buffType.duration and buffType.duration or 0
	acnt.drTimeEnd       = time + buffType.duration * factor
	acnt.timeEnd         = time + buffType.duration
	acnt.prio            = buffType.prio and buffType.prio or 0
	acnt.border          = buffType.type and uc.RGBBorderDebuffsColors[buffType.type] or { .1, .1, .1 } -- border rgb values depending on type of buff/debuff
	acnt.display         = buffType.display == nil and true or buffType.display
	return acnt
end

buffQueue.create = function(tar, spell, buffType, d, time)
	local acnt = {}
	setmetatable(acnt, buffQueue)
	acnt.target   = tar
	acnt.buffName = spell

	buffType['duration'] = d
	acnt.buffData        = buffType
	--acnt.duration	=
	acnt.timeStart       = time
	acnt.timeEnd         = time + 3.5
	return acnt
end

dreturns.create = function(tar, t, tEnd)
	local acnt = {}
	setmetatable(acnt, dreturns)
	acnt.target  = tar
	acnt.type    = t
	acnt.factor  = 1
	acnt.k       = 15
	acnt.timeEnd = tEnd + acnt.k
	return acnt
end

local removeExpiredTableEntries = function(time, tab)
	local i = 1
	for k, v in pairs(tab) do
		if time > v.timeEnd then
			table.remove(tab, i)
			if tab == buffList or tab == heals then
				uc.callbacks:Fire("EndCastOrBuff", 1, v)
			end
		elseif tab == buffList and time  > v.drTimeEnd then
			uc.callbacks:Fire("EndDRBuff", 1, v)
		end
		i = i + 1
	end
end

local updateDRtimers = function(time, drtab, bufftab)
	for k, v in pairs(drtab) do
		for i, j in pairs(bufftab) do
			if j.target == v.target and uc.BuffsToTrack[j.spell] and uc.BuffsToTrack[j.spell]['dr'] then
				if uc.BuffsToTrack[j.spell]['dr'] == v.type then
					v.timeEnd = time + v.k
				end
			end
		end
	end
end

local tableMaintenance = function(reset)
	if reset then
		casts = {}
		heals = {}
		iBuffs = {}
		buffList = {}
		dreturnsList = {}
	else
		-- CASTS
		local time = GetTime()
		local i = 1
		for k, v in pairs(casts) do
			if time > v.timeEnd or time > v.nextTick then
				table.remove(casts, i)
				uc.callbacks:Fire("EndCastOrBuff", 1, v)
			end
			i = i + 1
		end
		-- HEALS
		removeExpiredTableEntries(time, heals)
		--  CASTING SPEED BUFFS
		removeExpiredTableEntries(time, iBuffs)
		-- BUFFS / DEBUFFS
		removeExpiredTableEntries(time, buffList)
		-- BUFFQUEUE
		removeExpiredTableEntries(time, buffQueueList)
		-- DRS
		updateDRtimers(time, dreturnsList, buffList)
		removeExpiredTableEntries(time, dreturnsList)
	end
end

f:SetScript('OnUpdate', function()
	tableMaintenance(false)
end)

local removeDoubleCast = function(caster)
	local k = 1
	for i, j in casts do
		if j.caster == caster then table.remove(casts, k) end
		k = k + 1
	end
end

local checkForChannels = function(caster, spell)
	local k = 1
	for i, j in casts do
		if j.caster == caster and j.spell == spell and uc.ChanneledSpellcastsToTrack[spell] ~= nil then
			j.nextTick = j.nextTick + j.tick
			return true
		end
		k = k + 1
	end
	return false
end

local checkforCastTimeModBuffs = function(caster, spell)
	local k = 1
	for i, j in iBuffs do
		if j.caster == caster then
			if j.spellList[1] ~= 'all' then
				local a, lastT = 1, 1
				for b, c in j.spellList do
					if c == spell then
						if lastT ~= 0 then -- priority to buffs that proc instant cast
							lastT = j.timeMod
						end
					end
				end
				return lastT
			else
				return j.timeMod
			end
			--return false
		end
		k = k + 1
	end
	return 1
end

local newCast = function(caster, spell, channel)
	local time = GetTime()
	local info = nil

	if channel then
		if uc.ChanneledHealsSpellcastsToTrack[spell] ~= nil then info = uc.ChanneledHealsSpellcastsToTrack[spell]
		elseif uc.ChanneledSpellcastsToTrack[spell] ~= nil then info = uc.ChanneledSpellcastsToTrack[spell] end
	else
		if uc.SpellcastsToTrack[spell] ~= nil then info = uc.SpellcastsToTrack[spell] end
	end
	if info ~= nil then
		if not checkForChannels(caster, spell) then
			removeDoubleCast(caster)
			local tMod = checkforCastTimeModBuffs(caster, spell)
			if tMod > 0 then
				local n = Cast.create(caster, spell, info, tMod, time, channel)
				table.insert(casts, n)
				uc.callbacks:Fire("NewCast", 1, n)
			end
		end
	end
end

local newHeal = function(n, no, crit)
	local time = GetTime()
	local h = Heal.create(n, no, crit, time)
	table.insert(heals, h)
	uc.callbacks:Fire("NewHeal", 1, h)
end

local newIBuff = function(caster, buff)
	local time = GetTime()
	local b = InstaBuff.create(caster, buff, uc.TimeModifierBuffsToTrack[buff], time)
	table.insert(iBuffs, b)
	uc.callbacks:Fire("NewBuff", 1, b)
end

local function manageDR(time, tar, b, castOn)
	if not uc.BuffsToTrack[b]['dr'] then return 1 end

	for k, v in pairs(dreturnsList) do
		if v.target == tar and v.type == uc.BuffsToTrack[b]['dr'] then
			v.factor = v.factor > .25 and v.factor / 2 or 0
			--if v.factor > 0 then
			--	v.timeEnd = time + SPELLINFO_BUFFS_TO_TRACK[b]['duration'] * v.factor + v.k
			--end
			return v.factor
		end
	end

	if castOn then return 0 end -- avoids creating a new DR entry if none was found
	local n = dreturns.create(tar, uc.BuffsToTrack[b]['dr'], uc.BuffsToTrack[b]['duration'] + time)
	table.insert(dreturnsList, n)
	return 1
end

local function checkQueueBuff(tar, b)
	for k, v in pairs(buffQueueList) do
		if v.target == tar and v.buffName == b then
			return true
		end
	end
	return false
end

local function newbuff(tar, b, s, castOn)
	local time = GetTime()
	-- check buff queue
	if checkQueueBuff(tar, b) then return end

	local drf = manageDR(time, tar, b, castOn)
	local endBuff = time + uc.BuffsToTrack[b].duration
	--if drf > 0 then
		-- remove buff if it exists
		for k, v in pairs(buffList) do
			if v.caster == tar and v.spell == b then
				if v.timeEnd >= endBuff then
					return
				end
				table.remove(buffList, k)
			end
		end

		local n = buff.create(tar, b, s, uc.BuffsToTrack[b], drf, time)
		table.insert(buffList, n)
		uc.callbacks:Fire("NewBuff", 1, n)
	--end
end

local function refreshBuff(tar, b, s)
	-- refresh if it exists
	for i, j in pairs(uc.DebuffRefreshingSpells[b]) do
		for k, v in pairs(buffList) do
			if v.caster == tar and v.spell == j then
				newbuff(tar, j, s, false)
				return
			end
		end
	end
end

local function queueBuff(tar, spell, b, d)
	local time = GetTime()
	local bq = buffQueue.create(tar, spell, b, d, time)
	table.insert(buffQueueList, bq)
end

local function processQueuedBuff(tar, b, start)
	local time = GetTime()
	for k, v in pairs(buffQueueList) do
		if v.target == tar and v.buffName == b then
			--printT({"processQueuedBuff",v})
			local drf = manageDR(time, v.target, v.buffName, false)
			local n = buff.create(v.target, v.buffName, 1, v.buffData, drf, time)
			table.insert(buffList, n)
			if start then
			uc.callbacks:Fire("NewBuff", 1, n)
			end
			table.remove(buffQueueList, k)
			return n
		end
	end
end

-----handleCast subfunctions-----------------------------------------------
---------------------------------------------------------------------------
local forceHideTableItem = function(tab, caster, spell)
	local time = GetTime()
	for k, v in pairs(tab) do
		if (v.caster == caster) and (time < v.timeEnd) then
			if (spell ~= nil) then 
				if v.spell == spell then 
					v.timeEnd = time -- 10000 end
				end 
			else
				v.timeEnd = time -- 10000 -- force hide
			end
		end
	end
end

local handleCast = function(info)
	if info.isPerform then
		if info.skill == BS["Vanish"] or info.skill == BS["Escape Artist"] then
			for k, v in pairs(uc.RootSnares) do
				forceHideTableItem(buffList, info.source, k)
			end
		end
		newCast(info.source, info.skill, true)
		return true
	elseif info.isBegin then
		newCast(info.source, info.skill, false)
		return true
	else
		if uc.SpellcastsToTrack[info.skill] then
			newCast(info.source, info.skill, false)
		else
			forceHideTableItem(casts, info.source, nil)
		end
	end
end

local gainBuff = function(info)

	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	-- buffs/debuffs to be displayed
	if uc.BuffsToTrack[info.skill] then
		newbuff(victim, info.skill, 1, false)
	end
	-- self-cast buffs that interrupt cast (blink, ice block ...)
	if uc.InterruptBuffsToTrack[info.skill] then
		forceHideTableItem(casts, victim, nil)
	end
	-- specific channeled spells (evocation ...)
	if uc.ChanneledSpellcastsToTrack[info.skill] then
		newCast(victim, info.skill, true)
	end
	-- buffs that alter spell casting speed
	if uc.TimeModifierBuffsToTrack[info.skill] then
		newIBuff(victim, info.skill)
	end
end

local gainDebuff = function(info)
	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	
	-- debuffs to be displayed
	if uc.BuffsToTrack[info.skill] then
		newbuff(victim, info.skill, info.amountRank, false)
	end
	-- spell interrupting debuffs (stuns, incapacitates ...)
	if uc.InterruptBuffsToTrack[info.skill] then
		forceHideTableItem(casts, victim, nil)
	end
	-- debuffs that slow spellcasting speed (tongues ...)
	if uc.TimeModifierBuffsToTrack[info.skill] then
		newIBuff(victim, info.skill)
	end
	-- debuffs that refresh buffs(weakened soul to pw:shield)
	if uc.DebuffRefreshingSpells[info.skill] then
		refreshBuff(victim, info.skill)
	end
	-- process debuffs in queueBuff
	processQueuedBuff(victim, info.skill, true)
end

local fadeRem = function(info)
	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	-- buffs/debuffs to be displayed
	if uc.BuffsToTrack[info.skill] then
		forceHideTableItem(buffList, victim, info.skill)
	end
	-- buff channeling casts fading
	if uc.ChanneledSpellcastsToTrack[info.skill] then
		forceHideTableItem(casts, victim, nil)
	end

	if uc.TimeModifierBuffsToTrack[info.skill] then
		forceHideTableItem(iBuffs, victim, info.skill)
	end
end

local hitCrits = function(info)
	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	local source = info.source == ParserLib_SELF and playerName or info.source
	-- instant spells that cancel casted ones
	if uc.InstantSpellcastsToTrack[info.skill] then
		forceHideTableItem(casts, source, nil)
	end
	
	if uc.ChanneledSpellcastsToTrack[info.skill] then
		newCast(source, info.skill, true)
	end

	-- interrupt dmg spell
	if uc.InterruptsToTrack[info.skill] then
		forceHideTableItem(casts, victim, nil)
	end

	-- spells that refresh debuffs
	if uc.DebuffRefreshingSpells[info.skill] and not info.isDOT then
		refreshBuff(victim, info.skill)
	end

	uc.callbacks:Fire("Hit",1,info)
end

local fear = function(msg, caster )
	local fear = '(.+) attempts to run away in fear!'
	local ffear = string.find(msg, fear)
	if ffear then
		forceHideTableItem(casts, caster)
		uc.callbacks:Fire("Fear")
	end
	return ffear
end

local handleHeal = function(info)
	if uc.InstantSpellcastsToTrack[info.skill] then
		forceHideTableItem(casts, info.source == ParserLib_SELF and playerName or info.source , nil)
		return
	end
	if info.isDOT and uc.ChanneledHealsSpellcastsToTrack[info.skill] then
		newCast(info.source == ParserLib_SELF and playerName or info.source, info.skill, true)
		return
	end
	newHeal(info.victim, info.amount, info.isCrit)
	if not info.isDOT and uc.DebuffRefreshingSpells[info.skill] then
		refreshBuff(info.victim == ParserLib_SELF and playerName or info.victim, info.skill)
	end
end

local directInterrupt = function(info)
	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	forceHideTableItem(casts, victim, nil)
end

local playerDeath = function(info)
	local victim = info.victim == ParserLib_SELF and playerName or info.victim
	forceHideTableItem(casts, victim, nil)
	forceHideTableItem(buffList, victim, nil)

	uc.callbacks:Fire("Death", 1, info)
end

uc.OnEvent = function(event, info)
	if info.type == "cast" then
		handleCast(info)
	elseif info.type == "heal" then
		handleHeal(info)
	elseif info.type == "hit" then
		hitCrits(info)
	elseif info.type == "buff" then
		gainBuff(info)
	elseif info.type == "fade" then
		fadeRem(info)
	elseif info.type == "debuff" then
		gainDebuff(info)
	elseif info.type == "interrupt" then
		directInterrupt(info)
	elseif info.type == "death" then
		playerDeath(info)
	elseif info.type == "miss" then
		--printT({"OnEvent", event, info})
	end
end

local function catchSpellcast(spell, rank, onself)

	local unit, duration
	local target = ""
	local info = uc.UniqueDebuffs[spell]
	if info then

		if info.cp then
			duration = info.cp[GetComboPoints()]
		elseif rank and info.r then
			if rank == "Max" then
				rank = table.getn(info.r)
			else
				rank = tonumber((string.gsub(rank, RANK, ""))) or 0 
			end
			duration = info.r[rank]
		else
			duration = info.duration
		end
		if UnitExists("target") then
			target = GetUnitName("target")
		end
		queueBuff(target, spell, info, duration)
	end
end

function uc:UseAction(slot, clicked, onself)
	if not GetActionText(slot) and HasAction(slot) then
		self.tt:ClearLines()
		getglobal(ttName .. "TextRight1"):SetText()
		self.tt:SetAction(slot)
		local spell = getglobal(ttName .. "TextLeft1"):GetText()
		local rank = getglobal(ttName .. "TextRight1"):GetText()
		uc.tt:Hide()
		catchSpellcast(spell, rank, onself)
	end
end

function uc:CastSpell(index, booktype)
	local spell, rank = GetSpellName(index, booktype)
	catchSpellcast(spell, rank)
end

function uc:CastSpellByName(text, onself)
	local _, _, spell, rank = string.find(text, '(.+)%((.+)%)')
    local spell = spell or text
    local rank = rank or "Max"
	local spell = string.gsub(text, "%(.-%)$", "")
	catchSpellcast(spell, rank, onself)
end

function uc:SpellTargetUnit(unit)
	for k, v in pairs(buffQueueList) do
		if v.target == "" then
			v.target = UnitName(unit)
		end
	end
end

function uc:TargetUnit(unit)
	for k, v in pairs(buffQueueList) do
		if v.target == "" then
			v.target = UnitName(unit)
		end
	end
end

function uc:OnMouseDown()
	for k, v in pairs(buffQueueList) do
		if v.target == "" and arg1 == "LeftButton" and UnitExists("mouseover") then
			v.target = UnitName("mouseover")
		end
	end
end

function uc:SPELLCAST_STOP()
	local b = buffQueueList[1]
	if b then
		local info = processQueuedBuff(b.target, b.buffName, false)
		self:ScheduleTimer("CompleteCast", 0.5, 1, info)
	end
end

function uc:CompleteCast(info)

	uc.callbacks:Fire("NewBuff", 1, info)
end


function uc:SpellStopCasting()
	local i = 1
	for k, v in pairs(buffQueueList) do
		table.remove(buffQueueList, i)
		i = i + 1
	end
end

function uc:SpellStopTargeting()
	local i = 1
	for k, v in pairs(buffQueueList) do
		table.remove(buffQueueList, i)
		i = i + 1
	end
end

uc.SPELL_FAILED = function(event, info)
	for k, v in pairs(buffQueueList) do
		if v.buffName == info.skill then
			table.remove(buffQueueList, k)
			break
		end
	end
end

-- GLOBAL ACCESS FUNCTIONS
uc.GetCast = function(caster)
	if caster == nil then return nil end
	for k, v in pairs(casts) do
		if v.caster == caster then
			return v
		end
	end
	return nil
end

uc.GetHeal = function(target)
	for k, v in pairs(heals) do
		if v.target == target then
			return v
		end
	end
	return nil
end

local function sortPriobuff(tab, b)
	for k, v in pairs(tab) do
		if b.prio > v.prio then
			table.insert(tab, k, b)
			return tab
		end
	end
	table.insert(tab, b)
	return tab
end

uc.GetPrioBuff = function(name, n)
	local b = {}
	for j, e in pairs(buffList) do
		if e.target == name and e.display then
			b = sortPriobuff(b, e)
		end
	end

	local l = {}
	for k, v in pairs(b) do
		table.insert(l, v)
		if k == n then return l end
	end
	return l
end

uc.GetBuffs = function(name)
	local list = {}
	for j, e in ipairs(buffList) do
		if e.target == name then
			table.insert(list, e)
		end
	end
	return list
end

uc.RefreshBuff = function(t, b, s)
	if uc.DebuffRefreshingSpells[b] then
		refreshBuff(t, b, s)
	end
end



uc.AddBuff = function(t, s, d)
	if SPELLINFO_UNIQUE_DEBUFFS[s] then
		local time = getTimeMinusPing()
		local spell = SPELLINFO_UNIQUE_DEBUFFS[s]
		spell['duration'] = d
		local n = buff.create(t, s, 1, spell, 1, time)
		table.insert(buffList, n)
		--print(t .. '/' .. s .. '/' .. spell['duration'])
	end
end

uc.RegisterTable = function(name, t)
	uc[name] = t
end



uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_SELF_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_SELF_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PARTY_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PARTY_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PET_DAMAGE", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_PET_BUFF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_BREAK_AURA", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_AURA_GONE_SELF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_AURA_GONE_PARTY", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_AURA_GONE_OTHER", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_COMBAT_FRIENDLY_DEATH", uc.OnEvent)
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_COMBAT_HOSTILE_DEATH", uc.OnEvent)

-- Spellcast handling

uc:Hook("UseAction")
uc:Hook("CastSpell")
uc:Hook("CastSpellByName")
uc:Hook("SpellTargetUnit")
uc:Hook("TargetUnit")
uc:Hook("SpellStopTargeting")
uc:Hook("SpellStopCasting")
uc:HookScript(WorldFrame, "OnMouseDown")

f:RegisterEvent("SPELLCAST_STOP")
uc.parser:RegisterEvent("UnitCasting", "CHAT_MSG_SPELL_FAILED_LOCALPLAYER", uc.SPELL_FAILED)

f:RegisterEvent 'PLAYER_ENTERING_WORLD'
f:RegisterEvent 'CHAT_MSG_MONSTER_EMOTE'
f:SetScript('OnEvent', function()
	if event == 'PLAYER_ENTERING_WORLD' then
		tableMaintenance(true)
	elseif event == 'CHAT_MSG_MONSTER_EMOTE' then
		fear(arg1, arg2)
	elseif event == 'SPELLCAST_STOP' then
		uc:SPELLCAST_STOP()
	end
end)


--
