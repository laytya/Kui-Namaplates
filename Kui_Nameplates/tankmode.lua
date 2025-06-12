--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]] 

local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')

local AceCore = LibStub("AceCore-3.0")
local new, del = AceCore.new, AceCore.del
local wipe, truncate = AceCore.wipe, AceCore.truncate
local strsplit = AceCore.strsplit
local strlower, unpack = string.lower, unpack

if not addon.superwow then
    return
end

local mod = addon:NewModule('TankMode', 'AceEvent-3.0', 'AceTimer-3.0')

mod.uiName = 'Threat'

function mod:OnEnable()
    self:Toggle()
end

local guidsTargets = new()
local offTanks 

mod.threatApi = 'TWTv4='
mod.tankModeApi = 'TMTv1='
mod.UDTS = 'TWT_UDTSv4'
mod.tankModeThreats = new()
mod.tankName = ''
mod.myThreat = 0
mod.tankThreat = 0
mod.myMelee = false
mod.myName = ''

local strlen = string.len
local find = string.find
local substr = string.sub
local parseint = tonumber
local tinsert = table.insert
local playerGuid

local function explode(str, delimiter)
    local result = new()
    local from = 1
    local delim_from, delim_to = find(str, delimiter, from, 1, true)
    while delim_from do
        tinsert(result, substr(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = find(str, delimiter, from, true)
    end
    tinsert(result, substr(str, from))
    return result
end
--------------------------------------------------------- tank mode functions --
function mod:TargetsUpdate()
    for _, frame in pairs(addon.frameList) do
        self:TrackTargets(nil, frame.kui)
    end
end

function mod:Toggle()
    addon.TankMode = self.db.profile.enabled ~= 2
    --[[	if self.db.profile.enabled == 1 then
		-- smart tank mode, listen for spec changes
		self:RegisterEvent('PLAYER_TALENT_UPDATE', 'Update')
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'Update')
	else
		self:UnregisterEvent('PLAYER_TALENT_UPDATE')
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	end
]]
    mod:SetEnabledState(addon.TankMode)
end

local function getTankColor(tank, offtank)
    if tank then
        if mod.db.profile.enabled == 3 then
            return unpack(mod.db.profile.loosecolour)
        else
            if offtank then
                return unpack(mod.db.profile.offtcolour)
            else
            return unpack(mod.db.profile.barcolour)
        end    
        end    
    else
        if mod.db.profile.enabled == 3 then
            return unpack(mod.db.profile.barcolour)
        else
            if offtank then
                return unpack(mod.db.profile.offtcolour)
            else
            return unpack(mod.db.profile.loosecolour) 
        end  
    end
    end
    
end
local function checkOffTanks(target)
    if target and offTanks then
        local targetName = strlower(UnitName(target))
        for _, offtank in pairs(offTanks) do
            if targetName == strlower( offtank) then
                 return true
            end
        end
    end
end

function mod:GuidsTargets()
    --printT(guidsTargets)
end

function mod:TrackTargets(msg, f)
    local guid = f.oldHealth.kuiParent:GetName(1)
    if not guid then
        return
    end
    if not guidsTargets[guid] then
        guidsTargets[guid] = {
            prev = nil,
            current = nil,
            cast = nil,
            spellId = nil,
            cc = false
        }
    end
end

function mod:CleanTargets(msg, f)
    for guid, _ in pairs(guidsTargets) do
        if not UnitExists(guid) then
            guidsTargets[guid] = nil
        end
    end
end

function mod:PostCritUpdate(msg, f)
    local t 
    if f.guid and guidsTargets[f.guid] then
        t = guidsTargets[f.guid]
        local _, target = UnitExists(f.guid .. "target")
        if target ~= t.current then
            if t.current then
                t.prev = t.current
            end
            t.current = target
        end
    end
    if f.agroText and UnitAffectingCombat("player") and UnitAffectingCombat(f.guid) then
        if f.target and mod.myThreat > 0 and ((offTanks and t.current == playerGuid) or not offTanks) then
        local r,g,b  = getTankColor(mod.tankName == mod.myName )
        f:SetAgroText(mod.myThreat, {r,g,b})
        elseif offTanks and t and t.current  then
            local r,g,b  = getTankColor(checkOffTanks( t.current) or t.current == playerGuid)
            f:SetAgroText(UnitName( t.current), {r,g,b})
        else
            f:SetAgroText()
    end
    end
       
    
end

function mod:PostTarget(msg, f)
    local _, frame
    for _, frame in pairs(addon.frameList) do
        self:Hide(nil, frame.kui)
    end
    mod.tankName = ''
    mod.myThreat = 0
    mod.tankThreat = 0
    mod.myMelee = false
end

local ccSpells = {"Polymorph", "Shackle Undead", "Freezing Trap", "Hibernate", "Gouge", "Sap", "Magic Dust"}

function mod:CheckCC()
    for _, f in pairs(addon.frameList) do
        if f.guid and guidsTargets[f.guid] then
            guidsTargets[f.guid].cc = false
            for i = 1, 40 do
                local _, _, _, spellId = UnitDebuff(f.guid, i)
                if spellId then
                    local spell = SpellInfo(spellId)
                    if spell then
                        for _, v in ipairs(ccSpells) do
                            if string.find(spell, "^" .. v) then
                                guidsTargets[f.guid].cc = true
                            end
                        end
                    end
                end
            end
        end
    end
end

    

function mod:UpdateHealthbarColor(f)
    if not f.guid or not guidsTargets[f.guid] then
        return
    end
    if UnitAffectingCombat("player") and UnitAffectingCombat(f.guid) and not UnitCanAssist("player", f.guid) then
        local g = guidsTargets[f.guid]
        
				local r, gg, b
        if g.cc then
					r, gg, b = unpack(mod.db.profile.cccolour)
          return r, gg, b, true
        elseif (g.cast and (g.cast == playerGuid or g.prev == playerGuid)) or g.current == playerGuid or
            (not g.cast and (not g.current and g.prev == playerGuid)) then
						r, gg, b = getTankColor(true)
            return r, gg, b, true
        else
            r, gg, b = getTankColor(false, checkOffTanks(g.current))
          return r, gg, b, false
        end
    end
    return nil
end

local function OnCastEvent()
    local caster, target, eventType, spellId, start, duration = arg1, arg2, arg3, arg4, GetTime(), arg5 / 1000
    if eventType == "MAINHAND" or eventType == "OFFHAND" then
        return
    end
    local _
    _, caster = UnitExists(caster)
    _, target = UnitExists(target)
    if caster and guidsTargets[caster] then
        if eventType == "START" or eventType == "CHANNEL" then
            guidsTargets[caster].cast = target or true
        elseif eventType == "CAST" or eventType == "FAIL" and guidsTargets[caster].spellId == spellId then
            guidsTargets[caster].spellId = nil
            guidsTargets[caster].cast = nil
        end
    end
end

local function handleThreatPacket(packet)
    local playersString = substr(packet, find(packet, mod.threatApi) + strlen(mod.threatApi), strlen(packet))
    mod.tankName = ''
    local players = explode(playersString, ';')
    for _, tData in players do
        local msgEx = explode(tData, ':')
        -- udts handling
        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] then
            local player = msgEx[1]
            local tank = msgEx[2] == '1'
            local threat = parseint(msgEx[3])
            local perc = parseint(msgEx[4])
            local melee = msgEx[5] == '1'
            if tank then
                mod.tankName = player
                mod.tankThreat = perc
            end
            if player == mod.myName then
                mod.myThreat = perc
                mod.myMelee = melee
             end
          end
     end

end

local function handleTankModePacket(packet)
    local playersString = substr(packet, find(packet, mod.tankModeApi) + strlen(mod.tankModeApi), strlen(packet))
    mod.tankModeThreats = wipe( mod.tankModeThreats )
    local players = explode(playersString, ';')
    for _, tData in players do
        local msgEx = explode(tData, ':')
        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then
            local creature = msgEx[1]
            local guid = msgEx[2]
            local name = msgEx[3]
            local perc = parseint(msgEx[4])
            mod.tankModeThreats[guid] = {
                creature = creature,
                name = name,
                perc = perc
            }
        end
    end
end

local function OnChatMsgAddon()
    
    if find(arg2, mod.threatApi, 1, true) then
        local threatData = arg2
        if find(threatData, '#') and find(threatData, mod.tankModeApi) then
            local packetEx = explode(threatData, '#')
            if packetEx[1] and packetEx[2] then
                threatData = packetEx[1]
                handleTankModePacket(packetEx[2])
            end
        end

        return handleThreatPacket(threatData)
    end
end

function mod:UnitDetailedThreatSituation()
    if (GetNumRaidMembers() ~= 0 or GetNumPartyMembers() ~= 0) and UnitExists('target') and UnitCanAttack("player", 'target') and 
        UnitAffectingCombat('player') and UnitAffectingCombat('target') then
        SendAddonMessage(mod.UDTS .. '_TM' , "limit=5", "PARTY") 
    end 
end

local function SetAgroText(self, agro, agrocolor)
    if agro == nil or agro == '' then
        -- hide the warning instantly
        self.agroText:SetText()
        self.agroText:Hide()
    else
        agro = type(agro) == 'number' and math.floor(agro) or agro
        agrocolor = agrocolor and agrocolor or {1, 0, 0}
        self.agroText:SetText(agro)
        self.agroText:SetTextColor(unpack(agrocolor))
        self.agroText:Show()
    end
end

function mod:CreateAgroText(msg, frame)
   
    frame.agroText = frame:CreateFontString(frame.overlay, {
        size = 'spellname',
        outline = 'OUTLINE'
    })
    frame.agroText:Hide()
    frame.agroText:SetPoint('BOTTOMRIGHT', frame.health, 'TOPRIGHT', 0, 1)

      -- handlers
    frame.SetAgroText = SetAgroText
end

function mod:Hide(msg, frame)
    if frame.agroText then
        frame.agroText:SetText()
        frame.agroText:Hide()
    end
end
---------------------------------------------------- Post db change functions --
mod.configChangedFuncs = {
    runOnce = {}
}
mod.configChangedFuncs.runOnce.enabled = function()
    mod:Toggle()
end

mod.configChangedFuncs.runOnce.offtanks = function( val)
    --mod.db.profile.offtanks = val
    if val and val ~= "" then
         offTanks = { strsplit(',', val) }
    else
        offTanks = del(offTanks)
    end
end
-------------------------------------------------------------------- Register --
function mod:GetOptions()
    return {
        enabled = {
            name = 'Tank mode',
            desc = 'Change the colour of a plate\'s health bar and border when you have threat on its unit.',
            type = 'select',
            values = {'Enabled', 'Disabled', 'Healer'},
            order = 0
        },
        barcolour = {
            name = 'Bar colour',
            desc = 'The bar colour to use when you have threat',
            type = 'color',
            order = 1
        },
        glowcolour = {
            name = 'Glow colour',
            desc = 'The glow (border) colour to use when you have threat',
            type = 'color',
            hasAlpha = true,
            order = 2
        },
        cccolour = {
            name = 'CC colour',
            desc = 'The bar colour to use on CC targets.',
            type = 'color',
            order = 1
        },
        loosecolour = {
            name = 'Loose colour',
            desc = 'The colour to use when you dont have threat',
            type = 'color',
            hasAlpha = true,
            order = 2
        },
        offtcolour = {
            name = 'Offtank targets colour',
            desc = 'The colour to use when offtank have threat',
            type = 'color',
            hasAlpha = true,
            order = 2
        },
        offtanks = {
            name = 'List of Offtanks',
            desc = 'Write here list of Offtanks, separated by ","',
            type = 'input',
            order = 6,
            width = "double"
        }
    }
end

function mod:OnInitialize()
    self.db = addon.db:RegisterNamespace(self.moduleName, {
        profile = {
            enabled = 2,
            barcolour = {.2, .9, .1},
            glowcolour = {1, 0, 0, 1},
            cccolour = {1, 1, 0, 0.6},
            loosecolour = {1, 0, 0, 1},
            offtcolour = {1, 0.7, 0, 1}
        }
    })
    mod.myName = UnitName('player')
    addon:InitModuleOptions(self)
    mod:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostCreate', 'CreateAgroText')
    self:RegisterMessage('KuiNameplates_PostHide', 'Hide')
    self:RegisterMessage('KuiNameplates_PostCritUpdate', 'PostCritUpdate')
    self:RegisterMessage('KuiNameplates_PostTarget', 'PostTarget')
    --self:RegisterMessage('KuiNameplates_PostUpdate', 'PostUpdate')

    self:RegisterEvent("UNIT_CASTEVENT", OnCastEvent)
    self:RegisterEvent("CHAT_MSG_ADDON", OnChatMsgAddon)
    self:ScheduleRepeatingTimer('TargetsUpdate', .1)
    self:ScheduleRepeatingTimer('CleanTargets', 10)
		self:ScheduleRepeatingTimer('CheckCC', .5)
    self:ScheduleRepeatingTimer('UnitDetailedThreatSituation', 1)
    addon.TankModule = self
    local _ 
    _, playerGuid= UnitExists("player")
    mod:Toggle()
    local _, frame
    for _, frame in pairs(addon.frameList) do
        if not frame.agroText then
            self:CreateAgroText(nil, frame.kui)
        end
    end
    if mod.db.profile.offtanks and mod.db.profile.offtanks ~= '' then
        offTanks = { strsplit(',', mod.db.profile.offtanks) }
    end
end

function mod:OnDisable()
	self:UnregisterEvent("UNIT_CASTEVENT")
    self:UnregisterEvent("CHAT_MSG_ADDON")
	self:CancelAllTimers()
	self:UnregisterMessage('KuiNameplates_PostCritUpdate')
    self:UnregisterMessage('KuiNameplates_PostCreate')
    self:UnregisterMessage('KuiNameplates_PostTarget')
    self:UnregisterMessage('KuiNameplates_PostHide')
    local _, frame
    for _, frame in pairs(addon.frameList) do
        self:Hide(nil, frame.kui)
    end
end
