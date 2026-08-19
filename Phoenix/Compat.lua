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

local weaponSlots = {
    { id = 16, name = "Main Hand Enchant" },
    { id = 17, name = "Off Hand Enchant" },
}

local weaponEnchantNames = {}
local weaponTooltip

local function extractEnchantName(text)
    if type(text) ~= "string" then
        return nil
    end

    local plainText = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    plainText = string.gsub(plainText, "|r", "")
    local name = string.match(plainText, "^(.+) %([^%)]*%d[^%)]*%)$")
    if name then
        return string.gsub(name, " %([^%)]*%)", "")
    end
    return nil
end

function Compat:GetWeaponEnchantName(slot, enchantId)
    if enchantId and weaponEnchantNames[enchantId] then
        return weaponEnchantNames[enchantId]
    end

    local name
    if self.IsRetail and C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem("player", slot.id)
        for _, line in ipairs(tooltipData and tooltipData.lines or {}) do
            name = extractEnchantName(line.leftText)
            if name then
                break
            end
        end
    else
        if not weaponTooltip then
            weaponTooltip = CreateFrame("GameTooltip", "PhoenixWeaponTooltipScanner", nil, "SharedTooltipTemplate")
            weaponTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        end

        weaponTooltip:ClearLines()
        weaponTooltip:SetInventoryItem("player", slot.id)
        for _, region in ipairs({ weaponTooltip:GetRegions() }) do
            if region:IsObjectType("FontString") then
                name = extractEnchantName(region:GetText())
                if name then
                    break
                end
            end
        end
    end

    if name and enchantId then
        weaponEnchantNames[enchantId] = name
    end
    return name or slot.name
end

function Compat:GetWeaponEnchants()
    local results = {}
    if not GetWeaponEnchantInfo then
        return results
    end

    local enchantData = { GetWeaponEnchantInfo() }
    for index, slot in ipairs(weaponSlots) do
        local offset = (index - 1) * 4
        local hasEnchant = enchantData[offset + 1]
        if hasEnchant then
            local remainingMilliseconds = enchantData[offset + 2] or 0
            local charges = enchantData[offset + 3] or 0
            local enchantId = enchantData[offset + 4]
            local duration = remainingMilliseconds / 1000
            table.insert(results, {
                name = self:GetWeaponEnchantName(slot, enchantId),
                icon = GetInventoryItemTexture and GetInventoryItemTexture("player", slot.id) or "",
                type = "WEAPON",
                unit = "player",
                expiresAt = GetTime() + duration,
                remaining = duration,
                charges = charges,
                spellId = enchantId,
                duration = duration,
                isHelpful = true,
            })
        end
    end

    return results
end

function Compat:SafeFrameLookup(name)
    if not name then
        return nil
    end

    return _G[name]
end

addon.Compat = Compat
