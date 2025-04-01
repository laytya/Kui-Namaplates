--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]]

local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('CastWarnings', 'AceEvent-3.0')
mod.uc = LibStub:GetLibrary("UnitCasting-1.1")
local kui = LibStub('Kui-1.0')
mod.uiName = 'Cast warnings'

local superwow = SUPERWOW_VERSION and (tonumber(SUPERWOW_VERSION) > 1.4) or false

local function FadeFrame(self, from, to, duration, end_delay, callback)
    kui.frameFadeRemoveFrame(self)

    self:Show()
    self:SetAlpha(from)

    kui.frameFade(self, {
        mode = 'OUT',
        startAlpha = from,
        endAlpha = to,
        timeToFade = duration,
        fadeHoldTime = end_delay,
        finishedFunc = function(self)
            if to == 0 then
                self:Hide()
            else
                self:SetAlpha(to)
            end

            if callback then
                callback(self)
            end
        end
    })
end
------------------------------------------------------------- Frame functions --
local function SetCastWarning(self, spellName, spellSchool)
    self.castWarning:Stop()

    if spellName == nil then
        -- hide the warning instantly
        self.castWarning:SetText()
        self.castWarning:Hide()
    else
        spellSchool = spellSchool or {1, 1, 1}

        self.castWarning:SetText(spellName)
        self.castWarning:SetTextColor(unpack(spellSchool))
        self.castWarning:Fade()
    end
end

local function SetIncomingWarning(self, amount)
    if amount == 0 then
        return
    end
    self.incWarning:Stop()

    if amount > 0 then
        -- healing
        amount = '+' .. amount
        self.incWarning:SetTextColor(0, 1, 0)
    else
        -- damage (nyi)
        self.incWarning:SetTextColor(1, 0, 0)
    end
    self.incWarning:SetText(amount)
    self.incWarning:Fade()
end

-------------------------------------------------------------- Event handlers --
function mod:UNIT_CASTEVENT()
    local caster, target, eventType, spellId, start, duration = arg1, arg2, arg3, arg4, GetTime(), arg5 / 1000
    if eventType == "MAINHAND" or eventType == "OFFHAND" then
        return
    end
    local frame = addon:GetNameplate(caster)
    local name, guid = UnitExists(caster)

    if not guid then
        return
    end

    if warningEvents[event] then
        if event == 'SPELL_HEAL' or event == 'SPELL_PERIODIC_HEAL' then
            -- fetch the spell's target's nameplate
            name, guid = UnitExists(target)
        end

        if self.db.profile.useNames and name then
            name = name
        else
            name = nil
        end

        local f = addon:GetNameplate(guid)
        if f then
            if not f.castWarning or f.trivial then
                return
            end
            local spName, spSch = SpellInfo(spellId)

            if eventType == "START" or eventType == "CHANNEL" then
                f.castWarning.spellId = spellId
                f:SetCastWarning(spName, spSch)
                -- f:SetIncomingWarning(amount)
            elseif (eventType == "CAST" or eventType == "FAIL") and f.castWarning.spellId and f.castWarning.spellId ==
                spellId then
                -- hide the warning
                f:SetCastWarning(nil)
            end
        end
    end
end
local function getFrame(guid)
    if LoggingCombat and LoggingCombat("RAW") == 1 then
        guid = guid
    else
        guid = addon:GetKnownGUID(guid) -- Player
    end
    local f
    if guid then
        f = addon:GetNameplate(guid)
    else
        f = addon:GetTargetNameplate()
        if f and f.name.text ~= info.caster then
            return nil
        end
    end
    return f
end

local function OnHeal(event, info)
    local f = getFrame(info.target)
    if f and f.castWarning and not f.IN_NAMEONLY then
        f:SetIncomingWarning(info.amount)
    end
end

local function OnStartCast(event, info)
    local f = getFrame(info.caster)

    if f and f.castWarning and not f.IN_NAMEONLY then
        f:SetCastWarning(info.spell, info.school)
    end
end

local function OnEndCast(event, info)
    local name, exist, good = info.caster
    if superwow then
        good, exist, name = pcall(UnitName, info.caster)
        if not good or not exist then 
            name = info.caster
        end
    end

    local frames = addon:GetNameplates(name)
    for _, frame in pairs(frames) do
        if frame and frame.castWarning and (frame.castWarning:IsShown() and frame.castWarning:GetText() == info.skill) then
            frame:SetCastWarning(nil)
        end
    end
end

---------------------------------------------------------------------- Create --
function mod:CreateCastWarnings(msg, frame)
    -- casting spell name
    frame.castWarning = frame:CreateFontString(frame.overlay, {
        size = 'spellname',
        outline = 'OUTLINE'
    })
    frame.castWarning:Hide()
    frame.castWarning:SetPoint('BOTTOM', frame.name, 'TOP', 0, 1)

    frame.castWarning.Fade = function(self)
        FadeFrame(self, 1, 0, 3)
    end
    frame.castWarning.Stop = function(self)
        kui.frameFadeRemoveFrame(self)
    end

    -- incoming healing
    frame.incWarning = frame:CreateFontString(frame.overlay, {
        size = 'small',
        outline = 'OUTLINE'
    })
    frame.incWarning:Hide()
    frame.incWarning:SetPoint('TOP', frame.name, 'BOTTOM', 0, -3)

    frame.incWarning.Fade = function(self, full)
        if full then
            FadeFrame(self, .5, 0, .5)
        else
            FadeFrame(self, 1, .5, .5, .5, function(self)
                self:Fade(true)
            end)
        end
    end
    frame.incWarning.Stop = function(self)
        kui.frameFadeRemoveFrame(self)
    end

    -- handlers
    frame.SetCastWarning = SetCastWarning
    frame.SetIncomingWarning = SetIncomingWarning
end

function mod:Hide(msg, frame)
    if frame.castWarning then
        frame.castWarning:Stop()
        frame.castWarning:SetText()
        frame.castWarning:Hide()

        frame.incWarning:Stop()
        frame.incWarning:SetText()
        frame.incWarning:Hide()
    end
end

---------------------------------------------------- Post db change functions --
mod.configChangedFuncs = {
    runOnce = {}
}
mod.configChangedFuncs.runOnce.warnings = function(val)
    if val then
        mod:Enable()
    else
        mod:Disable()
    end
end

-------------------------------------------------------------------- Register --
function mod:GetOptions()
    return {
        warnings = {
            name = 'Show cast warnings',
            desc = 'Display cast and healing warnings on plates',
            type = 'toggle',
            order = 1,
            disabled = false
        },
        useNames = {
            name = "Use names for warnings",
            desc = 'Use character names to decide which frame to display warnings on. May increase memory usage and may cause warnings to be displayed on incorrect frames when there are many units with the same name. Reccommended on for PvP, off for PvE.',
            type = 'toggle',
            order = 2
        }
    }
end

function mod:OnInitialize()
    self.db = addon.db:RegisterNamespace(self.moduleName, {
        profile = {
            warnings = false,
            useNames = false
        }
    })

    addon:InitModuleOptions(self)
    mod:SetEnabledState(self.db.profile.warnings)
end

function mod:OnEnable()
    self:RegisterMessage('KuiNameplates_PostCreate', 'CreateCastWarnings')
    self:RegisterMessage('KuiNameplates_PostHide', 'Hide')

    -- self:RegisterEvent('UNIT_CASTEVENT')
    mod.uc.RegisterCallback(self, "NewCast", OnStartCast)
    mod.uc.RegisterCallback(self, "NewHeal", OnHeal)
    mod.uc.RegisterCallback(self, "EndCastOrBuff", OnEndCast)

    local _, frame
    for _, frame in pairs(addon.frameList) do
        if not frame.castWarning then
            self:CreateCastWarnings(nil, frame.kui)
        end
    end
end

function mod:OnDisable()
    -- self:UnregisterEvent('UNIT_CASTEVENT')
		self:UnregisterMessage('KuiNameplates_PostCreate')
    self:UnregisterMessage('KuiNameplates_PostHide')
    self.uc.UnregisterAllCallbacks(self)
    local _, frame
    for _, frame in pairs(addon.frameList) do
        self:Hide(nil, frame.kui)
    end
end
