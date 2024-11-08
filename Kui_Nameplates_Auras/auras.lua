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
local B = LibStub("LibBabble-Spell-3.0")

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
local gratuity = AceLibrary("Gratuity-2.0")

mod.gratuity = gratuity

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
				self.time:SetTextColor(1, 0.2, 0)
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
			self.used = nil
			self:Hide()
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
--[[
	for k, v in pairs(KUI_TOTEMS) do
		if find(name, k) then
			return v
		end
	end

]]

	return KUI_TOTEMS[name]
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
		self:UNIT_AURA('UNIT_AURA', 'target', frame)
		return
	end
	if addon.superwow then
		self:UNIT_AURA('UNIT_AURA', frame.guid, frame)
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

function mod:Update(msg, frame)
	if addon.superwow then
		--self:UNIT_AURA('UNIT_AURA', frame.guid, frame)
		return
	end
end

-------------------------------------------------------------- event handlers --
function mod:COMBAT_LOG_EVENT(event, info)
	if info.type ~= 'buff' or info.type ~= 'debuff' then return end

	if (addon.superwow and LoggingCombat("RAW") == 1 ) then
		local frame = addon:GetNameplate(info.victim)
		if frame then
			self:UNIT_AURA('UNIT_AURA', info.victim, frame)
			return
		end
	end

	local _, targetGUID = UnitExists("target")
	local _, moGUID = UnitExists('mouseover')
	if UnitExists("target") and not UnitIsDeadOrGhost("target")
		and ( UnitName('target') == info.victim or targetGUID == info.victim)then
		self:UNIT_AURA('UNIT_AURA', 'target')
	elseif UnitExists("mouseover") and UnitIsPlayer("mouseover") and not UnitIsDeadOrGhost("mouseover")
		and (UnitName('mouseover') == info.victim or moGUID == info.victim) then
		self:UNIT_AURA('UNIT_AURA', 'mouseover')
	end
end

function mod:PLAYER_TARGET_CHANGED(event, frame)
	self:UNIT_AURA('UNIT_AURA', 'target', frame)
end

function mod:UPDATE_MOUSEOVER_UNIT(event, frame)
	--if UnitIsPlayer("mouseover") then
	self:UNIT_AURA('UNIT_AURA', 'mouseover', frame)
	--printT({"UPDATE_MOUSEOVER_UNIT",UnitName('mouseover'), frame.name.text})
	--end
end

local function getDebuff(spellIcon, unit)
	if not unit or not UnitExists(unit) then return nil, nil end
	local filter = UnitIsFriend(unit, 'player')
	for i = 1, 32 do
		local spellId, count
		if filter == 1 then
			spellId, count = UnitBuff(unit, i)
		else
			spellId, count = UnitDebuff(unit, i)
		end
		if spellIcon == spellId then
			return spellId, count
	end
		
		
		gratuity:Erase()
   		gratuity:SetUnitBuff(unit, i)
   		local spell = gratuity:GetLine(1)
		if spell then
			local spellId = B:GetSpellIcon(spell)
			if spellId then
				return spellId, 1
			end
		end 

		
	end
	return nil, nil
end

local function addAura(spell, buffs, frame)
	for k, buff in pairs(buffs) do
		if spell == buff.spell or spell == buff.icon then
			local te = buff.drTimeEnd
			local duration, expirationTime = te - buff.timeStart, te - GetTime()
			local spellId
			if spell == buff.icon then
				spellId = spell
			else
				spellId = B:GetSpellIcon(spell)
			end
			if spellId then
				local button = frame.auras:GetAuraButton(spellId, count, duration, expirationTime)
				frame.auras:Show()
				button:Show()
				button.used = true
				return k
			end
		end
	end
	return nil
end

function mod:UNIT_AURA(e, u, frame)

	local unit = u and u or arg1
	if not frame then
	if unit == 'target' then
		frame = addon:GetTargetNameplate()
	else
		frame = addon:GetNameplate(kui.UnitGUID(unit), nil)
	end
	end
	if not frame or not frame.auras or frame.name.text ~= UnitName(unit) then return end
	if frame.trivial and not self.db.profile.showtrivial then return end

	local unitIsPlayer = UnitIsPlayer(unit)
	local filter = UnitIsFriend(unit, 'player')
	local _, guid = UnitExists(unit)
	local unitName = (addon.superwow and LoggingCombat("RAW") == 1 ) and guid or frame.name.text
	local buffs = mod.uc.GetBuffs(unitName)
	
	local spellId, count

	for i = 1, 32 do
		if filter == 1 then
			spellId, count = UnitBuff(unit, i)
		else
			spellId, count = UnitDebuff(unit, i)
		end

		--[[
		if Chronometer and spellId then
			duration, expirationTime = getChronometerTimer(spellId, GetUnitName(unit))

		end
		]]
		if spellId then
			local id = addAura(spellId, buffs, frame)
			if id then
				table.remove(buffs, id)
			end
		end
	end
	if unitIsPlayer or (addon.superwow and LoggingCombat("RAW") == 1 ) then

		if unit then
			for i = 1, 32 do
				gratuity:Erase()
   				gratuity:SetUnitBuff(unit, i)
   				local spell = gratuity:GetLine(1)
				if spell then
					local id = addAura(spell, buffs, frame)
					if id then
						table.remove(buffs, id)
					else
						local spellId = B:GetSpellIcon(spell)
						if spellId then
							local button = frame.auras:GetAuraButton(spellId, 1, 0, 0)
			frame.auras:Show()
			button:Show()
			button.used = true
		end
	end
		end
	end
		end
	for k, buff in pairs(buffs) do
		local te = unitIsPlayer and buff.drTimeEnd or buff.timeEnd
			local duration, expirationTime = te - buff.timeStart, te - GetTime()

		local button = frame.auras:GetAuraButton(buff.icon, buff.stacks, duration, expirationTime)
		frame.auras:Show()
		button:Show()
		button.used = true
	end
	end
	for _, button in pairs(frame.auras.buttons) do
	-- hide buttons that weren't used this update
		if not button.used then
			button:Hide()
		end

		button.used = nil
	end
end

local function OnNewBuff(event, info)
	local frame, spellId, count, unit
	local guid = (addon.superwow and LoggingCombat("RAW") == 1 ) and info.caster or addon:GetKnownGUID(info.caster)
	local targetFrame = addon:GetTargetNameplate()
	local moframe = addon:GetMouseoverNameplate()
	 -- Player
	if guid then
		if targetFrame and targetFrame.guid == guid then
			frame = targetFrame
			unit = "target"
		elseif moframe and moframe.guid ==  guid then
			frame =  moFrame
			unit = "mouseover"
		else
		frame = addon:GetNameplate(guid)
			if (addon.superwow and LoggingCombat("RAW") == 1 ) then unit =  info.caster end
		end
	else
		frame = addon:GetTargetNameplate()
		unit = 'target'
		if frame and frame.name.text ~= info.caster then
			return
		end
	end

	if frame and frame.auras then
		--if not (frame.trivial and not mod.db.profile.showtrivial) then
		if info.icon then
			spellId, count = nil, 0
			if unit then
				spellId, count = getDebuff(info.icon, unit)
				if not spellId and not guid then
					return
				end
			elseif not guid then
				return
			end
			if not spellId then
				count = info.stacks
			end
			local te = guid and info.drTimeEnd or info.timeEnd
			local button = frame.auras:GetAuraButton(info.icon, count, te - info.timeStart,
				te - GetTime())
			frame.auras:Show()
			button:Show()
			button.used = true
		end
		--end
	end
end

local function OnEndBuff(event, info)
	local frames, unit, frame
	local guid = (addon.superwow and LoggingCombat("RAW") == 1 ) and info.caster or addon:GetKnownGUID(info.caster)
	local targetFrame = addon:GetTargetNameplate()
	local moframe = addon:GetMouseoverNameplate()

	if guid then
		if targetFrame and targetFrame.guid == guid then
			frame = targetFrame
			unit = "target"
		elseif moframe and moframe.guid ==  guid then
			frame =  moFrame
			unit = "mouseover"
		else
			frame = addon:GetNameplate(guid)
			if (addon.superwow and LoggingCombat("RAW") == 1 ) then unit =  info.caster end
		end
	else
		frame = addon:GetTargetNameplate()
		unit = 'target'
		if frame and frame.name.text ~= info.caster then
			return
		end
	end
	if frame and frame.player and event == "EndDRBuff" then
		frames = { frame }
	elseif event == "EndDRBuff" then
		return
	else
		frames = addon:GetNameplates(info.caster)
	end
	for _, frame in pairs(frames) do
		if frame and frame.auras then
			--if not (frame.trivial and not mod.db.profile.showtrivial) then
			spellId, count = getDebuff(info.icon, unit)
			if frame.auras.spellIds[info.icon] and not spellId then
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
	self:RegisterMessage('KuiNameplates_PostUpdate', 'Update')
	self:RegisterMessage('KuiNameplates_PostTarget', 'PLAYER_TARGET_CHANGED')
	self:RegisterMessage('KuiNameplates_MouseEnter', 'UPDATE_MOUSEOVER_UNIT')

	--	self:RegisterEvent('UNIT_AURA')
	--	self:RegisterEvent('PLAYER_TARGET_CHANGED')
	--self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
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
	mod.uc.RegisterCallback(self, "EndDRBuff", OnEndBuff)

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
