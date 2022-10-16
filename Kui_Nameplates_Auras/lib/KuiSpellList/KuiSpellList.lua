local MAJOR, MINOR = 'KuiSpellList-1.0', 6
local KuiSpellList = LibStub:NewLibrary(MAJOR, MINOR)
local _

if not KuiSpellList then
	-- already registered
	return
end

local listeners = {}
local whitelist = {
--[[ Important spells ----------------------------------------------------------
	Target auras which the player needs to keep track of.

	-- LEGEND --
	gp = guaranteed passive
	nd = no damage
	td = tanking dot
	ma = modifies another ability when active
]]
	DRUID = { 
--[[		BS['Entangling Roots']          = { t="cast", d = 1.5 },
        BS['Healing Touch']             = { t="cast", d = 3},
        BS['Hibernate']                 = { t="cast", d = 1.5},
        BS['Rebirth']                   = { t="cast", d = 2},
        BS['Regrowth']                  = { t="cast", d = 2},
        BS['Soothe Animal']             = { t="cast", d = 1.5},
        BS['Starfire']                  = { t="cast", d = 3},
        BS['Teleport: Moonglade']       = { t="cast", d = 10},
        BS['Wrath']                     = { t="cast", d = 1.5},
		
		BS['Hibernate']                = { t="debuff", d = 40, sc = 'Magic'},
		
		BS['Moonfire']         		 = { t = "instacast" },
	
		[770] = "Faerie Fire"
		[1079] = "Rip"
		[1822] = "Rake"
		[8921] = "Moonfire"
		[9007] = "Pounce Bleed"
		[77758] = "Bear Thrash; td ma"
		[106830] = "Cat Thrash"
		[93402] = "Sunfire"
		[33745] = "Lacerate"
		[102546] = "Pounce"
		
		[339] = "Entangling Roots"
		[2637] = "Hibernate"
		[6795] = "Growl"
		[16914] = "Hurricane"
		[19975] = "Nature's grasp roots"
		[22570] = "Maim"
		[33786] = "Cyclone"
		--[58180] = "Infected Wounds; gp nd"
		[78675] = "Solar Beam silence"
		[102795] = "Bear Hug"

		[1126] = "Mark Of the wild"
		[29166] = "Innervate"
		[110309] = "Symbiosis"

		[774] = "Rejuvenation"
		[8936] = "Regrowth"
		[33763] = "Lifebloom"
		[48438] = "Wild Growth"
		[102342] = "Ironbark"

		-- talents
		--[16979] = "Wild Charge: bear; gp nd"
		--[49376] = "Wild Charge: cat; gp nd"
		[102351] = "Cenarion Ward"
		[102355] = "Faerie Swarm"
		[102359] = "Mass Entanglement"
		[61391] = "Typhoon Daze"
		[99] = "Disorienting Roar"
		[5211] = "Mighty Bash"
]]	
	},
	HUNTER = { -- 5.2 COMPLETE
--[[
	[1130] = "Hunter's mark"
		[3674] = "Black Arrow"
		[53301] = "Explosive Shot"
		[63468] = "Piercing Shots"
		[118253] = "Serpent Sting"

		[5116] = "Concussive Shot"
		[19503] = "Scatter Shot"
		[20736] = "Distracting Shot"
		[24394] = "Intimidation"
		[35101] = "Concussive Barrage"
		[64803] = "Entrapment"
		[82654] = "Widow Venom"
		[131894] = "Murder by way of crow"

		[3355] = "Freezing Trap"
		[13812] = "Explosive Trap"
		[135299] = "Ice Trap TODO isn't classed as caused by player"

		[34477] = "Misdirection"

		-- talents
		[136634] = "Narrow Escape"
		[34490] = "Silencing Shot"
		[19386] = "Wyvern Sting"
		[117405] = "Binding Shot"
		[117526] = "Binding Shot stun"
		[120761] = "Glaive Toss slow"
		[121414] = "Glaive Toss slow 2"
]]	},
	MAGE = { -- 5.2 COMPLETE
--[[		[116] = "Frostbolt Debuff"
		[11366] = "Pyroblast"
		[12654] = "Ignite"
		[31589] = "Slow"
		[83853] = "Combustion"
		[132210] = "Pyromaniac"
		
		[118] = "Polymorph"
		[28271] = "Polymorph: turtle"
		[28272] = "Polymorph: pig"
		[61305] = "Polymorph: cat"
		[61721] = "Polymorph: rabbit"
		[61780] = "Polymorph: turkey"
		[44572] = "Deep Freeze"
	
		[1459] = "Arcane Brilliance"
		
		-- talents
		[111264] = "Ice Ward"
		[114923] = "Nether Tempest"
		[44457] = "Living Bomb"
		[112948] = "Frost Bomb"
	},
	DEATHKNIGHT = { -- 5.2 COMPLETE
		[55095] = "Frost Fever"
		[55078] = "Blood Plague"
		[114866] = "Soul Reaper"

		[43265] = "Death And decay"
		[45524] = "Chains Of ice"
		[49560] = "Death Grip taunt"
		[50435] = "Chillblains"
		[56222] = "Dark Command		"
		[108194] = "Asphyxiate Stun"
		
		[3714] = "Path Of frost"
		[57330] = "Horn Of winter"

		-- talents
		[115000] = "Remorseless Winter slow"
		[115001] = "Remorseless Winter stun"
]]	},
	WARRIOR = { -- 5.2 COMPLETE
--[[		[86346] = "Colossus Smash"
		[113746] = "Weakened Armour"

		[355] = "Taunt"
		[676] = "Disarm"
		[1160] = "Demoralizing Shout"
		[1715] = "Hamstring"
		[5246] = "Intimidating Shout"
		[7922] = "Charge Stun"
		[18498] = "Gag Order"
		[64382] = "Shattering Throw"
		[115767] = "Deep Wounds; td"
		[137637] = "Warbringer Slow"
		
		[469] = "Commanding Shout"
		[3411] = "Intervene"
		[6673] = "Battle Shout"
		
		                 -- talents
		[12323] = "Piercing Howl"
		[107566] = "Staggering Shout"
		[132168] = "Shockwave Debuff"
		[114029] = "Safeguard"
		[114030] = "Vigilance"
		[113344] = "Bloodbath Debuff"
		[132169] = "Storm Bolt debuff"
]]	},
	PALADIN = { -- 5.2 COMPLETE
--[[		[114163] = "Eternal Flame"
		[53563] = { colour = {1,.5,0} },  -- beacon of light
		[20925] = { colour = {1,1,.3} },  -- sacred shield
		
		[19740] = { colour = {.2,.2,1} }, -- blessing of might
		[20217] = { colour = {1,.3,.3} }, -- blessing of kings
		
		[26573] = "Consecration; td"
		[31803] = "Censure; td"
		
		                 -- hand of...
		[114039] = "Purity"
		[6940] = "Sacrifice"
		[1044] = "Freedom"
		[1038] = "Salvation"
		[1022] = "Protection"
		
		[853] = "Hammer Of justice"
		[2812] = "Denounce"
		[10326] = "Turn Evil"
		[20066] = "Repentance"
		[31935] = "Avenger's shield silence"
		[62124] = "Reckoning"
		[105593] = "Fist Of justice"
		[119072] = "Holy Wrath stun"

		[114165] = "Holy Prism"
		[114916] = "Execution Sentence dot"
		[114917] = "Stay Of execution hot"
]]	},
	WARLOCK = { -- 5.2 COMPLETE
--[[		[5697]  = "Unending Breath"
		[20707]  = "Soulstone"
		[109773] = "Dark Intent"
	
		[172] = "Corruption, demo. version"
		[146739] = "Corruption"
		[114790] = "Soulburn: Seed of Corruption"
		[348] = "Immolate"
		[108686] = "Immolate (aoe)"
		[980] = "Agony"
		[27243] = "Seed of corruption"
		[30108] = "Unstable Affliction"
		[47960] = "Shadowflame"
		[48181] = "Haunt"
		[80240] = "Havoc"
		
		[1490] = "Curse of the elements"
		[18223] = "Curse of exhaustion"
		[109466] = "Curse of enfeeblement"
		
		[710] = "Banish"
		[1098] = "Enslave Demon"
		[5782] = "Fear"

		                 -- metamorphosis:
		[603] = "Doom"
		[124915] = "Chaos Wave"
		[116202] = "Aura of the elements"
		[116198] = "Aura of enfeeblement"
		
		                 -- talents:
		[5484] = "Howl of terror"
		[111397] = "Blood Fear"
]]	},
	SHAMAN = { -- 5.2 COMPLETE
--[[		[8050] = "Flame Shock"
		[8056] = "Frost Shock slow"
		[63685] = "Frost Shock root"
		[51490] = "Thunderstorm Slow"
		[17364] = "Stormstrike"
		[61882] = "Earthquake"
		
		[3600] = "Earthbind Totem passive"
		[64695] = "Earthgrap Totem root"
		[116947] = "Earthgrap Totem slow"

		[546] = "Water Walking"
		[974] = "Earth Shield"
		[51945] = "Earthliving"
		[61295] = "Riptide"
		
		[51514] = "Hex"
		[76780] = "Bind Elemental"
]]	},
	PRIEST = { -- 5.2 COMPLETE
--[[		[139] = "Renew"
		[6346] = "Fear Ward"
		[33206] = "Pain Suppression"
		[41635] = "Prayer Of mending buff"
		[47753] = "Divine Aegis"
		[47788] = "Guardian Spirit"
		[114908] = "Spirit Shell shield"
		
		[17] = "Power Word: shield"
		[21562] = "Power Word: fortitude"
	
		[2096] = "Mind Vision"
		[8122] = "Psychic Scream"
		[9484] = "Shackle Undead"
		[64044] = "Psychic Horror"
		[111759] = "Levitate"
		
		[589] = "Shadow Word: pain"
		[2944] = "Devouring Plague"
		[14914] = "Holy Fire"
		[34914] = "Vampiric Touch"
		
		                 -- talents:
		[605] = "Dominate Mind"
		[114404] = "Void Tendril root"
		[113792] = "Psychic Terror"
		[129250] = "Power Word: solace"
]]	},
	ROGUE = { -- 5.2 COMPLETE
--[[		[703] = "Garrote"
		[1943] = "Rupture"
		[79140] = "Vendetta"
		[84617] = "Revealing Strike"
		[89775] = "Hemorrhage"
		[113746] = "Weakened Armour"
		[122233] = "Crimson Tempest"

		[2818] = "Deadly Poison"
		[3409] = "Crippling Poison"
		[115196] = "Debilitating Poison"
		[5760] = "Mind Numbing poison"
		[115194] = "Mind Paralysis"
		[8680] = "Wound Poison"

		[408] = "Kidney Shot"
		[1776] = "Gouge"
		[1833] = "Cheap Shot"
		[2094] = "Blind"
		[6770] = "Sap"
		[26679] = "Deadly throw"
		[51722] = "Dismantle"
		[88611] = "Smoke bomb"

        [57934] = "Tricks of the trade"

                         -- talents:
        [112961] = "Leeching poison"
        [113952] = "Paralytic poison"
        [113953] = "Paralysis"
        [115197] = "Partial paralysis"
        [137619] = "Marked for death"
]]	},

	GlobalSelf = {
		[20549] = "War stomp"
		
	},

-- Important auras regardless of caster (cc, flags...) -------------------------
--[[
	Global = {
		-- PVP --
		[23335] = "Silverwing Flag"
		[23333] = "Warsong Flag"
	},
]]
}

KuiSpellList.RegisterChanged = function(table, method)
	-- register listener for whitelist updates
	tinsert(listeners, { table, method })
end

KuiSpellList.WhitelistChanged = function()
	-- inform listeners of whitelist update
	for _,listener in ipairs(listeners) do
		if (listener[1])[listener[2]] then
			(listener[1])[listener[2]]()
		end
	end
end

KuiSpellList.AppendGlobalSpells = function(toList)
	for spellid,_ in pairs(whitelist.GlobalSelf) do
		toList[spellid] = true
	end
	return toList
end

KuiSpellList.GetDefaultSpells = function(class,onlyClass)
	-- get spell list, ignoring KuiSpellListCustom
	local list = {}

	-- return a copy of the list rather than a reference
	for spellid,_ in pairs(whitelist[class]) do
		list[spellid] = true
	end

	if not onlyClass then
		KuiSpellList.AppendGlobalSpells(list)
	end

	return list
end

KuiSpellList.GetImportantSpells = function(class)
	-- get spell list and merge with KuiSpellListCustom if it is set
	local list = KuiSpellList.GetDefaultSpells(class)

	if KuiSpellListCustom then
		for _,group in pairs({class,'GlobalSelf'}) do
			if KuiSpellListCustom.Ignore and
			   KuiSpellListCustom.Ignore[group]
			then
				-- remove ignored spells
				for spellid,_ in pairs(KuiSpellListCustom.Ignore[group]) do
					list[spellid] = nil
				end
			end

			if KuiSpellListCustom.Classes and
			   KuiSpellListCustom.Classes[group]
			then
				-- merge custom added spells
				for spellid,_ in pairs(KuiSpellListCustom.Classes[group]) do
					list[spellid] = true
				end
			end
		end
	end

	return list
end
