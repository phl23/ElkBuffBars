local _, addon = ...

addon.Renderer = addon.Renderer or {}

local Renderer = addon.Renderer

function Renderer:RefreshGroup(group, auraList)
    if not group or not group.frame then
        return
    end

    local list = auraList or {}
    if group.visible == false then
        group.frame:Hide()
        return
    end

    group.frame:Show()
    addon.Layout:RefreshGroup(group, list)
end

function Renderer:RefreshAll()
    for _, group in pairs(addon.state.groups) do
        if group then
            self:RefreshGroup(group, addon.AuraData:CollectForGroup(group))
        end
    end
end

addon.Renderer = Renderer
