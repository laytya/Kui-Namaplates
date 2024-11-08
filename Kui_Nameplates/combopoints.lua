--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
]]

local kui = LibStub('Kui-1.0')


do
	local _, class = UnitClass'player'
	if class ~= 'ROGUE' and class ~= 'DRUID' then 
		return
	end
end


	
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = addon:NewModule('ComboPoints', 'AceEvent-3.0')
local _

mod.uiName = 'Combo points'

local colours = {
	full         = {  r= 1,  g= 1,  b=.1   },
	partial      = {  r=.79, g=.35, b=.1   },
	step         = {  r=.0525,  g=.1625,  b=0     },
	glowFull     = {  r=1,   g=1,   b=.1, a= .6 },
	glowPartial  = {  r=.7,    g=.3,    b=.1, a= .01 },
	glowStep     = {  r=.0525,  g=.1625,  b=0,  a = 0  },
}
--[[local colours = {
	full         = {  1,   1,  .1     },
	partial      = { .79, .55, .18    },
	anti         = {  1,  .3,  .3     },
	glowFull     = {  1,   1,  .1, .6 },
	glowPartial  = {  0,   0,   0, .3 },
	glowAnti     = {  1,  .1,  .1, .8 }
}]]
local function ComboPointsUpdate(self)
	if self.points and self.points > 0 then
		if self.points == 5 then
			self.colour = colours.full
			self.glowColour = colours.glowFull
		else
			if not self.colour then self.colour = {} end
			local point = self.points - 1
			self.colour.r = colours.partial.r + colours.step.r*point
			self.colour.g = colours.partial.g + colours.step.g*point
			self.colour.b = colours.partial.b + colours.step.b*point
			
			self.glowColour = colours.glowPartial
	--		if not self.glowColour then self.glowColour = {} end
	--		self.glowColour.r = colours.glowPartial.r + colours.glowStep.r*point
	--		self.glowColour.g = colours.glowPartial.g + colours.glowStep.g*point
	--		self.glowColour.b = colours.glowPartial.b + colours.glowStep.b*point
			
		end

		local i
		for i = 1,5 do
			if i <= self.points then
				self[i]:SetAlpha(1)
			else
				self[i]:SetAlpha(.4)
			end
			
			
			
			self[i]:SetVertexColor(self.colour.r, self.colour.g, self.colour.b) --(.2*self.points, 0.5/self.points, .5/self.points)
			self.glows[i]:SetVertexColor(self.glowColour.r, self.glowColour.g, self.glowColour.b, self.glowColour.a)
		end

		self:Show()
	elseif self:IsShown() then
		self:Hide()
	end
end
-------------------------------------------------------------- Event handlers --

function mod:PLAYER_COMBO_POINTS() --event,unit)
	local guid, name = kui.UnitGUID('target'), UnitName('target')
	local f = addon:GetNameplate(guid, name)
	self:OnUpdateTargetFrame("",f)
end
----------------------------------------------------------------------UpdateTarget
function mod:OnUpdateTargetFrame(msg,f)
	if f and f.combopoints then
		local points = GetComboPoints()
		f.combopoints.points = points
		f.combopoints:Update()

		if points > 0 then
			-- clear points on other frames
			local _, frame
			for _, frame in pairs(addon.frameList) do
				if frame.kui.combopoints and frame.kui ~= f then
					self:HideComboPoints(nil, frame.kui)
				end
			end
		end
	end
end
----------------------------------------------------------------------kTarget --
function mod:OnFrameTarget(msg, frame)
	self:PLAYER_COMBO_POINTS()
end
---------------------------------------------------------------------- Create --
function mod:CreateComboPoints(msg, frame)
	-- create combo point icons
	frame.combopoints = CreateFrame('Frame', nil, frame.overlay)
	frame.combopoints.glows = {}
	frame.combopoints:Hide()

	local i, pcp
	for i=0,4 do
		-- create individual combo point icons
		local cp = frame.combopoints:CreateTexture(nil, 'ARTWORK')
		cp:SetDrawLayer('ARTWORK', 2)
		cp:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\combopoint-round')
		cp:SetWidth(addon.sizes.tex.combopoints)
		cp:SetHeight(addon.sizes.tex.combopoints)

		if i == 0 then
			cp:SetPoint('BOTTOM', frame.overlay, 'BOTTOM',
				-(addon.sizes.tex.combopoints-1)*2, -3)
		else
			cp:SetPoint('LEFT', pcp, 'RIGHT', -1, 0)
		end

		tinsert(frame.combopoints, i+1, cp)
		pcp = cp

		-- and their glows
		local glow = frame.combopoints:CreateTexture(nil, 'ARTWORK')

		glow:SetDrawLayer('ARTWORK',1)
		glow:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\combopoint-glow')
		glow:SetWidth(addon.sizes.tex.combopoints+8)
		glow:SetHeight(addon.sizes.tex.combopoints+8)
		glow:SetPoint('CENTER',cp)

		tinsert(frame.combopoints.glows, i+1, glow)
	end

	frame.combopoints.Update = ComboPointsUpdate
end
------------------------------------------------------------------------ Hide --
function mod:HideComboPoints(msg, frame)
	if frame.combopoints then
		frame.combopoints.points = nil
		frame.combopoints:Update()
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

-------------------------------------------------------------------- Register --
function mod:GetOptions()
	return {
		enabled = {
			name = 'Show combo points',
			desc = 'Show combo points on the target',
			type = 'toggle',
			order = 0
		},
		scale = {
			name = 'Icon scale',
			desc = 'The scale of the combo point icons and glow',
			type = 'range',
			order = 5,
			min = 0.1,
			softMin = 0.5,
			softMax = 2
		}
	}
end

function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {
		profile = {
			enabled = true,
			scale   = 1,
		}
	})


	addon:RegisterSize('tex', 'combopoints', 4.5 * self.db.profile.scale)
	addon:RegisterSize('tex', 'cpGlowWidth', 30 * self.db.profile.scale)
	addon:RegisterSize('tex', 'cpGlowHeight', 15 * self.db.profile.scale)
	
	addon:InitModuleOptions(self)
	mod:SetEnabledState(self.db.profile.enabled)
end

function mod:OnEnable()
	self:RegisterMessage('KuiNameplates_PostCreate', 'CreateComboPoints')
	self:RegisterMessage('KuiNameplates_PostHide', 'HideComboPoints')
	self:RegisterMessage('KuiNameplates_PostTarget', 'OnFrameTarget')
	self:RegisterMessage('KuiNameplates_TargetUpdate', 'OnUpdateTargetFrame')

	self:RegisterEvent('PLAYER_COMBO_POINTS')

	local _, frame
	for _, frame in pairs(addon.frameList) do
		if not frame.combopoints then
			self:CreateComboPoints(nil, frame.kui)
		end
	end
end

function mod:OnDisable()
	self:UnregisterEvent('PLAYER_COMBO_POINTS')

	local _, frame
	for _, frame in pairs(addon.frameList) do
		self:HideComboPoints(nil, frame.kui)
	end
end
