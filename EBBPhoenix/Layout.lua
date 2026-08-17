local _, addon = ...

addon.Layout = addon.Layout or {}

local Layout = addon.Layout

function Layout:CreateGroup(groupConfig)
    local group = {
        id = groupConfig.id,
        name = groupConfig.name,
        unit = groupConfig.unit,
        filter = groupConfig.filter or "HELPFUL",
        width = groupConfig.width or 220,
        height = groupConfig.height or 18,
        icon = groupConfig.icon ~= false,
        text = groupConfig.text ~= false,
        anchor = groupConfig.anchor or { "TOPLEFT", UIParent, "TOPLEFT", 20, -60 },
        grow = groupConfig.grow or "DOWN",
        visible = groupConfig.enabled ~= false,
        maxBars = groupConfig.maxBars or 16,
        config = groupConfig,
        bars = {},
        frame = CreateFrame("Frame", nil, UIParent),
        barPool = {},
    }

    group.frame:SetSize(group.width, group.height)
    group.frame:SetFrameStrata("HIGH")
    group.frame:SetFrameLevel(50)

    local anchor = group.anchor or { "TOPLEFT", nil, "TOPLEFT", 0, 0 }
    local anchorPoint = anchor[1] or "TOPLEFT"
    local anchorParent = UIParent
    local relativePoint = anchor[3] or anchorPoint
    local offsetX = anchor[4] or 0
    local offsetY = anchor[5] or 0

    group.frame:SetPoint(anchorPoint, anchorParent, relativePoint, offsetX, offsetY)
    group.frame:SetMovable(true)
    group.frame:EnableMouse(true)
    group.frame:RegisterForDrag("LeftButton")
    group.frame:SetScript("OnDragStart", function(frame)
        if addon.db and addon.db.profile and not addon.db.profile.locked then
            frame:StartMoving()
        end
    end)
    group.frame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        group.config.anchor = { point, nil, relativePoint, x, y }
    end)

    group.frame:Show()
    return group
end

function Layout:CreateBar(parent)
    local bar = table.remove(parent.barPool) or CreateFrame("Button", nil, parent.frame)
    bar.group = parent
    bar:SetSize(parent.width, parent.height)
    bar:SetFrameStrata("HIGH")
    bar:SetFrameLevel(parent.frame:GetFrameLevel() + 10)
    bar:ClearAllPoints()
    bar:Show()

    if not bar.icon then
        bar.icon = bar:CreateTexture(nil, "ARTWORK")
        bar.icon:SetSize(16, 16)
        bar.icon:SetPoint("LEFT", bar, "LEFT", 2, 0)
    end

    if not bar.text then
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bar.text:SetPoint("LEFT", bar.icon, "RIGHT", 4, 0)
        bar.text:SetJustifyH("LEFT")
    end

    if not bar.duration then
        bar.duration = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bar.duration:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
        bar.duration:SetJustifyH("RIGHT")
        bar.text:SetPoint("RIGHT", bar.duration, "LEFT", -6, 0)
    end

    if not bar.fill then
        bar.fill = bar:CreateTexture(nil, "BACKGROUND")
        bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        bar.fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        bar.fill:SetDrawLayer("BACKGROUND", 1)
    end

    if not bar.background then
        bar.background = bar:CreateTexture(nil, "BACKGROUND")
        bar.background:SetAllPoints(bar)
        bar.background:SetColorTexture(0, 0, 0, 0.7)
    end

    bar:SetScript("OnUpdate", function(currentBar)
        if currentBar.aura then
            Layout:UpdateBarDuration(currentBar)
        end
    end)
    bar:SetScript("OnEnter", function(currentBar)
        local aura = currentBar.aura
        if not aura or not aura.index or not GameTooltip or not GameTooltip.SetUnitAura then
            return
        end

        GameTooltip:SetOwner(currentBar, "ANCHOR_RIGHT")
        GameTooltip:SetUnitAura(currentBar.group.unit, aura.index, currentBar.group.filter)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return bar
end

function Layout:RecycleBar(group, bar)
    if not bar then
        return
    end

    bar:Hide()
    bar.text:SetText("")
    bar.duration:SetText("")
    bar.icon:SetTexture("")
    bar.aura = nil
    table.insert(group.barPool, bar)
end

function Layout:RefreshGroup(group, auraList)
    if not group or not group.frame then
        return
    end

    local visibleAuras = auraList or {}
    local bars = group.bars
    local visibleCount = math.min(#visibleAuras, group.maxBars)

    for index = #bars + 1, visibleCount do
        local bar = self:CreateBar(group)
        table.insert(bars, bar)
    end

    for index = visibleCount + 1, #bars do
        self:RecycleBar(group, bars[index])
        bars[index] = nil
    end

    for index = 1, visibleCount do
        local aura = visibleAuras[index]
        local bar = bars[index]
        if not bar then
            bar = self:CreateBar(group)
            bars[index] = bar
        end

        self:ApplyAuraToBar(bar, aura)
        bar:ClearAllPoints()
        if index == 1 then
            bar:SetPoint("TOPLEFT", group.frame, "TOPLEFT", 0, 0)
        else
            if group.grow == "UP" then
                bar:SetPoint("BOTTOMLEFT", bars[index - 1], "TOPLEFT", 0, 4)
            else
                bar:SetPoint("TOPLEFT", bars[index - 1], "BOTTOMLEFT", 0, -4)
            end
        end
        bar:SetSize(group.width, group.height)
        bar:Show()
    end

    group.frame:SetHeight(math.max(group.height, (visibleCount * group.height) + math.max(0, visibleCount - 1) * 4))
end

function Layout:ApplyAuraToBar(bar, aura)
    if not bar or not aura then
        return
    end

    if bar.group.icon and aura.icon then
        bar.icon:SetTexture(aura.icon)
        bar.icon:Show()
    else
        bar.icon:Hide()
    end

    if bar.group.text then
        local stackText = aura.charges and aura.charges > 1 and " (" .. aura.charges .. ")" or ""
        bar.text:SetText((aura.name or "") .. stackText)
        bar.text:Show()
    else
        bar.text:SetText("")
        bar.text:Hide()
    end
    bar.aura = aura
    self:UpdateBarDuration(bar)

    local r, g, b = addon.Compat:GetDebuffColor(aura.debuffType)
    if aura.type == "DEBUFF" then
        bar.fill:SetColorTexture(r, g, b, 0.75)
    else
        bar.fill:SetColorTexture(0.2, 0.6, 1.0, 0.7)
    end
end

function Layout:UpdateBarDuration(bar)
    local aura = bar.aura
    if not aura then
        return
    end

    if not aura.duration or aura.duration <= 0 or not aura.expiresAt or aura.expiresAt <= 0 then
        bar.duration:SetText("")
        bar.fill:SetWidth(bar:GetWidth())
        return
    end

    local remaining = math.max(0, aura.expiresAt - GetTime())
    if remaining <= 0 then
        bar.duration:SetText("")
        return
    end

    bar.duration:SetText(string.format("%.0f", remaining))
    bar.fill:SetWidth(math.max(1, bar:GetWidth() * (remaining / aura.duration)))
end

addon.Layout = Layout
