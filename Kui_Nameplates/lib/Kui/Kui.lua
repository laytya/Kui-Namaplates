local MAJOR, MINOR = 'Kui-1.0', 12
local kui = LibStub:NewLibrary(MAJOR, MINOR)

if not kui then
	-- already registered
	return
end

local getn = table.getn
local len, format, byte = string.len, string.format, string.byte
local floor, ceil, mod = math.floor, math.ceil, math.mod
local superwow = SpellInfo
--------------------------------------------------------------- media / files --
local media = "Interface\\AddOns\\Kui_Media\\"
kui.m = {
	t = {
		-- borders
		shadow	= media .. 't\\shadowBorder',
		rounded	= media .. 't\\solidRoundedBorder',
	
		-- textures
		solid		= media .. 't\\solid',
		innerShade	= media .. 't\\innerShade',
		
		-- progress bars
		bar		= media .. 't\\bar',
		oldbar  = media .. 't\\bar-old',
		sbar	= media .. 't\\barSmall',

		empty = media..'t\\empty',
	},
	f = {
		yanone	 = media..'f\\yanone.ttf',
     	francois = media..'f\\francois.ttf',
	},
}
------------------------------------------------------------------ var tables --
local ct = { -- classification table
	elite     = { '+',  'elite'      },
	rare      = { 'r',  'rare'       },
	rareelite = { 'r+', 'rare elite' },
	worldboss = { 'b',  'boss'       }
}
RAID_CLASS_COLORS = {
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
	["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, colorStr = "ff69ccf0" },
	["ROGUE"]   = { r = 1,    g = 0.96, b = 0.41, colorStr = "fffff569" },
	["DRUID"]   = { r = 1,    g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
	["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
	["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.0,  colorStr = "ff0070de" },
	["PRIEST"]  = { r = 1,    g = 1,    b = 1,    colorStr = "ffffffff" },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
  }

  RAID_CLASS_COLORS = setmetatable(RAID_CLASS_COLORS, { __index = function(tab,key)
	return { r = 0.6,  g = 0.6,  b = 0.6,  colorStr = "ff999999" }
  end})
------------------------------------------------------------------- functions --
kui.GetClassColour = function(class, str)
	local _
	if not class then
		_, class = UnitClass('player')
	elseif not RAID_CLASS_COLORS[class] then
		-- assume class is a unit
		_, class =  UnitClass(class)
	end
	
	if CUSTOM_CLASS_COLORS then
		class = CUSTOM_CLASS_COLORS[class]
	else
		class = RAID_CLASS_COLORS[class]
	end
	
	if str then
		return format("%02x%02x%02x", class.r*255, class.g*255, class.b*255)
	else
		return class
	end
end

kui.UnitIsPet = function(unit)
	return (not UnitIsPlayer(unit) and UnitPlayerControlled(unit))
end

kui.GetUnitColour = function(unit, str)
	-- class colour for players or pets
	-- faction colour for NPCs
	local ret, r, g, b
	
	if (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit))
		or UnitIsDeadOrGhost(unit)
		or not UnitIsConnected(unit)
	then
		ret = { r = .5, g = .5, b = .5 }
	else
		if UnitIsPlayer(unit) or kui.UnitIsPet(unit) then
			return kui.GetClassColour(unit, str)
		else
			r, g, b = UnitSelectionColor(unit)
			ret = { r = r, g = g, b = b }
		end
	end
	
	if str then
		return format("%02x%02x%02x", ret.r*255, ret.g*255, ret.b*255)
	else
		return ret
	end
end

kui.UnitLevel = function(unit, long)
	local level, classification =
		UnitLevel(unit), UnitClassification(unit)
	local diff = 0 --todo GetQuestDifficultyColor(level <= 0 and 999 or level)
	
	if ct[classification] then
		classification = long and ct[classification][2] or ct[classification][1]
	else
		classification = ''
	end
	
	if level == -1 then
		level = '??'
	end
	
	return level, classification, diff
end

kui.UnitGUID = function( unit)
	if not unit then return nil end
	if superwow then
		local _, guid = UnitExists(unit)
		return guid
	else 
		local uname = UnitName(unit)
		if not uname then return end
		local ulevel = kui.UnitLevel(unit, true)
		local _, uclass = UnitClass(unit)	
			
		return kui.StringHash((uname or "")..(ulevel or "")..(uclass or "")..(kui.UnitIsPet(unit) and "Pet" or ""))
	end
end

kui.ModifyFontFlags = function(fs, io, flag)
	local font, size, flags = fs:GetFont()
	local flagStart,flagEnd = strfind(flags, flag)

	if io and not flagStart then
		-- add flag
		flags = flags..' '..flag
	elseif not io and flagStart then
		-- remove flag
		flags = strsub(flags, 0, flagStart-1) .. strsub(flags, flagEnd+1)
	end

	fs:SetFont(font, size, flags)
end

kui.CreateFontString = function(parent, args)
	local ob, font, size, outline, alpha, shadow, mono
	args = args or {}

	if args.reset then
		-- to change an already existing fontString
		ob = parent
	else
		ob = parent:CreateFontString(nil, 'OVERLAY')
	end

	font	= args.font or 'Fonts\\FRIZQT__.TTF'
	size	= args.size or 12
	outline	= args.outline or nil
	mono    = args.mono or args.monochrome or nil
	alpha	= args.alpha or 1
	shadow	= args.shadow or false

	ob:SetFont(font, size, (outline and 'OUTLINE' or '')..(mono and ' MONOCHROME' or ''))
	ob:SetAlpha(alpha)
	
	if shadow then
		ob:SetShadowColor(0, 0, 0, 1)
		ob:SetShadowOffset(type(shadow) == 'table' and unpack(shadow) or 1, -1)
	elseif not shadow and args.reset then
		-- remove the shadow
		ob:SetShadowColor(0, 0, 0, 0)
	end
	
	return ob
end

-- Format numbers
kui.num = function(num)
	if num < 1000 then
		return num
	elseif num >= 1000000 then
		return format('%.1fm', num/1000000)
	elseif num >= 1000 then
		return format('%.1fk', num/1000)
	end
end

-- Format times (given in seconds)
kui.FormatTime = function(s)
	if s > 86400 then
		-- days
		return ceil(s/86400) .. 'd', mod(s,86400)
	elseif s >= 3600 then
		-- hours
		return ceil(s/3600) .. 'h', mod(s,3600)
	elseif s >= 60 then
		-- minutes
		return ceil(s/60) .. 'm', mod(s,60)
	elseif s <= 10 then
		return ceil(s), s - format("%.1f", s)
	end
	
	return floor(s), s - floor(s)
end

-- Pluralise a word pertaining to a value
kui.Pluralise = function(word, value, with)
	if value == 1 then
		return word
	else
		return word .. (with and with or 's')
	end
end

kui.StringHash = function(text)
	local counter = 1
  local lenght = len(text)
  for i = 1, lenght, 3 do 
    counter = mod(counter*8161, 4294967279) +  -- 2^32 - 17: Prime!
  	  (byte(text,i)*16776193) +
  	  ((byte(text,i+1) or (lenght-i+256))*8372226) +
  	  ((byte(text,i+2) or (lenght-i+256))*3932164)
  end
  return mod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

-- substr for utf8 characters (which are somtimes longer than 1 byte)
do
	local function chsize(char)
		if not char then
			return 0
		elseif char > 240 then
			return 4
		elseif char > 225 then
			return 3
		elseif char > 192 then
			return 2
		else
			return 1
		end
	end

	-- substr for utf8 characters (which are somtimes longer than 1 byte)
	kui.utf8sub = function(str, startChar, numChars)
		numChars = numChars or getn(str)

		local startIndex = 1
		while startChar > 1 do
			local char = byte(str, startIndex)
			startIndex = startIndex + chsize(char)
			startChar = startChar - 1
		end

		local currentIndex = startIndex

		while numChars > 0 and currentIndex <= getn(str) do
			local char = byte(str, currentIndex)
			currentIndex = currentIndex + chsize(char)
			numChars = numChars - 1
		end

		return str:sub(startIndex, currentIndex - 1)
	end
end

-- Frame fading functions
-- (without the taint of UIFrameFade & the lag of AnimationGroups)
kui.frameFadeFrame = CreateFrame('Frame')
kui.FADEFRAMES = {}

kui.frameIsFading = function(frame)
	for index, value in pairs(kui.FADEFRAMES) do
		if value == frame then
			return true
		end
	end
end

kui.frameFadeRemoveFrame = function(frame)
	tDeleteItem(kui.FADEFRAMES, frame)
end

kui.frameFadeOnUpdate = function(self, elapsed)
	local frame, info
	for index, value in pairs(kui.FADEFRAMES) do
		frame, info = value, value.fadeInfo
		
		if info.startDelay and info.startDelay > 0 then
			info.startDelay = info.startDelay - elapsed
		else
			info.fadeTimer = (info.fadeTimer and info.fadeTimer + elapsed) or 0
			
			if info.fadeTimer < info.timeToFade then
				-- perform animation in either direction
				if info.mode == 'IN' then
					frame:SetAlpha(
						(info.fadeTimer / info.timeToFade) *
						(info.endAlpha - info.startAlpha) +
						info.startAlpha
					)
				elseif info.mode == 'OUT' then
					frame:SetAlpha(
						((info.timeToFade - info.fadeTimer) / info.timeToFade) *
						(info.startAlpha - info.endAlpha) + info.endAlpha
					)
				end
			else
				-- animation has ended
				frame:SetAlpha(info.endAlpha)
				
				if info.fadeHoldTime and info.fadeHoldTime > 0 then
					info.fadeHoldTime = info.fadeHoldTime - elapsed
				else
					kui.frameFadeRemoveFrame(frame)
					
					if info.finishedFunc then
						info.finishedFunc(frame)
						info.finishedFunc = nil
					end
				end
			end
		end
	end
	
	if getn(kui.FADEFRAMES) == 0 then
		self:SetScript('OnUpdate', nil)
	end
end

--[[
	info = {
		mode			= "IN" (nil) or "OUT",
		startAlpha		= alpha value to start at,
		endAlpha		= alpha value to end at,
		timeToFade		= duration of animation,
		startDelay		= seconds to wait before starting animation,
		fadeHoldTime 	= seconds to wait after ending animation before calling finishedFunc,
		finishedFunc	= function to call after animation has ended,
	}

	If you plan to reuse `info`, it should be passed as a single table,
	NOT a reference, as the table will be directly edited.
]]
kui.frameFade = function(frame, info)
    if not frame then return end
    if kui.frameIsFading(frame) then 
    	-- cancel the current operation
    	-- the code calling this should make sure not to interrupt a
    	-- necessary finishedFunc. This will entirely skip it.
    	kui.frameFadeRemoveFrame(frame)
    end

    info		= info or {}
    info.mode	= info.mode or 'IN'
	
    if info.mode == 'IN' then
		info.startAlpha	= info.startAlpha or 0
		info.endAlpha	= info.endAlpha or 1
	elseif info.mode == 'OUT' then
		info.startAlpha	= info.startAlpha or 1
		info.endAlpha	= info.endAlpha or 0
	end
	
	frame:SetAlpha(info.startAlpha)
	frame.fadeInfo = info

	tinsert(kui.FADEFRAMES, frame)
	kui.frameFadeFrame:SetScript('OnUpdate', function() kui.frameFadeOnUpdate(this, arg1) end)
end
