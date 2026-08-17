local _, addon = ...

addon.Main = addon.Main or {}

local Main = addon.Main

function Main:RefreshGroup(group)
    if not group then
        return
    end

    local auraList = addon.AuraData:CollectForGroup(group)
    addon.Renderer:RefreshGroup(group, auraList)
end

function Main:RefreshAll()
    if not addon.state or not addon.state.config or not addon.state.config.groups then
        return
    end

    for _, groupConfig in ipairs(addon.state.config.groups) do
        local actualGroup = addon.state.groups[groupConfig.id]
        if actualGroup then
            self:RefreshGroup(actualGroup)
        end
    end
end

function Main:RefreshUnit(unitToken)
    if not unitToken then
        return
    end

    for _, group in pairs(addon.state.groups) do
        if group and group.unit == unitToken then
            self:RefreshGroup(group)
        end
    end
end

addon.Main = Main

if addon.frame then
    addon.frame:RegisterEvent("PLAYER_LOGIN")
end
