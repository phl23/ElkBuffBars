local _, addon = ...

addon.AuraData = addon.AuraData or {}

local AuraData = addon.AuraData
local Compat = addon.Compat

local function normalizeAura(rawAura, unitToken, auraIndex)
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
        debuffType = rawAura.dispelName or rawAura.debuffType or "none",
        charges = rawAura.applications or rawAura.charges or rawAura.count or 0,
        spellId = rawAura.spellId,
        index = auraIndex or rawAura.index,
        duration = rawAura.duration or 0,
        isHelpful = rawAura.isHelpful,
        isHarmful = rawAura.isHarmful,
        canSteal = rawAura.isStealable or rawAura.canStealOrPurge,
    }
end

function AuraData:Collect(unitToken, filterType)
    local results = {}
    local index = 1
    while true do
        local rawAura = Compat:GetAuraDataByIndex(unitToken, index, filterType)
        if not rawAura then
            break
        end

        local aura = normalizeAura(rawAura, unitToken, index)
        if aura then
            table.insert(results, aura)
        end

        index = index + 1
    end

    table.sort(results, function(left, right)
        local leftExpires = left.expiresAt or 0
        local rightExpires = right.expiresAt or 0

        if leftExpires == 0 then
            return false
        end
        if rightExpires == 0 then
            return true
        end
        return leftExpires < rightExpires
    end)

    return results
end

function AuraData:CollectForGroup(group)
    if not group or not group.unit then
        return {}
    end

    local filter = group.filter or "HELPFUL"
    local results = self:Collect(group.unit, filter)

    if group.config and (group.config.onlyMine or group.config.hidePermanent) then
        local filtered = {}
        for _, aura in ipairs(results) do
            local isMine = aura.source == "player" or aura.source == "pet" or aura.source == "vehicle"
            local isPermanent = not aura.duration or aura.duration <= 0
            if (not group.config.onlyMine or isMine) and (not group.config.hidePermanent or not isPermanent) then
                table.insert(filtered, aura)
            end
        end
        results = filtered
    end

    if group.config and group.config.sort == "NAME" then
        table.sort(results, function(left, right)
            return (left.name or "") < (right.name or "")
        end)
    end

    return results
end

addon.AuraData = AuraData
