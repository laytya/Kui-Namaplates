--[[
-- Kui_Nameplates
-- By Kesava at curse.com
-- All rights reserved

   Rename this file to custom.lua to attach custom code to the addon. Once
   renamed, you'll need to completely restart WoW so that it detects the file.

   Some examples can be found at the following URL:
   https://github.com/rbtwrrr/Kui_Nameplates-Customs
]]
local kn = LibStub('AceAddon-3.0'):GetAddon('KuiNameplates')
local mod = kn:NewModule('Critters', 'AceEvent-3.0')

local critters = {
   ['Adder'] = true,
   ['Beetle'] = true,
   ['Belfry Bat'] = true,
   ['Biletoad'] = true,
   ['Black Rat'] = true,
   ['Brown Prairie Dog'] = true,
   ['Caged Rabbit'] = true,
   ['Caged Sheep'] = true,
   ['Caged Squirrel'] = true,
   ['Caged Toad'] = true,
   ['Cat'] = true,
   ['Chicken'] = true,
   ['Cleo'] = true,
   ['Core Rat'] = true,
   ['Cow'] = true,
   ['Cow'] = true,
   ['Cured Deer'] = true,
   ['Cured Gazelle'] = true,
   ['Deeprun Rat'] = true,
   ['Deer'] = true,
   ['Dog'] = true,
   ['Effsee'] = true,
   ['Enthralled Deeprun Rat'] = true,
   ['Fang'] = true,
   ['Fawn'] = true,
   ['Fire Beetle'] = true,
   ['Fluffy'] = true,
   ['Frog'] = true,
   ['Gazelle'] = true,
   ['Hare'] = true,
   ['Horse'] = true,
   ['Huge Toad'] = true,
   ['Infected Deer'] = true,
   ['Infected Squirrel'] = true,
   ['Jungle Toad'] = true,
   ['Krakle\'s Thermometer'] = true,
   ['Lady'] = true,
   ['Larva'] = true,
   ['Lava Crab'] = true,
   ['Maggot'] = true,
   ['Moccasin'] = true,
   ['Mouse'] = true,
   ['Mr. Bigglesworth'] = true,
   ['Nibbles'] = true,
   ['Noarm'] = true,
   ['Old Blanchy'] = true,
   ['Parrot'] = true,
   ['Pig'] = true,
   ['Pirate treasure trigger mob'] = true,
   ['Plagued Insect'] = true,
   ['Plagued Maggot'] = true,
   ['Plagued Rat'] = true,
   ['Plagueland Termite'] = true,
   ['Polymorphed Chicken'] = true,
   ['Polymorphed Rat'] = true,
   ['Prairie Dog'] = true,
   ['Rabbit'] = true,
   ['Ram'] = true,
   ['Rat'] = true,
   ['Riding Ram'] = true,
   ['Roach'] = true,
   ['Salome'] = true,
   ['School of Fish'] = true,
   ['Scorpion'] = true,
   ['Sheep'] = true,
   ['Sheep'] = true,
   ['Shen\'dralar Wisp'] = true,
   ['Sickly Deer'] = true,
   ['Sickly Gazelle'] = true,
   ['Snake'] = true,
   ['Spider'] = true,
   ['Spike'] = true,
   ['Squirrel'] = true,
   ['Swine'] = true,
   ['Tainted Cockroach'] = true,
   ['Tainted Rat'] = true,
   ['Toad'] = true,
   ['Transporter Malfunction'] = true,
   ['Turtle'] = true,
   ['Underfoot'] = true,
   ['Voice of Elune'] = true,
   ['Waypoint (Only GM can see it)'] = true,
   ['Wisp'] = true,
 }

---------------------------------------------------------------------- Create --
function mod:PostCreate(msg, frame)
	
end

------------------------------------------------------------------------ Show --
local function NameOnlyEnable(f)
   if f.IN_NAMEONLY then return end
   f.IN_NAMEONLY = true
   f:SetCentre()
   kn:UpdateBackground(f, false)
   kn:UpdateHealthBar(f, false)
   kn:UpdateHealthText(f, false)
   kn:UpdateAltHealthText(f, false)
   kn:UpdateLevel(f, false)
   kn:UpdateName(f, false)
   kn:UpdateTargetGlow(f, false)
        end

local function NameOnlyDisable(f)
   if not f.IN_NAMEONLY then return end
   f.IN_NAMEONLY = nil
   f:SetCentre()
   kn:UpdateBackground(f, false)
   kn:UpdateHealthBar(f, false)
   kn:UpdateHealthText(f, false)
   kn:UpdateAltHealthText(f, false)
   kn:UpdateLevel(f, false)
   kn:UpdateName(f, false)
   kn:UpdateTargetGlow(f, false)
end

function mod:PostShow(msg, frame)
   if critters[frame.name.text] and tonumber(frame.level:GetText()) == 1 then
         NameOnlyEnable(frame)
         return
      end
   NameOnlyDisable(frame)
end

------------------------------------------------------------------------ Hide --
function mod:PostHide(msg, frame)
	-- Place code to be performed after a frame is hidden here.
end

---------------------------------------------------------------------- Target --
function mod:PostTarget(msg, frame)
	-- Place code to be performed when a frame becomes the player's target here.
end

-------------------------------------------------------------------- Register --
mod:RegisterMessage('KuiNameplates_PostCreate', 'PostCreate')
mod:RegisterMessage('KuiNameplates_PostShow', 'PostShow')
mod:RegisterMessage('KuiNameplates_PostHide', 'PostHide')
mod:RegisterMessage('KuiNameplates_PostTarget', 'PostTarget')
