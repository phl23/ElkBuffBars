local _, addon = ...

addon.AuraData = addon.AuraData or {}

local AuraData = addon.AuraData
local Compat = addon.Compat

local function normalizeAura(rawAura, unitToken)
    if not rawAura then
        return nil
    end

    local auraType = rawAura.isHelpful and "BUFF" or rawAura.isHarmful and "DEBUFF" or "UNKNOWN"
    local remaining = rawAura.expirationTime and math.max(0, rawAura.expirationTime - GetTime()) or 0

    return {
        name = rawAura.name or "",
        icon = rawAura.icon or rawAura.texture or "",
        type = auraType,
        unit = unitToken,
        source = rawAura.sourceUnit or rawAura.source or "",
        expiresAt = rawAura.expirationTime or 0,
        remaining = remaining,
        debuffType = rawAura.debuffType or "none",
        charges = rawAura.charges or 0,
        spellId = rawAura.spellId,
        isHelpful = rawAura.isHelpful,
        isHarmful = rawAura.isHarmful,
        canSteal = rawAura.canStealOrPurge,
    }
end

function AuraData:Collect(unitToken, filterType)
    local results = {}
    local auraCount = 0

    if C_UnitAuras and C_UnitAuras.GetAuraDataByUnit then
        local auraList = C_UnitAuras.GetAuraDataByUnit(unitToken, filterType)
        if auraList then
            for _, rawAura in ipairs(auraList) do
                local aura = normalizeAura(rawAura, unitToken)
                if aura then
                    auraCount = auraCount + 1
                    results[auraCount] = aura
                end
            end
            return results
        end
    end

    local index = 1
    while true do
        local rawAura = Compat:GetAuraDataByIndex(unitToken, index, filterType)
        if not rawAura then
            break
        end

        local aura = normalizeAura(rawAura, unitToken)
        if aura then
            auraCount = auraCount + 1
            results[auraCount] = aura
        end

        index = index + 1
    end

    return results
end

function AuraData:CollectForGroup(group)
    if not group or not group.unit then
        return {}
    end

    local filter = group.filter or "HELPFUL"
    return self:Collect(group.unit, filter)
end

addon.AuraData = AuraData
