local addonName, addon = ...

addon.Media = addon.Media or {}

local Media = addon.Media
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

Media.defaultBarTexture = "Luna Minimalist"
Media.defaultBarTexturePath = "Interface\\AddOns\\Phoenix\\media\\Minimalist"
Media.defaultFont = "Aldrich"
Media.defaultBarStyle = "minimal_clean"
Media.barStyles = {
    { id = "classic_ebb", name = "Classic EBB", family = "Classic", texture = "Interface\\TargetingFrame\\UI-StatusBar", background = { 0.01, 0.01, 0.01, 0.9 }, border = { 0.18, 0.18, 0.18, 1 }, buff = { 0.08, 0.36, 0.78, 0.96 }, debuff = { 0.78, 0.08, 0.08, 0.96 }, text = { 1, 1, 1, 1 }, duration = { 1, 1, 1, 1 }, borderSize = 1, iconInset = 2 },
    { id = "luna", name = "Luna Classic", family = "Luna", texture = "You Are The Best!", background = { 0.02, 0.04, 0.07, 0.88 }, border = { 0.12, 0.26, 0.4, 1 }, buff = { 0.2, 0.55, 0.95, 0.86 }, debuff = { 0.85, 0.2, 0.2, 0.88 }, text = { 1, 0.88, 0.4, 1 }, duration = { 1, 0.9, 0.52, 1 }, borderSize = 1, iconInset = 4 },
    { id = "luna_glass", name = "Luna Glass", family = "Luna", texture = "You Are The Best!", background = { 0.03, 0.1, 0.16, 0.74 }, border = { 0.2, 0.7, 0.9, 0.85 }, buff = { 0.12, 0.7, 1, 0.76 }, debuff = { 1, 0.25, 0.28, 0.82 }, text = { 0.9, 0.98, 1, 1 }, duration = { 0.48, 0.9, 1, 1 }, borderSize = 1, iconInset = 4 },
    { id = "luna_bold", name = "Luna Bold", family = "Luna", texture = "You Are The Best!", background = { 0.01, 0.01, 0.01, 0.96 }, border = { 0.75, 0.75, 0.75, 1 }, buff = { 0.1, 0.42, 0.9, 0.96 }, debuff = { 0.92, 0.08, 0.08, 0.96 }, text = { 1, 1, 1, 1 }, duration = { 1, 1, 1, 1 }, borderSize = 2, iconInset = 5 },
    { id = "minimal_clean", name = "Minimal Clean", family = "Minimal", texture = "Luna Minimalist", background = { 0.015, 0.015, 0.015, 0.88 }, border = { 0.22, 0.22, 0.22, 1 }, buff = { 0.16, 0.5, 0.92, 0.88 }, debuff = { 0.82, 0.18, 0.18, 0.9 }, text = { 0.92, 0.92, 0.92, 1 }, duration = { 0.8, 0.8, 0.8, 1 }, borderSize = 1, iconInset = 4 },
    { id = "minimal_frost", name = "Minimal Frost", family = "Minimal", texture = "Luna Minimalist", background = { 0.04, 0.08, 0.12, 0.9 }, border = { 0.3, 0.65, 0.82, 0.9 }, buff = { 0.2, 0.72, 0.95, 0.88 }, debuff = { 0.9, 0.24, 0.2, 0.88 }, text = { 0.84, 0.96, 1, 1 }, duration = { 0.55, 0.85, 1, 1 }, borderSize = 1, iconInset = 4 },
    { id = "minimal_ember", name = "Minimal Ember", family = "Minimal", texture = "Luna Minimalist", background = { 0.11, 0.04, 0.02, 0.92 }, border = { 0.72, 0.34, 0.12, 0.9 }, buff = { 0.2, 0.5, 0.9, 0.88 }, debuff = { 0.98, 0.23, 0.08, 0.92 }, text = { 1, 0.84, 0.58, 1 }, duration = { 1, 0.62, 0.28, 1 }, borderSize = 1, iconInset = 4 },
    { id = "combat_steel", name = "Combat Steel", family = "Combat", texture = "Interface\\TargetingFrame\\UI-StatusBar", background = { 0.035, 0.04, 0.05, 0.96 }, border = { 0.34, 0.4, 0.46, 1 }, buff = { 0.16, 0.48, 0.88, 0.96 }, debuff = { 0.82, 0.16, 0.16, 0.96 }, text = { 0.9, 0.92, 0.95, 1 }, duration = { 0.74, 0.8, 0.88, 1 }, borderSize = 2, iconInset = 5 },
    { id = "combat_radar", name = "Combat Radar", family = "Combat", texture = "Interface\\TargetingFrame\\UI-StatusBar", background = { 0.015, 0.06, 0.035, 0.94 }, border = { 0.12, 0.58, 0.3, 0.9 }, buff = { 0.12, 0.7, 0.5, 0.9 }, debuff = { 0.92, 0.18, 0.16, 0.92 }, text = { 0.75, 1, 0.84, 1 }, duration = { 0.4, 0.92, 0.65, 1 }, borderSize = 1, iconInset = 4 },
    { id = "arcane_night", name = "Arcane Night", family = "Arcane", texture = "You Are The Best!", background = { 0.06, 0.03, 0.1, 0.94 }, border = { 0.42, 0.3, 0.72, 0.9 }, buff = { 0.3, 0.48, 0.98, 0.9 }, debuff = { 0.92, 0.2, 0.32, 0.9 }, text = { 0.92, 0.86, 1, 1 }, duration = { 0.72, 0.6, 1, 1 }, borderSize = 1, iconInset = 4 },
    { id = "arcane_neon", name = "Arcane Neon", family = "Arcane", texture = "Luna Minimalist", background = { 0.015, 0.015, 0.04, 0.96 }, border = { 0.28, 0.78, 0.86, 0.95 }, buff = { 0.1, 0.74, 0.96, 0.9 }, debuff = { 0.98, 0.16, 0.28, 0.92 }, text = { 0.8, 0.98, 1, 1 }, duration = { 0.3, 0.92, 1, 1 }, borderSize = 2, iconInset = 5 },
}
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
        LSM:Register(LSM.MediaType.FONT, font.name, "Interface\\AddOns\\Phoenix\\media\\fonts\\" .. font.file)
    end
end

function Media:GetBarTexture()
    local textureName = addon.db and addon.db.profile and addon.db.profile.barTexture or self.defaultBarTexture
    if LSM then
        return LSM:Fetch(LSM.MediaType.STATUSBAR, textureName, true) or self.defaultBarTexturePath
    end
    return self.defaultBarTexturePath
end

function Media:GetBarStyle()
    local styleId = addon.db and addon.db.profile and addon.db.profile.barStyle or self.defaultBarStyle
    for _, style in ipairs(self.barStyles) do
        if style.id == styleId then
            return style
        end
    end
    return self.barStyles[1]
end

function Media:GetBarStyleTexture(style)
    local textureName = style and style.texture or self.defaultBarTexture
    if string.find(textureName, "^Interface\\") then
        return textureName
    end
    if LSM then
        return LSM:Fetch(LSM.MediaType.STATUSBAR, textureName, true) or self.defaultBarTexturePath
    end
    return self.defaultBarTexturePath
end

function Media:GetBarStyleNames()
    local names = {}
    for _, style in ipairs(self.barStyles) do
        table.insert(names, style.name)
    end
    return names
end

function Media:CycleBarStyle(direction)
    local currentStyle = self:GetBarStyle()
    direction = direction == -1 and -1 or 1
    for index, style in ipairs(self.barStyles) do
        if style.id == currentStyle.id then
            local nextIndex = index + direction
            if nextIndex < 1 then
                nextIndex = #self.barStyles
            elseif nextIndex > #self.barStyles then
                nextIndex = 1
            end
            local nextStyle = self.barStyles[nextIndex]
            addon.db.profile.barStyle = nextStyle.id
            return nextStyle
        end
    end
end

function Media:GetBarFont()
    local fontName = addon.db and addon.db.profile and addon.db.profile.font or self.defaultFont
    if LSM then
        return LSM:Fetch(LSM.MediaType.FONT, fontName, true) or "Interface\\AddOns\\Phoenix\\media\\fonts\\Aldrich.ttf"
    end
    return "Interface\\AddOns\\Phoenix\\media\\fonts\\Aldrich.ttf"
end

function Media:GetFontNames()
    local names = {}
    for _, font in ipairs(self.fonts) do
        table.insert(names, font.name)
    end
    return names
end

addon.Media = Media