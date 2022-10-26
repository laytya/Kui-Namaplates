--[[
-- Kui_Nameplates_Auras
-- By Kesava at curse.com
-- All rights reserved

   Auras module for Kui_Nameplates core layout.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local spelllist = LibStub('KuiSpellList-1.0')
local kui = LibStub('Kui-1.0')

local mod = addon:NewModule('Auras', 'AceEvent-3.0')
mod.parser = ParserLib:GetInstance("1.1")
mod.uc = LibStub:GetLibrary("UnitCasting-1.1")
local whitelist, _

local GetTime, floor, ceil, fmod, getn, find = GetTime, math.floor, math.ceil, math.mod, table.getn, string.find

-- auras pulsate when they have less than this many seconds remaining
local FADE_THRESHOLD = 5

-- combat log events to listen to for fading auras
local auraEvents = {
	--	['SPELL_DISPEL'] = true,
	['SPELL_AURA_REMOVED'] = true,
	['SPELL_AURA_BROKEN'] = true,
	['SPELL_AURA_BROKEN_SPELL'] = true,
}

local function ArrangeButtons(self)
	local pv, pc
	self.visible = 0

	for k, b in ipairs(self.buttons) do
		if b:IsShown() then
			self.visible = self.visible + 1

			b:ClearAllPoints()

			if pv then
				if fmod((self.visible - 1), (self.frame.trivial and 3 or 5)) == 0 then
					-- start of row
					b:SetPoint('BOTTOMLEFT', pc, 'TOPLEFT', 0, 1)
					pc = b
				else
					-- subsequent button in a row
					b:SetPoint('LEFT', pv, 'RIGHT', 1, 0)
				end
			else
				-- first button
				b:SetPoint('BOTTOMLEFT', 0, 0)
				pc = b
			end

			pv = b
		end
	end

	if self.visible == 0 then
		self:Hide()
	else
		self:Show()
	end
end

-- aura pulsating functions ----------------------------------------------------
local DoPulsateAura
do
	local function OnFadeOutFinished(button)
		button.fading = nil
		button.faded = true
		DoPulsateAura(button)
	end

	local function OnFadeInFinished(button)
		button.fading = nil
		button.faded = nil
		DoPulsateAura(button)
	end

	DoPulsateAura = function(button)
		if button.fading or not button.doPulsate then return end
		button.fading = true

		if button.faded then
			kui.frameFade(button, {
				startAlpha = .5,
				timeToFade = .5,
				finishedFunc = OnFadeInFinished
			})
		else
			kui.frameFade(button, {
				mode = 'OUT',
				endAlpha = .5,
				timeToFade = .5,
				finishedFunc = OnFadeOutFinished
			})
		end
	end
end

local function StopPulsatingAura(button)
	kui.frameFadeRemoveFrame(button)
	button.doPulsate = nil
	button.fading = nil
	button.faded = nil
	button:SetAlpha(1)
end

--------------------------------------------------------------------------------
local function OnAuraUpdate(self, elapsed)
	self.elapsed = self.elapsed - elapsed

	if self.expirationTime and self.elapsed <= 0 then
		local timeLeft = self.expirationTime - GetTime()

		if mod.db.profile.display.pulsate then
			if self.doPulsate and timeLeft > FADE_THRESHOLD then
				-- reset pulsating status if the time is extended
				StopPulsatingAura(self)
			elseif not self.doPulsate and timeLeft <= FADE_THRESHOLD then
				-- make the aura pulsate
				self.doPulsate = true
				DoPulsateAura(self)
			end
		end

		if mod.db.profile.display.timerThreshold > -1 and
			timeLeft > mod.db.profile.display.timerThreshold
		then
			self.time:Hide()
		else
			local timeLeftS

			if mod.db.profile.display.decimal and
				timeLeft <= 1 and timeLeft > 0
			then
				-- decimal places for the last second
				timeLeftS = string.format("%.1f", timeLeft)
			else
				timeLeftS = (timeLeft > 60 and
					ceil(timeLeft / 60) .. 'm' or
					floor(timeLeft)
					)
			end

			if timeLeft <= 5 then
				-- red text
				self.time:SetTextColor(1, 0, 0)
			elseif timeLeft <= 20 then
				-- yellow text
				self.time:SetTextColor(1, 1, 0)
			else
				-- white text
				self.time:SetTextColor(1, 1, 1)
			end

			self.time:SetText(timeLeftS)
			self.time:Show()
		end

		if timeLeft < 0 then
			-- used when a non-targeted mob's auras timer gets below 0
			-- but the combat log hasn't reported that it has faded yet.
			self.time:SetText('0')
		end

		if mod.db.profile.display.decimal and
			timeLeft <= 2 and timeLeft > 0
		then
			-- faster updates in the last two seconds
			self.elapsed = .05
		else
			self.elapsed = .5
		end
	end
end

local function OnAuraShow(self)
	local parent = self:GetParent()
	parent:ArrangeButtons()
end

local function OnAuraHide(self)
	local parent = self:GetParent()

	if parent.spellIds[self.spellId] == self then
		parent.spellIds[self.spellId] = nil
	end

	self.time:Hide()
	self.spellId = nil

	-- reset button pulsating
	StopPulsatingAura(self)

	parent:ArrangeButtons()
end

local function getChronometerTimer(debuffname, target)
	for i = 20, 1, -1 do
		if Chronometer.bars[i].name and Chronometer.bars[i].target
			and (Chronometer.bars[i].target == target or Chronometer.bars[i].target == "none")
			and Chronometer.bars[i].timer.x.tx and Chronometer.bars[i].timer.x.tx == debuffname then

			local registered, time, elapsed, running = Chronometer:CandyBarStatus(Chronometer.bars[i].id)

			if registered and running then
				return time, time - elapsed
			else
				return nil, nil
			end
		end
	end
end

local function GetAuraButton(self, spellId, count, duration, expirationTime)

	--	Sea.io.printTable2({self=self, spellId=spellId, count=count, duration=duration, expirationTime=expirationTime},"",2)

	local button

	duration = duration or 0
	expirationTime = expirationTime or 0
	count = count or 0

	if self.spellIds[spellId] then
		-- use this spell's current button...
		button = self.spellIds[spellId]
	elseif self.visible ~= getn(self.buttons) then
		-- .. or reuse a hidden button...
		for k, b in pairs(self.buttons) do
			if not b:IsShown() then
				button = b
				break
			end
		end
	end

	if not button then
		-- ... or create a new button
		button = CreateFrame('Frame', nil, self)
		button:Hide()

		button.icon = button:CreateTexture(nil, 'ARTWORK')

		button.time = self.frame:CreateFontString(button, {
			size = 'large'
		})
		button.time:SetJustifyH('LEFT')
		button.time:SetPoint('TOPLEFT', -2, 4)
		button.time:Hide()

		button.count = self.frame:CreateFontString(button, {
			outline = 'OUTLINE'
		})
		button.count:SetJustifyH('RIGHT')
		button.count:SetPoint('BOTTOMRIGHT', 2, -2)
		button.count:Hide()

		button:SetBackdrop({ bgFile = kui.m.t.solid })
		button:SetBackdropColor(0, 0, 0)

		button.icon:SetPoint('TOPLEFT', 1, -1)
		button.icon:SetPoint('BOTTOMRIGHT', -1, 1)

		button.icon:SetTexCoord(.1, .9, .2, .8)

		tinsert(self.buttons, button)

		button:SetScript('OnHide', function() OnAuraHide(this) end)
		button:SetScript('OnShow', function() OnAuraShow(this) end)
	end
	if self.frame.totem then
		button:SetHeight(addon.sizes.frame.totemHeight)
		button:SetWidth(addon.sizes.frame.totemWidth)
		button.time = self.frame:CreateFontString(button.time, {
			reset = true, size = 'small'
		})
	elseif self.frame.trivial then
		-- shrink icons for trivial frames!
		button:SetHeight(addon.sizes.frame.tauraHeight)
		button:SetWidth(addon.sizes.frame.tauraWidth)
		button.time = self.frame:CreateFontString(button.time, {
			reset = true, size = 'small'
		})
	else
		-- normal size!
		button:SetHeight(addon.sizes.frame.auraHeight)
		button:SetWidth(addon.sizes.frame.auraWidth)
		button.time = self.frame:CreateFontString(button.time, {
			reset = true, size = 'large'
		})
	end

	button.icon:SetTexture(spellId)

	if count > 1 and not self.frame.trivial then
		button.count:SetText(count)
		button.count:Show()
	else
		button.count:Hide()
	end

	if duration == 0 then
		-- hide time on timeless auras
		button:SetScript('OnUpdate', nil)
		button.time:Hide()
	else
		button:SetScript('OnUpdate', function() OnAuraUpdate(this, arg1) end)
	end

	button.duration = duration
	button.expirationTime = (expirationTime or 0) + GetTime()
	button.spellId = spellId
	button.elapsed = 0

	self.spellIds[spellId] = button

	return button
end

----------------------------------------------------------------------- hooks --
function mod:Create(msg, frame)
	frame.auras = CreateFrame('Frame', nil, frame)
	frame.auras.frame = frame

	-- BOTTOMLEFT is set OnShow
	frame.auras:SetPoint('BOTTOMRIGHT', frame.health, 'TOPRIGHT', -3, 0)
	frame.auras:SetHeight(50)
	frame.auras:Hide()

	frame.auras.visible = 0
	frame.auras.buttons = {}
	frame.auras.spellIds = {}
	frame.auras.GetAuraButton = GetAuraButton
	frame.auras.ArrangeButtons = ArrangeButtons

	frame.auras:SetScript('OnHide', function()

		for k, b in pairs(this.buttons) do
			b:Hide()
		end
		this.visible = 0
	end)
end

local function IsTotem(name)
	for k, v in pairs(KUI_TOTEMS) do
		if find(name, k) then
			return v
		end
	end
	return nil
end

function mod:Show(msg, frame)
	
	local totem = IsTotem(frame and frame.name.text or "")
	frame.totem = nil

	if totem ~= nil then
		frame.trivial = true
		frame.totem = totem
        frame:SetCentre()

        addon:UpdateBackground(frame, frame.trivial)
        addon:UpdateHealthBar(frame, frame.trivial)
        addon:UpdateHealthText(frame, frame.trivial)
        addon:UpdateAltHealthText(frame, frame.trivial)
        addon:UpdateLevel(frame, frame.trivial)
        addon:UpdateName(frame, frame.trivial)
        addon:UpdateTargetGlow(frame, frame.trivial)
	else
		frame.trivial = false
		frame.totem = nil
		frame:SetCentre()

        addon:UpdateBackground(frame, frame.trivial)
        addon:UpdateHealthBar(frame, frame.trivial)
        addon:UpdateHealthText(frame, frame.trivial)
        addon:UpdateAltHealthText(frame, frame.trivial)
        addon:UpdateLevel(frame, frame.trivial)
        addon:UpdateName(frame, frame.trivial)
        addon:UpdateTargetGlow(frame, frame.trivial)
	end

	-- set vertical position of the container frame
	if frame.trivial and frame.totem then
		frame.auras:SetPoint('BOTTOM', frame.health, 'TOP',
			0, addon.sizes.frame.taurasOffset)
	elseif frame.trivial then
		frame.auras:SetPoint('BOTTOMLEFT', frame.health, 'BOTTOMLEFT',
			3, addon.sizes.frame.taurasOffset)
	else
		frame.auras:SetPoint('BOTTOMLEFT', frame.health, 'BOTTOMLEFT',
			3, addon.sizes.frame.aurasOffset)
	end
	if frame.target then
		self:UNIT_AURA('UNIT_AURA', 'target')
		return
	end
	if frame.totem then
		local button = frame.auras:GetAuraButton("Interface\\Icons\\" .. (frame.totem.icon or ""), 0, 0, 0)
		frame.auras:Show()
		button:Show()
		button.used = true
	else
		local buffs = mod.uc.GetBuffs(frame.name.text)
		local guid = addon:GetKnownGUID(frame.name.text) -- Player
		if guid and frame.auras then
			--if not (frame.trivial and not mod.db.profile.showtrivial) then
			for _, info in pairs(buffs) do
				if info.icon then
					local te = guid and info.drTimeEnd or info.timeEnd
					local button = frame.auras:GetAuraButton(info.icon, info.stacks, te - info.timeStart,
						te - GetTime())
					frame.auras:Show()
					button:Show()
					button.used = true
				end
			end
			--end
		end
	end
	-- TODO calculate size of auras & num per column here

end

function mod:Hide(msg, frame)
	if frame.auras then
		frame.auras:Hide()
	end
end

-------------------------------------------------------------- event handlers --
function mod:COMBAT_LOG_EVENT(event, info)
	--	local castTime, event, _, guid, name, _, _, targetGUID, targetName = ...
	--	if not guid then return end
	--	if not auraEvents[event] then return end
	--if guid ~= kui.UnitGUID('player') then return end

	--print(event..' from '..name..' on '..targetName)

	-- fetch the subject's nameplate
	--	Sea.io.printTable2(info)
	if info.type ~= 'buff' or info.type ~= 'debuff' then return end

	if UnitExists("target") and not UnitIsDeadOrGhost("target")
		and UnitName('target') == info.victim then
		self:UNIT_AURA('UNIT_AURA', 'target')
	elseif UnitExists("mouseover") and UnitIsPlayer("mouseover") and not UnitIsDeadOrGhost("mouseover")
		and UnitName('mouseover') == info.victim then
		self:UNIT_AURA('UNIT_AURA', 'mouseover')
	end
	--	local f = addon:GetNameplate(nil, targetName)
	--	if not f or not f.auras then return end

	--print('(frame for guid: '..targetGUID..')')

	--	local spId = select(12, ...)

	--	if f.auras.spellIds[spId] then
	--		f.auras.spellIds[spId]:Hide()
	--	end
end

function mod:PLAYER_TARGET_CHANGED()
	self:UNIT_AURA('UNIT_AURA', 'target')
end

function mod:UPDATE_MOUSEOVER_UNIT()
	if UnitIsPlayer("mouseover") then
		self:UNIT_AURA('UNIT_AURA', 'mouseover')
	end
end

function mod:UNIT_AURA(e, u)
	
	local unit = u and u or arg1
	local frame
	if unit == 'target' then
		frame = addon:GetTargetNameplate()
	else
		frame = addon:GetNameplate(kui.UnitGUID(unit), nil)
	end
	if not frame or not frame.auras then return end
	if frame.trivial and not self.db.profile.showtrivial then return end

	local unitIsPlayer = UnitIsPlayer(unit)
	local filter = UnitIsFriend(unit, 'player')
	local buffs = mod.uc.GetBuffs(frame.name.text)

	for i = 1, 16 do

		--	local name, _, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, i, filter)
		local spellId, count
		if filter == 1 then
			spellId, count = UnitBuff(unit, i)
		else
			spellId, count = UnitDebuff(unit, i)
		end

		local duration, expirationTime = 0, 0
		--[[
		if Chronometer and spellId then
			duration, expirationTime = getChronometerTimer(spellId, GetUnitName(unit))

		end
		]]

		for _, buff in pairs(buffs) do
			if buff.icon == spellId then
				local te = unitIsPlayer and buff.drTimeEnd or buff.timeEnd
				duration, expirationTime = te - buff.timeStart, te - GetTime()
			end
		end

		--name = name and strlower(name) or nil

		if spellId
		--[[	and
		   (not self.db.profile.behav.useWhitelist or
		    (whitelist[spellId] or whitelist[name])) and
		   (duration >= self.db.profile.display.lengthMin) and
		   (self.db.profile.display.lengthMax == -1 or (
		   	duration > 0 and
		    duration <= self.db.profile.display.lengthMax))
	--]]
		then
			--	Sea.io.printTable2({spellId,count,duration,expirationTime},"",2)
			local button = frame.auras:GetAuraButton(spellId, count, duration, expirationTime)
			frame.auras:Show()
			button:Show()
			button.used = true
		end
	end

	for _,button in pairs(frame.auras.buttons) do
	-- hide buttons that weren't used this update
		if not button.used then
			button:Hide()
		end

		button.used = nil
	end
end

local function OnNewBuff(event, info)
	local frame 
	local guid  =  addon:GetKnownGUID(info.caster) -- Player
	if guid then 
		frame = addon:GetNameplate(guid)
	else
		frame = addon:GetTargetNameplate()
		if frame and frame.name.text ~= info.caster then
			return
		end
	end

	if frame and frame.auras then
		--if not (frame.trivial and not mod.db.profile.showtrivial) then
		if info.icon then
			local te = guid and info.drTimeEnd or info.timeEnd
			local button = frame.auras:GetAuraButton(info.icon, info.stacks, te - info.timeStart,
				te - GetTime())
			frame.auras:Show()
			button:Show()
			button.used = true
		end
		--end
	end
end

local function OnEndBuff(event, info)
	local frames = addon:GetNameplates(info.caster)
	for _, frame in pairs(frames) do
		if frame and frame.auras then
			--if not (frame.trivial and not mod.db.profile.showtrivial) then
			if frame.auras.spellIds[info.icon] then
				local button = frame.auras.spellIds[info.icon]
				button.used = nil
				button:Hide()
			end
			--end
		end
	end
end

function mod:WhitelistChanged()
	-- update spell whitelist
	local _, class = UnitClass("player")
	whitelist = spelllist.GetImportantSpells(class)
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
---------------------------------------------------- initialisation functions --
function mod:GetOptions()
	return {
		enabled = {
			name = 'Show my auras',
			desc = 'Display auras cast by you on the current target\'s nameplate',
			type = 'toggle',
			order = 1,
			disabled = false
		},
		showtrivial = {
			name = 'Show on trivial units',
			desc = 'Show auras on trivial (half-size, lower maximum health) nameplates.',
			type = 'toggle',
			order = 3,
			disabled = function()
				return not self.db.profile.enabled
			end,
		},
		display = {
			name = 'Display',
			type = 'group',
			inline = true,
			disabled = function()
				return not self.db.profile.enabled
			end,
			order = 10,
			args = {
				pulsate = {
					name = 'Pulsate auras',
					desc = 'Pulsate aura icons when they have less than 5 seconds remaining.\nSlightly increases memory usage.',
					type = 'toggle',
					order = 5,
				},
				decimal = {
					name = 'Show decimal places',
					desc = 'Show decimal places (.9 to .0) when an aura has less than one second remaining, rather than just showing 0.',
					type = 'toggle',
					order = 8,
				},
				timerThreshold = {
					name = 'Timer threshold (s)',
					desc = 'Timer text will be displayed on auras when their remaining length is less than or equal to this value. -1 to always display timer.',
					type = 'range',
					order = 10,
					min = -1,
					softMax = 180,
					step = 1
				},
				lengthMin = {
					name = 'Effect length minimum (s)',
					desc = 'Auras with a total duration of less than this value will never be displayed. 0 to disable.',
					type = 'range',
					order = 20,
					min = 0,
					softMax = 60,
					step = 1
				},
				lengthMax = {
					name = 'Effect length maximum (s)',
					desc = 'Auras with a total duration greater than this value will never be displayed. -1 to disable.',
					type = 'range',
					order = 30,
					min = -1,
					softMax = 1800,
					step = 1
				},

			}
		},
		behav = {
			name = 'Behaviour',
			type = 'group',
			inline = true,
			disabled = function()
				return not self.db.profile.enabled
			end,
			order = 5,
			args = {
				useWhitelist = {
					name = 'Use whitelist',
					desc = 'Only display spells which your class needs to keep track of for PVP or an effective DPS rotation. Most passive effects are excluded.\n\n|cff00ff00You can use KuiSpellListConfig from Curse.com to customise this list.',
					type = 'toggle',
					order = 0,
				},
			}
		}
	}
end

function mod:OnInitialize()
	self.db = addon.db:RegisterNamespace(self.moduleName, {
		profile = {
			enabled = true,
			showtrivial = false,
			display = {
				pulsate = true,
				decimal = true,
				timerThreshold = 60,
				lengthMin = 0,
				lengthMax = -1,
			},
			behav = {
				useWhitelist = true,
			}
		}
	})

	addon:RegisterSize('frame', 'auraHeight', 14)
	addon:RegisterSize('frame', 'auraWidth', 20)
	addon:RegisterSize('frame', 'tauraHeight', 7)
	addon:RegisterSize('frame', 'tauraWidth', 10)
	addon:RegisterSize('frame', 'totemHeight', 24)
	addon:RegisterSize('frame', 'totemWidth', 24)

	addon:RegisterSize('frame', 'aurasOffset', 20)
	addon:RegisterSize('frame', 'taurasOffset', 10)

	addon:InitModuleOptions(self)
	mod:SetEnabledState(self.db.profile.enabled)

	self:WhitelistChanged()
	spelllist.RegisterChanged(self, 'WhitelistChanged')
end

function mod:OnEnable()
	self:RegisterMessage('KuiNameplates_PostCreate', 'Create')
	self:RegisterMessage('KuiNameplates_PostShow', 'Show')
	self:RegisterMessage('KuiNameplates_PostHide', 'Hide')
	self:RegisterMessage('KuiNameplates_PostTarget', 'PLAYER_TARGET_CHANGED')
	--self:RegisterMessage('KuiNameplates_TargetUpdate', 'PLAYER_TARGET_CHANGED')

--	self:RegisterEvent('UNIT_AURA')
	--	self:RegisterEvent('PLAYER_TARGET_CHANGED')
	self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
	--self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

	-- Buff/Debuff gain handling
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",       function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS",        function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",   function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE",  function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",            function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",           function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",  function (event, info) self:COMBAT_LOG_EVENT(event, info) end)
	--	self.parser:RegisterEvent("KNP_Auras", "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", function (event, info) self:COMBAT_LOG_EVENT(event, info) end)

	mod.uc.RegisterCallback(self, "NewBuff", OnNewBuff)
	mod.uc.RegisterCallback(self, "EndCastOrBuff", OnEndBuff)

	local _, frame
	for _, frame in pairs(addon.frameList) do
		if not frame.auras then
			self:Create(nil, frame.kui)
		end
	end
end

function mod:OnDisable()
--	self:UnregisterEvent('UNIT_AURA')
	self:UnregisterEvent('PLAYER_TARGET_CHANGED')
	self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT')
	self.parser:UnregisterAllEvents("KNP_Auras")
	self.uc.UnregisterAllCallbacks(self)

	local _, frame
	for _, frame in pairs(addon.frameList) do
		self:Hide(nil, frame.kui)
	end
end
