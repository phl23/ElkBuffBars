local addonName, addon = ...

addon.Media = addon.Media or {}

local Media = addon.Media
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

Media.defaultBarTexture = "You Are The Best!"
Media.defaultBarTexturePath = "Interface\\AddOns\\EBBPhoenix\\media\\Minimalist"
Media.defaultFont = "Aldrich"
Media.fonts = {
    { name = "Aldrich", file = "Aldrich.ttf" },
    { name = "Bangers", file = "Bangers.ttf" },
    { name = "Faster One", file = "FasterOne.ttf" },
    { name = "Iceland", file = "Iceland.ttf" },
    { name = "Inconsolata", file = "Inconsolata.ttf" },
    { name = "Trade Winds", file = "TradeWinds.ttf" },
}

if LSM then
    LSM:Register(LSM.MediaType.STATUSBAR, "Luna Minimalist", Media.defaultBarTexturePath)
    for _, font in ipairs(Media.fonts) do
        LSM:Register(LSM.MediaType.FONT, font.name, "Interface\\AddOns\\EBBPhoenix\\media\\fonts\\" .. font.file)
    end
end

function Media:GetBarTexture()
    local textureName = addon.db and addon.db.profile and addon.db.profile.barTexture or self.defaultBarTexture
    if LSM then
        return LSM:Fetch(LSM.MediaType.STATUSBAR, textureName, true) or self.defaultBarTexturePath
    end
    return self.defaultBarTexturePath
end

function Media:GetBarFont()
    local fontName = addon.db and addon.db.profile and addon.db.profile.font or self.defaultFont
    if LSM then
        return LSM:Fetch(LSM.MediaType.FONT, fontName, true) or "Interface\\AddOns\\EBBPhoenix\\media\\fonts\\Aldrich.ttf"
    end
    return "Interface\\AddOns\\EBBPhoenix\\media\\fonts\\Aldrich.ttf"
end

function Media:GetFontNames()
    local names = {}
    for _, font in ipairs(self.fonts) do
        table.insert(names, font.name)
    end
    return names
end

addon.Media = Media