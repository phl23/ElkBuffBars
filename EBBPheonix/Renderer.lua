local _, addon = ...

addon.Renderer = addon.Renderer or {}

local Renderer = addon.Renderer

function Renderer:RefreshGroup(group, auraList)
    if not group or not group.frame then
        return
    end

    self:UpdateFrameSize(group, #auraList)
    addon.Layout:RefreshGroup(group, auraList)
end

function Renderer:UpdateFrameSize(group, count)
    local height = (group.height or 18) * math.max(1, count)
    group.frame:SetHeight(height)
end

addon.Renderer = Renderer
