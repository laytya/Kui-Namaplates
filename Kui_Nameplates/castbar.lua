--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]]
do
--return
end

local kui = LibStub('Kui-1.0')
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('CastBar', 'AceEvent-3.0')
mod.uc = LibStub:GetLibrary("UnitCasting-1.1")

mod.uiName = 'Cast bars'

local format , floor, fmod = format , math.floor, math.mod
local function ResetFade(f)
	kui.frameFadeRemoveFrame(f.castbar)
--	f.castbar.shield:Hide()
	f.castbar:Hide()
	f.castbar:SetAlpha(1)
end

------------------------------------------------------------- Script handlers --
local function OnCastbarShow(f, spell,icon)
	if not mod.enabledState then return end

--	local f = self:GetParent():GetParent().kui
	ResetFade(f)

	if f.castbar.name then
		f.castbar.name:SetText(spell)
	end
--[[
	-- is cast uninterruptible?
	if f.shield:IsShown() then
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.shieldbarcolour))
		f.castbar.shield:Show()
else ]]
		f.castbar.bar:SetStatusBarColor(unpack(mod.db.profile.display.barcolour))
	--	f.castbar.shield:Hide()
	--end
--	
	if f.trivial then
		-- hide text & icon
		if f.castbar.icon then
			f.castbar.icon:Hide()
			f.castbar.icon.bg:Hide()
		end

		if f.castbar.name then
			f.castbar.name:Hide()
		end

		if f.castbar.curr then
			f.castbar.curr:Hide()
		end
	else
		if f.castbar.icon then
	--		Sea.io.print(icon)
			f.castbar.icon:SetTexture(icon)
			f.castbar.icon.bg:Hide()
			f.castbar.icon:Show()
		end

		if f.castbar.name then
			f.castbar.name:Show()
		end

		if f.castbar.curr then
			f.castbar.curr:Show()
		end
	end

	-- castbar is shown on first update
end

local function OnCastbarHide(f)
	--local f = self:GetParent():GetParent().kui
	if f.castbar and f.castbar:IsShown() then
		ResetFade(f)
		
--[[		kui.frameFade(f.castbar, {
			mode		= 'OUT',
			timeToFade	= .5,
			startAlpha	= 1,
			endAlpha	= 0,
			finishedFunc = function()
				ResetFade(f)
			end,
		})
	]]
--		Sea.io.print("hide")
	end
	
end

local function decimal_round(n, dp)      -- ROUND TO 1 DECIMAL PLACE
    local shift = 10^(dp or 0)
    return floor(n*shift + .5)/shift
end
local getTimerLeft = function(tEnd)
	local t = tEnd - GetTime()
    if t > 5 then return decimal_round(t, 0) else return decimal_round(t, 1) end
end


function mod:OnCastbarUpdate(f, elapsed)
	local v,vv
	if not mod.enabledState then return end
	if addon.superwow then
		v = f.castbar.spellInfo
	else
		v = mod.uc.GetCast(f.name.text)
		vv = mod.uc.GetHeal(f.name.text)
	        if v == nil and vv ~= nil then
		    v = vv
	    end
	end
	if v ~= nil and GetTime() < v.timeEnd then

		f.castbar.bar:SetMinMaxValues(0, v.timeEnd - v.timeStart)
		if v.inverse then
			f.castbar.bar:SetValue(fmod((v.timeEnd - GetTime()), v.timeEnd - v.timeStart))
		else
			f.castbar.bar:SetValue(fmod((GetTime() - v.timeStart), v.timeEnd - v.timeStart))
		end
		if f.castbar.curr then
			f.castbar.curr:SetText(format("%.1f",getTimerLeft(v.timeEnd)))
		end
		
		local perc = (v.timeEnd - GetTime()) / (v.timeEnd - v.timeStart)
		local width = f.castbar.bar:GetWidth()
		local sp = width * perc
	--	Sea.io.print(perc," ", width," ", sp)
		sp = v.inverse and sp or -sp
		f.castbar.spark:SetPoint("CENTER", f.castbar.bar:GetRegions(), v.inverse and "LEFT" or "RIGHT", sp, 0)
		f.castbar:SetAlpha(f.currentAlpha)
		if not f.castbar:IsShown() then
			OnCastbarShow(f, v.spell, v.icon)
			f.castbar:Show()
		end
	else 
		OnCastbarHide(f)
	end
end

local function OnStartCast(event, info)
	
	local frame
	local guid
	if LoggingCombat and LoggingCombat("RAW") == 1 then
		guid = info.caster
	else
		guid = addon:GetKnownGUID(info.caster) -- Player
	end
	if guid then
		frame = addon:GetNameplate(guid)
	else
		frame = addon:GetTargetNameplate()
		if frame and frame.name.text ~= info.caster then
			return
		end
	end

	if frame and frame.castbar and ( not frame.castbar:IsShown() or frame.castbar.name:GetText() ~= info.skill) then 

		mod:OnCastbarUpdate(frame)
	end
end

local function OnEndCast(event, info)
	local frames = addon:GetNameplates(info.caster)
	for _, frame in pairs(frames) do
		if frame and frame.castbar and ( frame.castbar:IsShown() and frame.castbar.name:GetText() == info.skill) then
			OnCastbarHide(frame)
		end
	end
end

local function OnCastEvent()
	local caster, target, eventType, spellId, start, duration = arg1, arg2, arg3, arg4, GetTime(), arg5 / 1000
	if eventType == "MAINHAND" or eventType == "OFFHAND" then return end
	local frame = addon:GetNameplate(caster)
	if frame and frame.castbar then
		if eventType == "START" or eventType == "CHANNEL" then
			frame.castbar.spellInfo = nil
			local spell, rank, icon = SpellInfo(spellId)
			frame.castbar.spellInfo = {
				target = target, 
				spellId = spellId,
				spell = spell, 
				rank = rank, 
				icon = icon, 
				inverse = eventType == "CHANNEL",
				timeStart = start, 
				timeEnd = start + duration
			}
			
			mod:OnCastbarUpdate(frame)
		elseif eventType == "CAST" or eventType == "FAIL" 
						and frame.castbar.spellInfo and frame.castbar.spellInfo.spellId == spellId then
			frame.castbar.spellInfo = nil
			OnCastbarHide(frame)
		end
	end
end

---------------------------------------------------------------------- create --
function mod:CreateCastbar(msg, frame)
	if frame.castbar then return end
	-- container ---------------------------------------------------------------
	frame.castbar = CreateFrame('Frame', nil, frame)
	frame.castbar:Hide()
	
	-- background --------------------------------------------------------------
	frame.castbar.bg = frame.castbar:CreateTexture(nil, 'BACKGROUND')
	frame.castbar.bg:SetTexture(kui.m.t.solid)
	frame.castbar.bg:SetVertexColor(0, 0, 0, .85)

	frame.castbar.bg:SetHeight(addon.sizes.frame.cbheight)
	
	frame.castbar.bg:SetPoint('TOPLEFT', frame.bg.fill, 'BOTTOMLEFT', 0, -1)
	frame.castbar.bg:SetPoint('TOPRIGHT', frame.bg.fill, 'BOTTOMRIGHT', 0, 0)
	
	-- cast bar ------------------------------------------------------------
	frame.castbar.bar = CreateFrame("StatusBar", nil, frame.castbar)
	frame.castbar.bar:SetStatusBarTexture(addon.bartexture)

	frame.castbar.bar:SetPoint('TOPLEFT', frame.castbar.bg, 'TOPLEFT', 1, -1)
	frame.castbar.bar:SetPoint('BOTTOMLEFT', frame.castbar.bg, 'BOTTOMLEFT', 1, 1)
	frame.castbar.bar:SetPoint('RIGHT', frame.castbar.bg, 'RIGHT', -1, 0)

	frame.castbar.bar:SetFrameLevel(frame.castbar:GetFrameLevel() + 1)
	frame.castbar.bar:SetMinMaxValues(0, 1)

	-- spark
	frame.castbar.spark = frame.castbar.bar:CreateTexture(nil, 'ARTWORK')
	frame.castbar.spark:SetDrawLayer('ARTWORK', 6)
	frame.castbar.spark:SetVertexColor(1,1,.8)
	frame.castbar.spark:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\spark')
	frame.castbar.spark:SetPoint('CENTER', frame.castbar.bar:GetRegions(), 'RIGHT', 1, 0)
	frame.castbar.spark:SetWidth(6); frame.castbar.spark:SetHeight(addon.sizes.frame.cbheight + 6)

	--[[ uninterruptible cast shield -----------------------------------------
	frame.castbar.shield = frame.castbar.bar:CreateTexture(nil, 'ARTWORK')
	frame.castbar.shield:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\Shield')
	frame.castbar.shield:SetTexCoord(0, .53125, 0, .625)

	frame.castbar.shield:SetWidth(addon.sizes.tex.shieldw); frame.castbar.shield:SetHeight(addon.sizes.tex.shieldh)
	frame.castbar.shield:SetPoint('LEFT', frame.castbar.bg, -7, 0)

	frame.castbar.shield:SetBlendMode('BLEND')
	frame.castbar.shield:SetDrawLayer('ARTWORK', 7)
	frame.castbar.shield:SetVertexColor(unpack(mod.db.profile.display.shieldbarcolour))
	
	frame.castbar.shield:Hide()
--	]]
	-- cast bar text -------------------------------------------------------
	if self.db.profile.display.spellname then
		frame.castbar.name = frame:CreateFontString(frame.castbar.bar, {
			size = 'small' })
        
        if addon.db.profile.general.leftie then
            frame.castbar.name:SetPoint('TOPLEFT', frame.castbar.bar, 'BOTTOMLEFT', 2.5, -3)
            frame.castbar.name:SetPoint('TOPRIGHT', frame.castbar.bar, 'BOTTOMRIGHT')
            frame.castbar.name:SetJustifyH('LEFT')
        else
            frame.castbar.name:SetPoint('TOP', frame.castbar.bar, 'BOTTOM', 0, -3)
        end
	end

	if self.db.profile.display.casttime then
		frame.castbar.curr = frame:CreateFontString(frame.castbar.bar, {
			size = 'small' })

        if addon.db.profile.general.leftie then
            frame.castbar.curr:SetPoint('TOPRIGHT', frame.castbar.bar, 'BOTTOMRIGHT', -2.5, -3)
            frame.castbar.curr:SetJustifyH('RIGHT')

            if frame.castbar.name then
                frame.castbar.name:SetPoint('RIGHT', frame.castbar.curr, 'LEFT')
            end
        else
            frame.castbar.curr:SetPoint('LEFT', frame.castbar.bg, 'RIGHT', 2, 0)
        end
	end

	if self.db.profile.display.spellicon then
		frame.castbar.icon = frame.castbar:CreateTexture(nil, 'ARTWORK', nil, 7)
		frame.castbar.icon:SetTexCoord(.1, .9, .1, .9)

		frame.castbar.icon.bg = frame.castbar:CreateTexture(nil, 'ARTWORK', nil, 0)
		frame.castbar.icon.bg:SetTexture(kui.m.t.solid)
		frame.castbar.icon.bg:SetVertexColor(0,0,0)
		frame.castbar.icon.bg:SetWidth(addon.sizes.frame.icon);frame.castbar.icon.bg:SetHeight(addon.sizes.frame.icon)
		frame.castbar.icon.bg:SetPoint(
			'TOPRIGHT', frame.health, 'TOPLEFT', -2, 1)
		
		frame.castbar.icon:SetPoint(
			'TOPLEFT', frame.castbar.icon.bg, 'TOPLEFT', 1, -1)
		frame.castbar.icon:SetPoint(
			'BOTTOMRIGHT', frame.castbar.icon.bg, 'BOTTOMRIGHT', -1, 1)
		
	--	frame.castbar.icon.bg:SetDrawLayer('ARTWORK', 1)
	--	frame.castbar.icon:SetDrawLayer('ARTWORK', 2)
	--	frame.castbar.icon:SetFrameLevel(frame.castbar.icon.bg:GetFrameLevel()+1)
	end

	-- scripts -------------------------------------------------------------
--	frame.oldCastbar:HookScript('OnShow', OnDefaultCastbarShow)
--	frame.oldCastbar:HookScript('OnHide', OnDefaultCastbarHide)
-- addon:HookScript -- frame.castbar:HookScript('OnUpdate', function() OnCastbarUpdate(this, elapsed) end)

	frame.castbar:SetScript('OnUpdate', function() mod:OnCastbarUpdate(this:GetParent(), arg1) end)

end
------------------------------------------------------------------------ Hide --
function mod:HideCastbar(msg, frame)
    if frame.castbar then
    	ResetFade(frame)
    end
end

---------------------------------------------------- Post db change functions --
mod.configChangedFuncs = { runOnce = {} }
mod.configChangedFuncs.runOnce.enabled = function(val)
	if val then
		mod:Enable()
	else
		mod:Disable()
	end
end

mod.configChangedFuncs.shieldbarcolour = function(frame, val)
	frame.castbar.shield:SetVertexColor(unpack(val))
end

-------------------------------------------------------------------- Register --
function mod:GetOptions()
	return {
		enabled = {
			name = 'Enable cast bar',
			desc = 'Show cast bars (at all)',
			type = 'toggle',
			order = 0,
			disabled = false
		},
		display = {
			name = 'Display',
			type = 'group',
			inline = true,
			disabled = function(info)
				return not self.db.profile.enabled
			end,
			args = {
				casttime = {
					name = 'Show cast time',
					desc = 'Show cast time and time remaining',
					type = 'toggle',
					width = 'double',
					order = 20
				},
				spellname = {
					name = 'Show spell name',
					type = 'toggle',
					order = 15
				},
				spellicon = {
					name = 'Show spell icon',
					type = 'toggle',
					order = 10
				},
				barcolour = {
					name = 'Bar colour',
					desc = 'The colour of the cast bar during interruptible casts',
					type = 'color',
					order = 0
				},
	--[[			shieldbarcolour = {
					name = 'Uninterruptible colour',
					desc = 'The colour of the cast bar and shield during UNinterruptible casts.',
					type = 'color',
					order = 5
				},
	]]
				cbheight = {
					name = 'Height',
					desc = 'The height of castbars on nameplates. Also affects the size of the spell icon.',
					order = 25,
					type = 'range',
					step = 1,
					min = 1,
					softMax = 10,
					max = 50
				},
			}
		}
	}
end

function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {
		profile = {
			enabled   = true,
			display = {
				casttime        = false,
				spellname       = true,
				spellicon       = true,
				cbheight        = 4,
				barcolour       = { .43, .47, .55, 1 },
--				shieldbarcolour = { .8,  .1,  .1,  1 },
			}
		}
	})

	addon:RegisterSize('frame', 'cbheight', self.db.profile.display.cbheight)
	addon:RegisterSize('frame', 'icon', 
		addon.db.profile.general.hheight + addon.defaultSizes.frame.cbheight + 1)
--	addon:RegisterSize('tex', 'shieldw', 10)
--	addon:RegisterSize('tex', 'shieldh', 12)

	addon:InitModuleOptions(self)
	mod:SetEnabledState(self.db.profile.enabled)
end

function mod:OnEnable()
	self:RegisterMessage('KuiNameplates_PostCreate',   'CreateCastbar')
	self:RegisterMessage('KuiNameplates_PostHide', 'HideCastbar')
--	self:RegisterMessage('KuiNameplates_PostTarget', 'OnFrameTarget')
--	self:RegisterMessage('KuiNameplates_TargetUpdate', 'PLAYER_TARGET_CHANGED')
	--self:RegisterMessage('KuiNameplates_TargetUpdate', 'OnCastbarUpdate')

	if addon.superwow then
		self:RegisterEvent("UNIT_CASTEVENT", OnCastEvent)
	else
	    mod.uc.RegisterCallback(self, "NewCast", OnStartCast)
	    mod.uc.RegisterCallback(self, "EndCastOrBuff", OnEndCast)
	end


	local _,frame
    for _, frame in pairs(addon.frameList) do
    	if not frame.kui or not frame.kui.castbar then
    		self:CreateCastbar(nil, frame.kui)
    	end
	end
end

function mod:OnDisable()
	local _,frame
	for _, frame in pairs(addon.frameList) do
		self:HideCastbar(nil, frame.kui)
	end
	self:UnregisterEvent("UNIT_CASTEVENT")
	self.uc.UnregisterAllCallbacks(self)
end
