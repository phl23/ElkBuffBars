local _, addon = ...

addon.Compat = addon.Compat or {}

local Compat = addon.Compat

Compat.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Compat.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Compat.IsBurningCrusade = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Compat.IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Compat.IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC

local fallbackDebuffColors = {
    none = { r = 0.5, g = 0.5, b = 0.5 },
    Magic = { r = 0.2, g = 0.6, b = 1.0 },
    Curse = { r = 0.6, g = 0.4, b = 1.0 },
    Disease = { r = 0.6, g = 0.6, b = 0.0 },
    Poison = { r = 0.0, g = 0.6, b = 0.0 },
}

if not _G.DebuffTypeColor then
    _G.DebuffTypeColor = fallbackDebuffColors
end

function Compat:GetDebuffColor(debuffType)
    local tableRef = _G.DebuffTypeColor or fallbackDebuffColors
    local key = debuffType or "none"
    local color = tableRef[key] or tableRef.none or fallbackDebuffColors.none
    return color.r, color.g, color.b
end

function Compat:GetClassColor(className)
    local colorTable = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS or {}
    local color = className and colorTable[className]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

function Compat:GetAuraDataByIndex(unitToken, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
        if auraData then
            return auraData
        end
    end

    local name, texture, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, _, _, _, isFromPlayerOrPlayerPet = UnitAura(unitToken, index, filter)
    if not name then
        return nil
    end

    return {
        name = name,
        icon = texture,
        count = count,
        debuffType = debuffType,
        duration = duration,
        expirationTime = expirationTime,
        sourceUnit = source,
        isStealable = isStealable,
        spellId = spellId,
        isFromPlayerOrPlayerPet = isFromPlayerOrPlayerPet,
        isHelpful = filter == "HELPFUL",
        isHarmful = filter == "HARMFUL",
    }
end

function Compat:SafeFrameLookup(name)
    if not name then
        return nil
    end

    return _G[name]
end

addon.Compat = Compat
