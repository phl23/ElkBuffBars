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
        maxBars = groupConfig.maxBars,
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
            group.config.anchorTo = nil
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

    if not bar.fill then
        bar.fill = CreateFrame("StatusBar", nil, bar)
        bar.fill:SetAllPoints(bar)
        bar.fill:SetFrameLevel(bar:GetFrameLevel())
        bar.fill:SetMinMaxValues(0, 1)
        bar.fill:SetValue(1)
        bar.fill:SetStatusBarTexture(addon.Media:GetBarTexture())
    end

    if not bar.icon then
        bar.icon = bar.fill:CreateTexture(nil, "OVERLAY")
    end

    if not bar.text then
        bar.text = bar.fill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bar.text:SetJustifyH("LEFT")
    end

    if not bar.duration then
        bar.duration = bar.fill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bar.duration:SetJustifyH("RIGHT")
    end

    self:UpdateBarLayout(bar)
    self:ApplyBarFont(bar)

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
        if not aura or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(currentBar, "ANCHOR_RIGHT")
        if aura.isDummy then
            GameTooltip:SetText(currentBar.group.name)
            GameTooltip:AddLine("Drag to move this group", 1, 1, 1)
            GameTooltip:AddLine("Shift+Click to lock again", 1, 0.82, 0)
        elseif aura.index and GameTooltip.SetUnitAura then
            GameTooltip:SetUnitAura(currentBar.group.unit, aura.index, currentBar.group.filter)
            if addon.db and addon.db.profile and not addon.db.profile.locked then
                GameTooltip:AddLine("Shift+Click to lock again", 1, 0.82, 0)
            end
        else
            return
        end
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    bar:SetScript("OnMouseDown", function(currentBar, button)
        if button ~= "LeftButton" or IsShiftKeyDown() then
            return
        end

        if addon.db and addon.db.profile and not addon.db.profile.locked then
            currentBar.group.config.anchorTo = nil
            currentBar.group.frame:StartMoving()
            currentBar.draggingGroup = true
        end
    end)
    bar:SetScript("OnMouseUp", function(currentBar)
        if not currentBar.draggingGroup then
            return
        end

        currentBar.group.frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = currentBar.group.frame:GetPoint(1)
        currentBar.group.config.anchor = { point, nil, relativePoint, x, y }
        currentBar.draggingGroup = false
    end)
    bar:SetScript("OnClick", function(_, button)
        if button == "LeftButton" and IsShiftKeyDown() then
            addon:SetBarsLocked(true)
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
    local visibleCount = group.maxBars and math.min(#visibleAuras, group.maxBars) or #visibleAuras

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
        self:UpdateBarLayout(bar)
        bar:Show()
    end

    group.frame:SetHeight(math.max(group.height, (visibleCount * group.height) + math.max(0, visibleCount - 1) * 4))
end

function Layout:UpdateBarLayout(bar)
    if not bar.icon or not bar.text or not bar.duration then
        return
    end

    local iconSize = math.max(12, math.min(24, bar:GetHeight() - 4))
    bar.icon:SetSize(iconSize, iconSize)
    bar.icon:ClearAllPoints()
    bar.icon:SetPoint("LEFT", bar.fill, "LEFT", 4, 0)

    bar.duration:ClearAllPoints()
    bar.duration:SetPoint("RIGHT", bar.fill, "RIGHT", -6, 0)
    bar.text:ClearAllPoints()
    bar.text:SetPoint("LEFT", bar.icon, "RIGHT", 6, 0)
    bar.text:SetPoint("RIGHT", bar.duration, "LEFT", -8, 0)
end

function Layout:UpdateChainedAnchors()
    for _, group in pairs(addon.state.groups) do
        local parentId = group.config.anchorTo
        local parent = parentId and addon.state.groups[parentId]
        if parent and parent ~= group and parent.frame then
            local parentBars = parent.bars
            local terminalBar = parentBars[#parentBars]
            group.frame:ClearAllPoints()

            if parent.grow == "UP" then
                local anchorFrame = terminalBar or parent.frame
                group.frame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, group.height + 4)
            else
                local anchorFrame = terminalBar or parent.frame
                group.frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
            end
        end
    end
end

function Layout:ApplyAuraToBar(bar, aura)
    if not bar or not aura then
        return
    end

    self:ApplyBarFont(bar)

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

    if aura.isDummy then
        bar.fill:SetStatusBarTexture(addon.Media:GetBarTexture())
        bar.fill:SetStatusBarColor(0.75, 0.55, 0.08, 0.8)
        bar.duration:SetText("")
        bar.fill:SetValue(1)
        return
    end

    local r, g, b = addon.Compat:GetDebuffColor(aura.debuffType)
    bar.fill:SetStatusBarTexture(addon.Media:GetBarTexture())
    if aura.type == "DEBUFF" then
        bar.fill:SetStatusBarColor(r, g, b, 0.75)
    else
        bar.fill:SetStatusBarColor(0.2, 0.6, 1.0, 0.7)
    end
end

function Layout:ApplyBarFont(bar)
    if not bar.text or not bar.duration then
        return
    end

    local fontPath = addon.Media:GetBarFont()
    bar.text:SetFont(fontPath, 11, "")
    bar.duration:SetFont(fontPath, 11, "")

    if addon.db and addon.db.profile and addon.db.profile.fontShadow ~= false then
        bar.text:SetShadowColor(0, 0, 0, 1)
        bar.duration:SetShadowColor(0, 0, 0, 1)
        bar.text:SetShadowOffset(1, -1)
        bar.duration:SetShadowOffset(1, -1)
    else
        bar.text:SetShadowOffset(0, 0)
        bar.duration:SetShadowOffset(0, 0)
    end
end

function Layout:UpdateBarDuration(bar)
    local aura = bar.aura
    if not aura then
        return
    end

    if not aura.duration or aura.duration <= 0 or not aura.expiresAt or aura.expiresAt <= 0 then
        bar.duration:SetText("")
        bar.fill:SetValue(1)
        return
    end

    local remaining = math.max(0, aura.expiresAt - GetTime())
    if remaining <= 0 then
        bar.duration:SetText("")
        bar.fill:SetValue(0)
        return
    end

    bar.duration:SetText(string.format("%.0f", remaining))
    bar.fill:SetValue(remaining / aura.duration)
end

addon.Layout = Layout
