local media = LibStub("LibSharedMedia-3.0")
local fontPath = "Interface\\Addons\\Kui_Plate_Package\\Kui_Media\\t\\"

for i = 1, 25 do
  media:Register("statusbar", "pfUI-"..string.char(64+i), fontPath .. "pfui\\pfUI-"..string.char(64+i))
end   

media:Register("statusbar", "banto", fontPath .. "chrono\\banto")
media:Register("statusbar", "smooth", fontPath .. "chrono\\smooth")
media:Register("statusbar", "perl", fontPath .. "chrono\\perl")
media:Register("statusbar", "glaze", fontPath .. "chrono\\glaze")
media:Register("statusbar",	"cilo", fontPath .. "chrono\\cilo")
media:Register("statusbar",	"charcoal", fontPath .. "chrono\\Charcoal")
media:Register("statusbar",	"diagonal", fontPath .. "chrono\\Diagonal")
media:Register("statusbar",	"fifths", fontPath .. "chrono\\Fifths")
media:Register("statusbar",	"smoothv2", fontPath .. "chrono\\Smoothv2")
media:Register("statusbar", "Healbot", fontPath .. "chrono\\Healbot")
media:Register("statusbar", "LiteStep", fontPath .. "chrono\\LiteStep")
media:Register("statusbar", "Rocks", fontPath .. "chrono\\Rocks")
media:Register("statusbar", "Runes", fontPath .. "chrono\\Runes")
media:Register("statusbar", "Xeon", fontPath .. "chrono\\Xeon")
