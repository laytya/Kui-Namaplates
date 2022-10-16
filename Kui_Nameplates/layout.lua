--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved

   Things to do when I get the time
   ===
   * customisation for sizes/positions of auras & width of container frame, etc
   * make auras respect nameplate frame width
   * customisation for raid target icons
   * ability to make certain auras bigger
   * add upper limit to number of auras

   * fix horizontal text jitter
   * fix castbar fades out on newly shown frames
]]

local kui = LibStub('Kui-1.0')
local LSM = LibStub('LibSharedMedia-3.0')
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local slowUpdateTime, critUpdateTime = 1, 1/60

local AceCore = LibStub("AceCore-3.0")
local new, del = AceCore.new, AceCore.del
local wipe, truncate = AceCore.wipe, AceCore.truncate
local strsplit = AceCore.strsplit

--------------------------------------------------------------------- globals --
local select, strfind, pairs, ipairs, unpack, tinsert, type, floor
    = select, strfind, pairs, ipairs, unpack, tinsert, type, math.floor
local UnitExists=UnitExists
local getn, setn = table.getn, table.setn
------------------------------------------------------------- Frame functions --
local function SetFrameCentre(f)
    -- using CENTER breaks pixel-perfectness with oddly sized frames
    -- .. so we have to align frames manually.
    local w,h = f:GetWidth(),f:GetHeight()

    if f.trivial then
        f.x = floor((w / 2) - (addon.sizes.frame.twidth / 2))
        f.y = floor((h / 2) - (addon.sizes.frame.theight / 2))
    else
        f.x = floor((w / 2) - (addon.sizes.frame.width / 2))
        f.y = floor((h / 2) - (addon.sizes.frame.height / 2))
    end
end
-- get default health bar colour, parse it into one of our custom colours
-- and the reaction of the unit toward the player
local function SetHealthColour(self,sticky,r,g,b)
	if sticky then
		-- sticky colour; override other colours
		
		self.health:SetStatusBarColor(r,g,b)
		self.stickyHealthColour = true
		self.health.reset = true
		return
	end

	if self.stickyHealthColour then
		if sticky == nil then
			return
		elseif sticky == false then
			-- unstick
			self.stickyHealthColour = false
		end
	end
	local r, g, b
	local classcolor = nil
	
	if self.guid and addon:GetClass(self.guid) then
		classcolor = kui.GetClassColour(addon:GetClass(self.guid))	
	else
		r, g, b = self.oldHealth:GetStatusBarColor()
	end
		
	if self.health.reset  or
       (not classcolor and  (r ~= self.health.r or  g ~= self.health.g or b ~= self.health.b)) or
	   (classcolor and (classcolor.r ~= self.health.r or classcolor.g ~= self.health.g or classcolor.b ~= self.health.b))
    then
		
        -- store the default colour
        if classcolor then 
			self.health.r, self.health.g, self.health.b = classcolor.r, classcolor.g, classcolor.b
		else
        self.health.r, self.health.g, self.health.b = r, g, b
		end
        self.health.reset, self.friend, self.player = nil, nil, nil

        if self.guid and addon:GetClass(self.guid) then
			-- Class colors
			r, g, b = classcolor.r, classcolor.g, classcolor.b
			self.health.reset, self.friend, self.player = nil, true, true	
		elseif self.tapped  then
			r, g, b = unpack(addon.db.profile.general.reactioncolours.tappedcol)
		elseif g > .9 and r == 0 and b == 0 then
            -- friendly NPC
            self.friend = true
				r, g, b = unpack(addon.db.profile.general.reactioncolours.friendlycol)
        elseif b > .9 and r == 0 and g == 0 then
            -- friendly player
            self.friend = true
            self.player = true
			
				r, g, b = unpack(addon.db.profile.general.reactioncolours.playercol)
        elseif r > .9 and g == 0 and b == 0 then
            -- enemy NPC
            r, g, b = unpack(addon.db.profile.general.reactioncolours.hatedcol)
        elseif (r + g) > 1.8 and b == 0 then
            -- neutral NPC
            r, g, b = unpack(addon.db.profile.general.reactioncolours.neutralcol)
        elseif r < .6 and (r+g) == (r+b) then
            -- tapped NPC
            r, g, b = unpack(addon.db.profile.general.reactioncolours.tappedcol)
        else
            -- enemy player, use default UI colour
            self.player = true
        end

        self.health:SetStatusBarColor(r, g, b)
    end
end

local function SetGlowColour(self, r, g, b, a)
    if not r then
        -- set default colour
        r, g, b = 0, 0, 0

        if addon.db.profile.general.glowshadow then
            a = .85
        else
            a = 0
        end
    end

    if not a then
        a = .85
    end

    self.bg:SetVertexColor(r, g, b, a)
end
---------------------------------------------------- Update health bar & text --
local OnHealthValueChanged
do
	local rules,rule,big,sml,condition,display,pattern
	OnHealthValueChanged = function(oldBar, curr)
		if oldBar.oldHealth then
			-- allow calling this as a function of the frame
			oldBar = oldBar.oldHealth
			curr = oldBar:GetValue()
		end
	
		local frame = oldBar.kuiParent.kui --:GetParent():GetParent().kui
		big,sml = nil,nil

		-- store values for external access
		frame.health.min, frame.health.max = oldBar:GetMinMaxValues()
		frame.health.curr = curr
		frame.health.percent = frame.health.curr / frame.health.max * 100

		frame.health:SetMinMaxValues(frame.health.min, frame.health.max)
		frame.health:SetValue(frame.health.curr)
        
--[[        
        -- if "curr" is percentage values
		frame.health.pmin, frame.health.pmax = oldBar:GetMinMaxValues()
		
		local percentOnly, vmax = false, 0
		frame.health.percent = curr
		
		frame.health.min = frame.health.pmin
		frame.health.max = UnitHealthMax("target")
		frame.health.curr = UnitHealth("target")

        frame.health:SetMinMaxValues(frame.health.pmin, frame.health.pmax)
		frame.health:SetValue(frame.health.percent)
]]
--[[
		if  MobHealth_PPP  then
			if MobHealth_GetTargetCurHP and frame.target then
				frame.health.curr = MobHealth_GetTargetCurHP()
				percentOnly = frame.health.curr == nil 
				frame.health.max = MobHealth_GetTargetMaxHP() 
			elseif frame.name.text then
				local index = frame.name.text..":"..(frame.level:GetText() or 99);
				local ppp = MobHealth_PPP( index );
				if ppp ~= 0 then 
					frame.health.curr = floor( curr * ppp + 0.5);
				    frame.health.max = floor( 100 * ppp + 0.5);
					percentOnly = false
				end
			end
		end
]]		
		

		-- select correct health display pattern
		if frame.friend then
			pattern = addon.db.profile.hp.friendly
		else
			pattern = addon.db.profile.hp.hostile
		end

		-- parse pattern into big/sml
		rules = { strsplit(';', pattern) }

		for _, rule in ipairs(rules) do
			condition, display = strsplit(':', rule)

			if condition == '<' then
				condition = frame.health.curr < frame.health.max
			elseif condition == '=' then
				condition = frame.health.curr == frame.health.max
			elseif condition == '<=' or condition == '=<' then
				condition = frame.health.curr <= frame.health.max
			else
				condition = nil
			end
			if condition then
				if display == 'd' then
					big = '-'..kui.num(frame.health.max - frame.health.curr)
					sml = kui.num(frame.health.curr)
				elseif display == 'm' then
					big = kui.num(frame.health.max)
				elseif display == 'c' then
					big = kui.num(frame.health.curr)
					sml = frame.health.curr ~= frame.health.max and kui.num(frame.health.max)
				elseif display == 'p' then
					big = floor(frame.health.percent) .. "%"
					sml = kui.num(frame.health.curr)
				end

				break
			end
		end

		frame.health.p:SetText(big or '')

		if frame.health.mo then
			frame.health.mo:SetText(sml or '')
		end
	end
end
------------------------------------------------------- Frame script handlers --
local function OnFrameEnter(self)
--	Sea.io.print("mouseover")
--    addon:StoreGUID(self, 'mouseover')
    self.highlighted = true

    if self.highlight then
        self.highlight:Show()
    end

	if (not UnitIsTappedByPlayer('mouseover') and UnitIsTapped('mouseover') and UnitCanAttack("player", 'mouseover')) then
		self.tapped = true
	else
		self.tapped = false
	end
	
	
    if addon.db.profile.hp.mouseover then
        self.health.p:Show()
        if self.health.mo then self.health.mo:Show() end
    end
end
local function OnFrameLeave(self)
    self.highlighted = false

    if self.highlight then
        self.highlight:Hide()
    end

    if addon.db.profile.hp.mouseover and self.health and not self.target then
        self.health.p:Hide()
        if self.health.mo then self.health.mo:Hide() end
    end
end
local function OnFrameShow(self)
    self = self.kuiParent
    local f = self.kui
    local trivial = f.firstChild:GetScale() < 1

    -- classifications
    if not trivial and f.level.enabled then
        if f.boss:IsVisible() then
            f.level:SetText('Boss')
            f.level:SetTextColor(1,.2,.2)
            f.level:Show()
 --[[   elseif f.state:IsVisible() then
            if f.state:GetTexture() == "Interface\\Tooltips\\EliteNameplateIcon"
            then
                f.level:SetText(f.level:GetText()..'+')
            else
                f.level:SetText(f.level:GetText()..'r')
            end
 ]]
        end
    else
        f.level:Hide()
    end
--[[
    if f.state:IsVisible() then
        -- hide the elite/rare dragon
        f.state:Hide()
    end
]]
    ---------------------------------------------- Trivial sizing/positioning --
    if addon.uiscale then
        -- change our parent frame size if we're using fixaa..
		f:SetWidth(self:GetWidth()/addon.uiscale); f:SetHeight( self:GetHeight()/addon.uiscale)
    end
    -- otherwise, size is changed automatically thanks to using SetAllPoints

    if trivial and not f.trivial or
       not trivial and f.trivial or
       not f.doneFirstShow
    then
        f.trivial = trivial
        f:SetCentre()

        addon:UpdateBackground(f, trivial)
        addon:UpdateHealthBar(f, trivial)
        addon:UpdateHealthText(f, trivial)
        addon:UpdateAltHealthText(f, trivial)
        addon:UpdateLevel(f, trivial)
        addon:UpdateName(f, trivial)
        addon:UpdateTargetGlow(f, trivial)

        f.doneFirstShow = true
    end

    -- run updates immediately after the frame is shown
    f.elapsed = 0
    f.critElap = 0
	f.tapped = false

	-- reset glow colour
    f:SetGlowColour()

    f.DoShow = true
    -- dispatch the PostShow message after the first UpdateFrame
    f.DispatchPostShow = true 
end
local function OnFrameHide(self)
    self = self.kuiParent
    local f = self.kui
    f:Hide()

    f:SetFrameLevel(0)

    -- force un-highlight
    OnFrameLeave(self)

    if f.targetGlow then
        f.targetGlow:Hide()
    end

    addon:ClearGUID(f)

    -- remove name from store
    -- if there are name duplicates, this will be recreated in an onupdate
    addon:ClearName(f)

    f.lastAlpha = nil
    f.fadingTo  = nil
    f.hasThreat = nil
    f.target    = nil
    f.targetDelay = nil
	f.stickyHealthColour = nil

    -- unset stored health bar colours
    f.health.r, f.health.g, f.health.b, f.health.reset
        = nil, nil, nil, nil

    addon:SendMessage('KuiNameplates_PostHide', 1,  f)
end
-- stuff that needs to be updated every frame
local function OnFrameUpdate(fr, e)
	local f = fr.kuiParent.kui

    f.elapsed   = (f.elapsed or 0) - e
	f.critElap  = (f.critElap or 0) - e

    if f.fixaa then
        ------------------------------------------------------------ Position --
        local scale = f.firstChild:GetParent():GetScale()
		local _, _, _, x, y = f.firstChild:GetParent():GetPoint()
        x = (x / addon.uiscale) * scale
        y = (y / addon.uiscale) * scale

        f:SetPoint('BOTTOMLEFT', WorldFrame, 'BOTTOMLEFT',
            floor(x - (f:GetWidth() / 2)),
            floor(y) - 25)
    end

    -- show the frame after it's been moved so it doesn't flash
    -- .DoShow is set OnFrameShow
    if f.DoShow then
        f:Show()
        f.DoShow = nil
    end

    f.defaultAlpha = fr.kuiParent:GetAlpha()

    ------------------------------------------------------------------- Alpha --
    -- determine alpha value!
    if (f.defaultAlpha == 1 and UnitExists('target'))
       or
       -- avoid fading low hp units
       (((f.friend and addon.db.profile.fade.rules.avoidfriendhp) or
        (not f.friend and addon.db.profile.fade.rules.avoidhostilehp)) and
         f.health.percent <= addon.db.profile.fade.rules.avoidhpval
       )
       or
       -- avoid fading casting units
       (f.castbar and addon.db.profile.fade.rules.avoidcast and f.castbar:IsShown())
       or
       -- avoid fading mouse-over'd units
       (addon.db.profile.fade.fademouse and f.highlighted)
    then
        f.currentAlpha = 1
    elseif UnitExists('target') or addon.db.profile.fade.fadeall then
        -- if a target exists or fadeall is enabled...
        f.currentAlpha = addon.db.profile.fade.fadedalpha or .3
    else
        -- nothing is targeted!
        f.currentAlpha = 1
    end
    ------------------------------------------------------------------ Fading --
    if addon.db.profile.fade.smooth then
        -- track changes in the alpha level and intercept them
        if not f.lastAlpha or f.currentAlpha ~= f.lastAlpha then
            if not f.fadingTo or f.fadingTo ~= f.currentAlpha then
                if kui.frameIsFading(f) then
                    kui.frameFadeRemoveFrame(f)
                end

                -- fade to the new value
                f.fadingTo    = f.currentAlpha
                local alphaChange = (f.fadingTo - (f.lastAlpha or 0))

                kui.frameFade(f, {
                    mode        = alphaChange < 0 and 'OUT' or 'IN',
                    timeToFade  = abs(alphaChange) * (addon.db.profile.fade.fadespeed or .5),
                    startAlpha  = f.lastAlpha or 0,
                    endAlpha    = f.fadingTo,
                    finishedFunc = function()
                        f.fadingTo = nil
                    end,
                })
            end

            f.lastAlpha = f.currentAlpha
        end
    else
        f:SetAlpha(f.currentAlpha)
    end

    -- call delayed updates
    if f.elapsed <= 0 then
        f.elapsed = slowUpdateTime
        f:UpdateFrame()
    end

    if f.critElap <= 0 then
        f.critElap = critUpdateTime
        f:UpdateFrameCritical()
    end
end

-- stuff that can be updated less often
local function UpdateFrame(self)
    -- periodically update the name in order to purge Unknowns due to lag, etc
    self:SetName()

	
	
    -- ensure a frame is still stored for this name, as name conflicts cause
    -- it to be erased when another might still exist
    addon:StoreName(self)

    -- reset/update health bar colour
    self:SetHealthColour()
	
	if UnitName("target") == nil and self.guid == nil then 
		--Set Name text and save it in a list
		self.scanningPlayers = true
		TargetByName(self.name.text, true)
	--	Sea.io.print("-1-")
		addon:StoreGUID(self, 'target')
		ClearTarget()
		self.scanningPlayers = false
	end
	
	if UnitName("mouseover") == self.name.text and self.guid == nil then
	--			Sea.io.print("-3-")
				addon:StoreGUID(self, 'mouseover')
	end
	
    if self.DispatchPostShow then
        -- force initial health update, which relies on health colour
        self:OnHealthValueChanged()

        -- return guid to an assumed unique name
        addon:GetGUID(self)

        addon:SendMessage('KuiNameplates_PostShow', 1, self)
        self.DispatchPostShow = nil
    end
end

-- stuff that needs to be updated often
local function UpdateFrameCritical(self)
    ------------------------------------------------------------------ Threat --
    if self.glow:IsVisible() then
        self.glow.wasVisible = true
		
        -- set glow to the current default ui's colour
        self.glow.r, self.glow.g, self.glow.b = self.oldName:GetTextColor() --self.glow:GetVertexColor()
        self:SetGlowColour(self.glow.r, self.glow.g, self.glow.b)

        if not self.friend and addon.TankModule and addon.TankMode then
            -- in tank mode; is the default glow red (are we tanking)?
			self.hasThreat = true
			self.holdingThreat = self.glow.r > .9 and (self.glow.g + self.glow.b) < .1

			self:SetGlowColour(unpack(addon.TankModule.db.profile.glowcolour))

			if self.holdingThreat then
				self:SetHealthColour(true, unpack(addon.TankModule.db.profile.barcolour))
			else
				-- losing/gaining threat
				self:SetHealthColour(true, unpack(addon.TankModule.db.profile.midcolour))
			end
        end
    elseif self.glow.wasVisible then
        self.glow.wasVisible = nil

        -- restore shadow glow colour
        self:SetGlowColour()

        if self.hasThreat then
            -- lost threat
            self.hasThreat = nil
            self:SetHealthColour(false)
        end
    end
    ------------------------------------------------------------ Target stuff --
    if UnitExists('target') and self.defaultAlpha == 1 and not self.scanningPlayers then
        if not self.target then
            if self.guid and self.guid == kui.UnitGUID('target') then
                -- this is definitely the target
                self.targetDelay = 1
            else
                -- this -may- be the target's frame but we need to wait a moment
                -- before we can be sure.
                -- this alpha update delay is a blizzard issue.
                self.targetDelay = (self.targetDelay and self.targetDelay + 1) or 0
            end

            if self.targetDelay >= 1 then
	 
				-- this is almost probably certainly maybe the target
                -- (the delay may not be long enough, but it already feels
                -- laggy so i'd prefer not to make it longer)
                self.target = true
                self.targetDelay = nil
                if self.guid == nil then
		--			Sea.io.print("-2-")
                addon:StoreGUID(self, 'target')
				end

                -- move this frame above others
      --          self:SetFrameLevel(10)

                if addon.db.profile.hp.mouseover then
                    self.health.p:Show()
                    if self.health.mo then self.health.mo:Show() end
                end

                if self.targetGlow then
                    self.targetGlow:Show()
                end
				if (not UnitIsTappedByPlayer('target') and UnitIsTapped('target') and UnitCanAttack("player", 'target')) then
					self.tapped = true
				else
					self.tapped = false
				end
                addon:SendMessage('KuiNameplates_PostTarget', 1, self)
            end
        end
		addon:SendMessage('KuiNameplates_TargetUpdate', 1, self)
    else
        if self.targetDelay then
            -- it wasn't the target after all. phew.
            self.targetDelay = nil
        end

        if self.target then
            -- or it was, but no longer is.
            self.target = nil

            self:SetFrameLevel(0)

            if self.targetGlow then
                self.targetGlow:Hide()
            end

            if not self.highlighted and addon.db.profile.hp.mouseover then
                self.health.p:Hide()
                if self.health.mo then self.health.mo:Hide() end
            end
        end
    end

    --------------------------------------------------------------- Mouseover --
 --[[ todo ]]
 
	if MouseIsOver(self) then
        if not self.highlighted then
            OnFrameEnter(self)
        end
    elseif self.highlighted then
        OnFrameLeave(self)
    end
 --]]

end

local function SetName(self)
    -- get name from default frame and update our values
    self.name.text = self.oldName:GetText()
    self.name:SetText(self.name.text)
end

--------------------------------------------------------------- KNP functions --
function addon:IsNameplate(frame)
    
	local overlayRegion = frame:GetRegions()
	return (overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == "Interface\\Tooltips\\Nameplate-Border")
	
	--[[
	if frame:GetName() and strfind(frame:GetName(), '^NamePlate%d') then
        local nameTextChild = select(2, frame:GetChildren())
        if nameTextChild then
            local nameTextRegion = nameTextChild:GetRegions()
            return (nameTextRegion and nameTextRegion:GetObjectType() == 'FontString')
        end
    end
	]]
end

function addon:InitFrame(frame)
    -- container for kui objects!
    frame.kui = CreateFrame('Frame', nil, WorldFrame)
    local f = frame.kui

    f.fontObjects = {}

    -- fetch default ui's objects
	
	local healthBar = frame:GetChildren()
	local borderRegion, glowRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion = frame:GetRegions()
	
	
 --   local overlayChild, nameTextChild = frame:GetChildren()
 --   local healthBar, castBar = overlayChild:GetChildren()
--[[
    local _, castbarOverlay, shieldedRegion, spellIconRegion,
          spellNameRegion, spellNameShadow
        = castBar:GetRegions()

    local nameTextRegion = nameTextChild:GetRegions()
    local glowRegion, overlayRegion, highlightRegion, levelTextRegion,
          bossIconRegion, raidIconRegion, stateIconRegion
        = overlayChild:GetRegions()
]]
--    overlayRegion:SetTexture(nil)
--    highlightRegion:SetTexture(nil)
    bossIconRegion:SetTexture(nil)
	borderRegion:SetTexture(nil)
--    shieldedRegion:SetTexture(nil)
--    castbarOverlay:SetTexture(nil)
    glowRegion:SetTexture(nil)
--    spellIconRegion:SetSize(.01,.01)
--    spellNameShadow:SetTexture(nil)
--    spellNameRegion:Hide()

    -- make default healthbar & castbar transparent
    healthBar:SetStatusBarTexture(kui.m.t.empty)
  --  castBar:SetStatusBarTexture(kui.m.t.empty)

    f.firstChild = healthBar

    
    f.glow       = glowRegion
    f.boss       = bossIconRegion
--    f.state      = stateIconRegion
    f.level      = levelTextRegion
    f.icon       = raidIconRegion
--    f.spell      = spellIconRegion
--    f.spellName  = spellNameRegion
--    f.shield     = shieldedRegion
    f.oldHealth  = healthBar
--    f.oldCastbar = castBar

    f.oldName = nameTextRegion
    f.oldName:Hide()

    f.oldHighlight = highlightRegion

    --------------------------------------------------------- Frame functions --
    f.CreateFontString    = addon.CreateFontString
    f.UpdateFrame         = UpdateFrame
    f.UpdateFrameCritical = UpdateFrameCritical
    f.SetName             = SetName
    f.SetHealthColour     = SetHealthColour
    f.SetNameColour       = SetNameColour
    f.SetGlowColour       = SetGlowColour
    f.SetCentre           = SetFrameCentre
    f.OnHealthValueChanged = OnHealthValueChanged

    ------------------------------------------------------------------ Layout --
    if self.db.profile.general.fixaa and addon.uiscale then
        f:SetWidth(frame:GetWidth()/addon.uiscale);
		f:SetHeight( frame:GetHeight()/addon.uiscale)
        f:SetScale(addon.uiscale)

        f:SetPoint('BOTTOMLEFT', UIParent)
        f:Hide()

        f.fixaa = true
    else
        f:ClearAllPoints()
		f:SetAllPoints(frame)
    end

	
    f:SetFrameStrata(self.db.profile.general.strata)
    f:SetFrameLevel(0)

    f:SetCentre()

    self:CreateBackground(frame, f)
    self:CreateHealthBar(frame, f)

    -- overlay (text is parented to this) --------------------------------------
    f.overlay = CreateFrame('Frame', nil, f)
    f.overlay:SetAllPoints(f.health)
    f.overlay:SetFrameLevel(f.health:GetFrameLevel()+1)

    self:CreateHighlight(frame, f)
    self:CreateHealthText(frame, f)

    if self.db.profile.hp.showalt then
        self:CreateAltHealthText(frame, f)
    end

    if self.db.profile.text.level then
        self:CreateLevel(frame, f)
    else
        f.level:Hide()
    end

    self:CreateName(frame, f)

    -- target highlight --------------------------------------------------------
    if self.db.profile.general.targetglow then
        self:CreateTargetGlow(f)
    end

    -- raid icon ---------------------------------------------------------------
    f.icon:SetParent(f.overlay)
    f.icon:SetWidth(addon.sizes.tex.raidicon) 
	f.icon:SetHeight(addon.sizes.tex.raidicon)
    f.icon:ClearAllPoints()
    f.icon:SetPoint('LEFT', f.health, 'RIGHT', 5, 1)

    ----------------------------------------------------------------- Scripts --
    -- used by these scripts
    f.oldHealth.kuiParent = frame

    -- Don't hook these directly to the frame; workaround for issue caused by
    -- current curse.com version of VialCooldowns.
    addon:HookScript(f.oldHealth,'OnShow', function() OnFrameShow(this) end)
    addon:HookScript(f.oldHealth,'OnHide', function() OnFrameHide(this) end)
    addon:HookScript(f.oldHealth,'OnUpdate',function() OnFrameUpdate(this, arg1) end)

    addon:HookScript(f.oldHealth,'OnValueChanged', function() OnHealthValueChanged(this, arg1) end)

    ------------------------------------------------------------ Finishing up --
    addon:SendMessage('KuiNameplates_PostCreate', 1, f)

    if frame:IsShown() then
        -- force OnShow
        OnFrameShow(healthBar)
    else
        f:Hide()
    end
end

---------------------------------------------------------------------- Events --
-- automatic toggling of enemy frames
function addon:PLAYER_REGEN_ENABLED()
   HideNameplates();
end
function addon:PLAYER_REGEN_DISABLED()
   ShowNameplates();
   HideFriendNameplates();
end

------------------------------------------------------------- Script handlers --
do
    local WorldFrame = WorldFrame
    function addon:OnUpdate()
        local frames = { WorldFrame:GetChildren()}

        if getn(frames) ~= self.numFrames then
            local f
			for _, f in ipairs(frames) do
			    if self:IsNameplate(f) and not f.kui then
                    self:InitFrame(f)
                    tinsert(self.frameList, f)
                end
            end

            self.numFrames = getn(frames)
        end
    end
end

function addon:ToggleCombatEvents(io)
    if io then
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
    else
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        self:UnregisterEvent('PLAYER_REGEN_DISABLED')
    end
end