local _, addon = ...

addon.Layout = addon.Layout or {}

local Layout = addon.Layout

function Layout:CreateGroup(groupConfig)
    local group = {
        id = groupConfig.id,
        name = groupConfig.name,
        unit = groupConfig.unit,
        filter = groupConfig.filter,
        width = groupConfig.width or 220,
        height = groupConfig.height or 18,
        icon = groupConfig.icon ~= false,
        text = groupConfig.text ~= false,
        anchor = groupConfig.anchor,
        grow = groupConfig.grow or "RIGHT",
        bars = {},
        frame = CreateFrame("Frame", nil, UIParent),
    }

    group.frame:SetSize(group.width, 200)
    group.frame:SetPoint(unpack(group.anchor))
    group.frame:Show()

    return group
end

function Layout:RefreshGroup(group, auraList)
    if not group then
        return
    end

    local frame = group.frame
    local bars = group.bars

    for index = #bars + 1, #auraList do
        local bar = self:CreateBar(frame, index)
        table.insert(bars, bar)
    end

    for index = #auraList + 1, #bars do
        bars[index]:Hide()
    end

    for index, aura in ipairs(auraList) do
        local bar = bars[index]
        if bar then
            self:ApplyAuraToBar(bar, aura)
            bar:ClearAllPoints()
            if index == 1 then
                bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            else
                if group.grow == "RIGHT" then
                    bar:SetPoint("TOPLEFT", bars[index - 1], "TOPRIGHT", 4, 0)
                else
                    bar:SetPoint("TOPLEFT", bars[index - 1], "BOTTOMLEFT", 0, -4)
                end
            end
            bar:Show()
        end
    end
end

function Layout:CreateBar(parent, index)
    local bar = CreateFrame("Button", nil, parent)
    bar:SetSize(parent:GetWidth(), parent:GetHeight())
    bar:SetFrameLevel(parent:GetFrameLevel() + 5)

    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.icon = icon

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetJustifyH("LEFT")
    bar.text = text

    local duration = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    duration:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    duration:SetJustifyH("RIGHT")
    bar.duration = duration

    local fill = bar:CreateTexture(nil, "BACKGROUND")
    fill:SetColorTexture(0.2, 0.6, 1.0, 0.7)
    fill:SetAllPoints(bar)
    fill:SetDrawLayer("BACKGROUND", 1)
    bar.fill = fill

    return bar
end

function Layout:ApplyAuraToBar(bar, aura)
    if not bar then
        return
    end

    if aura.icon then
        bar.icon:SetTexture(aura.icon)
        bar.icon:Show()
    else
        bar.icon:Hide()
    end

    bar.text:SetText(aura.name or "")
    bar.duration:SetText(aura.remaining and string.format("%.0f", aura.remaining) or "")

    local r, g, b = addon.Compat:GetDebuffColor(aura.debuffType)
    if aura.type == "DEBUFF" then
        bar.fill:SetColorTexture(r, g, b, 0.75)
    else
        bar.fill:SetColorTexture(0.2, 0.6, 1.0, 0.7)
    end
end

addon.Layout = Layout
