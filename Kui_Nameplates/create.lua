--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved
--
-- This file essentially creates "my" core layout. The eventual idea is to split
-- this into a seperate addon. That will come after a few necessary things are
-- ported to support that capability, such as the ability to theme cast bars.
]]
local addon = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local kui = LibStub('Kui-1.0')

------------------------------------------------------------------ Background --
function addon:CreateBackground(frame, f)
    -- frame glow
    --f.bg:SetParent(f)
    f.bg = f:CreateTexture(nil, 'ARTWORK')
    f.bg:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\FrameGlow')
    f.bg:SetTexCoord(0, .469, 0, .625)
    f.bg:SetVertexColor(0, 0, 0, .9)

    -- solid background
    f.bg.fill = f:CreateTexture(nil, 'BACKGROUND')
    f.bg.fill:SetTexture(kui.m.t.solid)
    f.bg.fill:SetVertexColor(0, 0, 0, .8)
    f.bg.fill:SetDrawLayer('ARTWORK', 1) -- 1 sub-layer above .bg
end
function addon:UpdateBackground(f, trivial)
    f.bg:ClearAllPoints()
    f.bg.fill:ClearAllPoints()

    if f.IN_NAMEONLY then
        f.bg:Hide() 
        f.bg.fill:Hide()
    elseif trivial then
        -- switch to trivial sizes
		f.bg.fill:SetWidth(self.sizes.frame.twidth)
		f.bg.fill:SetHeight(self.sizes.frame.theight)
        f.bg.fill:SetPoint('BOTTOMLEFT', f.x, f.y)
        
        f.bg:SetPoint('BOTTOMLEFT', f.bg.fill, 'BOTTOMLEFT',
            -self.sizes.frame.bgOffset/2,
            -self.sizes.frame.bgOffset/2)
        f.bg:SetPoint('TOPRIGHT', f.bg.fill, 'TOPRIGHT',
            self.sizes.frame.bgOffset/2,
            self.sizes.frame.bgOffset/2)
        f.bg:Show() 
        f.bg.fill:Show()
    elseif not trivial then
        -- switch back to normal sizes
	f.bg.fill:SetWidth(self.sizes.frame.width);
	f.bg.fill:SetHeight(self.sizes.frame.height)      
        
        f.bg.fill:SetPoint('BOTTOMLEFT', f.x, f.y)

        f.bg:SetPoint('BOTTOMLEFT', f.bg.fill, 'BOTTOMLEFT',
            -self.sizes.frame.bgOffset,
            -self.sizes.frame.bgOffset)
        f.bg:SetPoint('TOPRIGHT', f.bg.fill, 'TOPRIGHT',
            self.sizes.frame.bgOffset,
            self.sizes.frame.bgOffset)
        f.bg:Show() 
        f.bg.fill:Show()
    end
end
------------------------------------------------------------------ Health bar --
function addon:CreateHealthBar(frame, f)
    f.health = CreateFrame('StatusBar', nil, f)
    f.health:SetStatusBarTexture(addon.bartexture)
	f.health.percent = 100

    if self.SetValueSmooth then
        -- smooth bar
        f.health.OrigSetValue = f.health.SetValue
        f.health.SetValue = self.SetValueSmooth
    end
end

function addon:UpdateHealthBar(f, trivial)
    f.health:ClearAllPoints()
    if f.IN_NAMEONLY then
        f.health:SetWidth(self.sizes.frame.twidth-2)
	    f.health:SetHeight(2)
        f.health:SetPoint('BOTTOMLEFT', f.x+1, f.y+1)
    elseif trivial then
		f.health:SetWidth(self.sizes.frame.twidth-2)
		f.health:SetHeight(self.sizes.frame.theight-2)
        f.health:SetPoint('BOTTOMLEFT', f.x+1, f.y+1)
    elseif not trivial then
		f.health:SetWidth(self.sizes.frame.width - 2)
		f.health:SetHeight(self.sizes.frame.height - 2)
        f.health:SetPoint('BOTTOMLEFT', f.x+1, f.y+1)
    end
end

function addon:UpdateOldFrame(f, trivial)
    if f.kui and f.kui.IN_NAMEONLY then
        f:SetWidth(self.sizes.frame.twidth)
        f:SetHeight(12)
    elseif trivial then
        f:SetWidth(self.sizes.frame.twidth)
        f:SetHeight(self.sizes.frame.theight + 10 -self.db.profile.text.healthoffset)
    elseif not trivial then
        f:SetWidth(self.sizes.frame.width)
        f:SetHeight(self.sizes.frame.height + 10 -self.db.profile.text.healthoffset )
    end
end

------------------------------------------------------------------- Highlight --
function addon:CreateHighlight(frame, f)
    if not self.db.profile.general.highlight then return end

    f.highlight = f.overlay:CreateTexture(nil, 'ARTWORK')
    f.highlight:SetTexture(addon.bartexture)
    f.highlight:SetAllPoints(f.health)

    f.highlight:SetVertexColor(1, 1, 1)
    f.highlight:SetBlendMode('ADD')
    f.highlight:SetAlpha(.4)
    f.highlight:Hide()
end
----------------------------------------------------------------- Health text --
function addon:CreateHealthText(frame, f)
    f.health.p = f:CreateFontString(f.overlay, {
        font = self.font,
        size = self.db.profile.general.leftie and 'large' or 'name',
        alpha = 1,
        outline = "OUTLINE" })

    f.health.p:SetHeight(10)
    f.health.p:SetJustifyH('RIGHT')
    f.health.p:SetJustifyV('BOTTOM')

    if self.db.profile.hp.mouseover then
        f.health.p:Hide()
    end
end
function addon:UpdateHealthText(f, trivial)
    if trivial or f.IN_NAMEONLY then
        f.health.p:Hide()
    else
        if not self.db.profile.hp.mouseover then
            f.health.p:Show()
        end

        if self.db.profile.general.leftie then
            f.health.p:SetPoint('BOTTOMRIGHT', f.health, 'TOPRIGHT',
                                -2.5, -self.db.profile.text.healthoffset)
        else
            f.health.p:SetPoint('TOPRIGHT', f.health, 'BOTTOMRIGHT',
                                -2.5, self.db.profile.text.healthoffset + 4)
        end
    end
end
------------------------------------------------------------- Alt health text --
function addon:CreateAltHealthText(frame, f)
    f.health.mo = f:CreateFontString(f.overlay, {
        font = self.font, size = 'small', alpha = .6, outline = "OUTLINE" })

    f.health.mo:SetHeight(10)
    f.health.mo:SetJustifyH('RIGHT')
    f.health.mo:SetJustifyV('BOTTOM')

    if self.db.profile.hp.mouseover then
        f.health.mo:Hide()
    end
end
function addon:UpdateAltHealthText(f, trivial)
    if not f.health.mo or f.IN_NAMEONLY then return end
    if trivial then
        f.health.mo:Hide()
    else
        if not self.db.profile.hp.mouseover then
            f.health.mo:Show()
        end

        if self.db.profile.general.leftie then
            f.health.mo:SetPoint('TOPRIGHT', f.health, 'BOTTOMRIGHT',
                                 -2.5, self.db.profile.text.healthoffset + 3)
        else
            f.health.mo:SetPoint('BOTTOMRIGHT', f.health.p, 'BOTTOMLEFT',0, 0)
        end
    end
end
------------------------------------------------------------------ Level text --
function addon:CreateLevel(frame, f)
    if not f.level then return end

    f.level = f:CreateFontString(f.level, { reset = true,
        font = self.font,
        size = 'name',
        alpha = 1,
        outline = 'OUTLINE'
    })
    f.level:SetParent(f.overlay)
    f.level:SetJustifyH('LEFT')
    f.level:SetJustifyV('BOTTOM')
    f.level:SetHeight(10)
    f.level:ClearAllPoints()

    f.level.enabled = true
end
function addon:UpdateLevel(f, trivial)
    if not f.level.enabled or f.IN_NAMEONLY then
        f.level:Hide()
        return
    end

    if trivial then
        f.level:Hide()
    else
        f.level:Show()
        f.level:SetPoint('TOPLEFT', f.health, 'BOTTOMLEFT',
                         2.5, self.db.profile.text.healthoffset + 4)
    end
end
------------------------------------------------------------------- Name text --
function addon:CreateName(frame, f) 
    f.name = f:CreateFontString(f.overlay, {
        font = self.font, size = 'name', outline = 'OUTLINE' })
    f.name:SetJustifyV('BOTTOM')
    f.name:SetHeight(10)
end
function addon:UpdateName(f, trivial)
    f.name:ClearAllPoints()

	-- silly hacky way of fixing horizontal jitter with center aligned texts
	local offset
	if trivial or not self.db.profile.general.leftie then
		local swidth = f.name:GetStringWidth()
		swidth = swidth - abs(swidth)
		offset = (swidth > .7 or swidth < .2) and .5 or 0
	end

    if trivial then
        f.name:SetPoint('BOTTOM', f.health, 'TOP', offset, -self.db.profile.text.healthoffset)
		f.name:SetWidth(addon.sizes.frame.twidth * 2)
		f.name:SetJustifyH('CENTER')
    else
        if self.db.profile.general.leftie then
            f.name:SetPoint('BOTTOMLEFT', f.health, 'TOPLEFT',
                            2.5, -self.db.profile.text.healthoffset)

            f.name:SetPoint('RIGHT', f.health.p, 'LEFT')
            f.name:SetJustifyH('LEFT')
        else
            -- move to top center
            f.name:SetPoint('BOTTOM', f.health, 'TOP',
                            offset, -self.db.profile.text.healthoffset)
			f.name:SetWidth(addon.sizes.frame.width * 2)
        end
    end
end
----------------------------------------------------------------- Target glow --
function addon:CreateTargetGlow(f)
    f.targetGlow = f.overlay:CreateTexture(nil, 'ARTWORK')
    f.targetGlow:SetTexture('Interface\\AddOns\\Kui_Nameplates\\media\\target-glow')
    f.targetGlow:SetTexCoord(0, .593, 0, .875)
    f.targetGlow:SetPoint('TOP', f.overlay, 'BOTTOM', 0, 1)
    f.targetGlow:SetVertexColor(unpack(self.db.profile.general.targetglowcolour))
    f.targetGlow:Hide()
end
function addon:UpdateTargetGlow(f, trivial)
    if not f.targetGlow then return end
    if f.IN_NAMEONLY then
        f.targetGlow:SetWidth(self.sizes.tex.ttargetGlowW)
        f.targetGlow:SetHeight(self.sizes.tex.targetGlowH)
    elseif trivial then
		f.targetGlow:SetWidth(self.sizes.tex.ttargetGlowW)
		f.targetGlow:SetHeight(self.sizes.tex.targetGlowH)
    else
		f.targetGlow:SetWidth(self.sizes.tex.targetGlowW)
		f.targetGlow:SetHeight(self.sizes.tex.targetGlowH)
    end
end

-- target arrows ###############################################################
do
    local function Arrows_Hide(self)
        self.l:Hide()
        self.r:Hide()
    end
    local function Arrows_Show(self)
        self.l:Show()
        self.r:Show()
    end
    local function Arrows_SetVertexColor(self, r, g, b, a)
        self.l:SetVertexColor( r, g, b, a)
        self.l:SetAlpha(1)
        self.r:SetVertexColor( r, g, b, a)
        self.r:SetAlpha(1)
    end
    local function Arrows_UpdatePosition(self)
        self.l:SetPoint('RIGHT',self.parent.bg,'LEFT',7,0) --TARGET_ARROWS_INSET
        self.r:SetPoint('LEFT',self.parent.bg,'RIGHT',-7,0)
    end
    local function Arrows_SetSize(self,size)
        self.l:SetHeight(size)
        self.l:SetWidth(size)
        self.r:SetHeight(size)
        self.r:SetWidth(size)
        self:UpdatePosition()
    end

    function addon:UpdateTargetArrows(f)
        if not self.db.profile.general.targetarrows or f.IN_NAMEONLY then
            if f.TargetArrows then f.TargetArrows:Hide() end
            return
        end

        if f.target then
            f.TargetArrows.l:SetTexture("Interface\\AddOns\\Kui_Nameplates\\media\\targetarrows3")
            f.TargetArrows.r:SetTexture("Interface\\AddOns\\Kui_Nameplates\\media\\targetarrows3")
            f.TargetArrows:SetVertexColor(unpack(self.db.profile.general.targetglowcolour))
            f.TargetArrows:SetSize(self.db.profile.general.targetarrowssize)
            f.TargetArrows:Show()
        else
            f.TargetArrows:Hide()
        end
    end
    function addon:CreateTargetArrows(f)
        if not self.db.profile.general.targetarrows or f.TargetArrows then return end

        local left = f.health:CreateTexture(nil,'ARTWORK',nil,4)
        left:SetBlendMode('BLEND')

        local right = f.health:CreateTexture(nil,'ARTWORK',nil,4)
        right:SetBlendMode('BLEND')
        right:SetTexCoord(1,0,0,1)

        local arrows = {
            Hide = Arrows_Hide,
            Show = Arrows_Show,
            SetVertexColor = Arrows_SetVertexColor,
            UpdatePosition = Arrows_UpdatePosition,
            SetSize = Arrows_SetSize,
            parent = f,
            l = left,
            r = right,
        }

        f.TargetArrows = arrows
    end
    function addon:configChangedTargetArrows()
        if not self.db.profile.general.targetarrows then return end
        for _,f in addon.frameList do
            self:CreateTargetArrows(f.kui)
        end
    end

end

-- raid icon ###################################################################
local PositionRaidIcon = {
    function(f) return f.icon:SetPoint('RIGHT',f.overlay,'LEFT',-8,0) end,
    function(f) return f.icon:SetPoint('BOTTOM',f.overlay,'TOP',0,12) end,
    function(f) return f.icon:SetPoint('LEFT',f.overlay,'RIGHT',8,0) end,
    function(f) return f.icon:SetPoint('TOP',f.overlay,'BOTTOM',0,-8) end,
}
function addon:UpdateRaidIcon(f)
    f.icon:SetParent(f.overlay)
    f.icon:SetHeight(addon.sizes.tex.raidicon)
    f.icon:SetWidth(addon.sizes.tex.raidicon)

    f.icon:ClearAllPoints()
    PositionRaidIcon[addon.db.profile.general.raidicon_side](f)
end