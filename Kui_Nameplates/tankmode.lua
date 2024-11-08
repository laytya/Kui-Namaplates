--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]] local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')

if not addon.superwow then
    return
end

local mod = addon:NewModule('TankMode', 'AceEvent-3.0', 'AceTimer-3.0')

mod.uiName = 'Threat'

function mod:OnEnable()
    self:Toggle()
end

local guidsTargets = {}

--------------------------------------------------------- tank mode functions --
function mod:TargetsUpdate()
    for _, frame in pairs(addon.frameList) do
        self:TrackTargets(nil, frame.kui)
    end
end

function mod:Toggle()
    addon.TankMode = self.db.profile.enabled == 1
    --[[	if self.db.profile.enabled == 1 then
		-- smart tank mode, listen for spec changes
		self:RegisterEvent('PLAYER_TALENT_UPDATE', 'Update')
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'Update')
	else
		self:UnregisterEvent('PLAYER_TALENT_UPDATE')
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	end
]]

end

function mod:GuidsTargets()
    printT(guidsTargets)
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
    if not f.guid or not guidsTargets[f.guid] then
        return
    end
    local g = guidsTargets[f.guid]
    local _, target = UnitExists(f.guid .. "target")
    if target ~= g.current then
        if g.current then
            g.prev = g.current
        end
        g.current = target
    end
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
        local _, player = UnitExists("player")
        if g.cc then
            return unpack(mod.db.profile.cccolour)
        elseif (g.cast and (g.cast == player or g.prev == player)) or g.current == player or
            (not g.cast and (not g.current and g.prev == player)) then
            return unpack(mod.db.profile.barcolour)
        else
            return unpack(mod.db.profile.loosecolour)
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

---------------------------------------------------- Post db change functions --
mod.configChangedFuncs = {
    runOnce = {}
}
mod.configChangedFuncs.runOnce.enabled = function()
    mod:Toggle()
end
-------------------------------------------------------------------- Register --
function mod:GetOptions()
    return {
        enabled = {
            name = 'Tank mode',
            desc = 'Change the colour of a plate\'s health bar and border when you have threat on its unit.',
            type = 'select',
            values = {'Enabled', 'Disabled'},
            order = 0
        },
        barcolour = {
            name = 'Bar colour',
            desc = 'The bar colour to use when you have threat',
            type = 'color',
            order = 1
        },
        midcolour = {
            name = 'Transitional colour',
            desc = 'The bar colour to use when you are losing or gaining threat.',
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
        }
    }
end

function mod:OnInitialize()
    self.db = addon.db:RegisterNamespace(self.moduleName, {
        profile = {
            enabled = 2,
            barcolour = {.2, .9, .1},
            midcolour = {1, .5, 0},
            glowcolour = {1, 0, 0, 1},
            cccolour = {1, 1, 0, 0.6},
            loosecolour = {1, 0, 0, 1}
        }
    })

    addon:InitModuleOptions(self)
    mod:SetEnabledState(true)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostCritUpdate', 'PostCritUpdate')
    --self:RegisterMessage('KuiNameplates_PostUpdate', 'PostUpdate')

    self:RegisterEvent("UNIT_CASTEVENT", OnCastEvent)
    self:ScheduleRepeatingTimer('TargetsUpdate', .1)
    self:ScheduleRepeatingTimer('CleanTargets', 10)
	self:ScheduleRepeatingTimer('CheckCC', 1)
    addon.TankModule = self
    addon.TankMode = true
end
