-- FuBar_Kui-Nameplates  by laytya
------------------------------------------------------------
KNPFu = 		AceLibrary("AceAddon-2.0"):new("FuBarPlugin-2.0", "AceDB-2.0")
local KNPFu = KNPFu

--Fubar plugin settings
KNPFu.version = "1.0"
KNPFu.date = "29/06/2018"
KNPFu.hasIcon = "Interface\\AddOns\\FuBar_KuiNameplates\\icon"
KNPFu.canHideText = true
KNPFu.hasNoColor = true
KNPFu.clickableTooltip = false
KNPFu.cannotDetachTooltip = true
KNPFu.hideWithoutStandby = false
KNPFu.profileCode = true
KNPFu.overrideMenu = true

KNPFu.defaultPosition = "RIGHT";
KNPFu.defaultMinimapPosition = 235;

-- localization Lib
local L = 		AceLibrary("AceLocale-2.2"):new("FuBar_Kui-Nameplates"); 

-- tool tip Lib
local tablet = 	AceLibrary("Tablet-2.0")
local dewdrop = AceLibrary("Dewdrop-2.0")
local AceConfigDialog = LibStub('AceConfigDialog-3.0')


-- Menu Items

function KNPFu:OnMenuRequest(level,value)
	if level == 1 then
		dewdrop:AddLine(
				'text', L["Kui-Nameplates"],
--					'secure', v.secure,
				'icon', KNPFu.hasIcon,
				'desc', L["Open Kui-Nameplates Options"],
				'func', (function() 
						if AceConfigDialog.OpenFrames['kuinameplates'] ~= nil then
							AceConfigDialog:Close('kuinameplates')
						else
							AceConfigDialog:Open('kuinameplates')
						end 
				  end),
				
				'disabled', false,
				'closeWhenClicked', true
			)
		
		dewdrop:AddLine()
		dewdrop:AddLine(
			'text', "FuBar Options",
			'hasArrow', true,
			'value', "fubar"
		)
		
		
	elseif level == 2 and value == "fubar" then
		self:AddImpliedMenuOptions(level )	
	end
end


function KNPFu:OnInitialize()
	-- Activate menu options to hide icon/text by activating "AceDB-2.0" DB
	self:RegisterDB("FuBar_KuiNameplatesDB")
end

function KNPFu:OnTextUpdate()
	self:SetText(L["Kui-Nameplates"])
end


-- keep self updated when activated?
function KNPFu:OnEnable()
	self:Update();
end

-- tool tip
function KNPFu:OnTooltipUpdate()
	local cat = tablet:AddCategory('columns', 1)
	cat:AddLine(
		'text', L["TOOLTIP_NOTE"],
		'size', 12
	)
	tablet:SetTitle(L["TOOLTIP_NAME"])
	tablet:SetHint(L["TOOLTIP_HINT1"])
end

-- when Clicked do this
function KNPFu:OnClick()
	if AceConfigDialog.OpenFrames['kuinameplates'] ~= nil then
		AceConfigDialog:Close('kuinameplates')
	else
		AceConfigDialog:Open('kuinameplates')
	end
end
