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

    if addon.db and addon.db.profile and not addon.db.profile.locked and #list < 2 then
        local editList = {}
        for index, aura in ipairs(list) do
            editList[index] = aura
        end

        while #editList < 2 do
            table.insert(editList, {
                name = "Move " .. group.name,
                type = group.filter == "HARMFUL" and "DEBUFF" or "BUFF",
                icon = "Interface\\Icons\\INV_Misc_QuestionMark",
                isDummy = true,
            })
        end
        list = editList
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
