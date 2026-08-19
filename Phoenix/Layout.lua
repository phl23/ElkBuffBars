local _, addon = ...

addon.Layout = addon.Layout or {}

local Layout = addon.Layout

local function utf8Prefix(text, characterCount)
    local index = 1
    local length = #text
    for _ = 1, characterCount do
        if index > length then
            return text
        end

        local byte = string.byte(text, index)
        if byte < 0x80 then
            index = index + 1
        elseif byte < 0xE0 then
            index = index + 2
        elseif byte < 0xF0 then
            index = index + 3
        else
            index = index + 4
        end
    end
    return string.sub(text, 1, index - 1)
end

local function utf8Length(text)
    local index = 1
    local count = 0
    while index <= #text do
        local byte = string.byte(text, index)
        if byte < 0x80 then
            index = index + 1
        elseif byte < 0xE0 then
            index = index + 2
        elseif byte < 0xF0 then
            index = index + 3
        else
            index = index + 4
        end
        count = count + 1
    end
    return count
end

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
    bar:RegisterForClicks("LeftButtonUp")
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
        bar.text:SetWordWrap(false)
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
    end

    if not bar.borders then
        bar.borders = {}
        for _, side in ipairs({ "top", "bottom", "left", "right" }) do
            bar.borders[side] = bar:CreateTexture(nil, "OVERLAY")
        end
    end

    self:ApplyBarStyle(bar)

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

    if not bar.secureCancelButton then
        local secureButton = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
        secureButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        secureButton:SetPoint("TOPLEFT", bar, "TOPLEFT")
        secureButton:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
        secureButton:SetFrameStrata("HIGH")
        secureButton:SetFrameLevel(bar:GetFrameLevel() + 1)
        secureButton:Hide()
        secureButton:SetScript("OnEnter", function()
            local onEnter = bar:GetScript("OnEnter")
            if onEnter then
                onEnter(bar)
            end
        end)
        secureButton:SetScript("OnLeave", function()
            local onLeave = bar:GetScript("OnLeave")
            if onLeave then
                onLeave(bar)
            end
        end)
        bar.secureCancelButton = secureButton
    end

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
    if not InCombatLockdown() then
        local secureButton = bar.secureCancelButton
        secureButton:SetAttribute("unit", nil)
        secureButton:SetAttribute("*type2", nil)
        secureButton:SetAttribute("*index2", nil)
        secureButton:SetAttribute("*target-slot2", nil)
        secureButton:Hide()
    end
    table.insert(group.barPool, bar)
end

function Layout:RefreshGroup(group, auraList)
    if not group or not group.frame then
        return
    end

    local visibleAuras = auraList or {}
    local bars = group.bars
    local spacing = addon.db and addon.db.profile and addon.db.profile.barSpacing or 4
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
                bar:SetPoint("BOTTOMLEFT", bars[index - 1], "TOPLEFT", 0, spacing)
            else
                bar:SetPoint("TOPLEFT", bars[index - 1], "BOTTOMLEFT", 0, -spacing)
            end
        end
        bar:SetSize(group.width, group.height)
        self:UpdateBarLayout(bar)
        bar:Show()
    end

    group.frame:SetHeight(math.max(group.height, (visibleCount * group.height) + math.max(0, visibleCount - 1) * spacing))
end

function Layout:UpdateBarLayout(bar)
    if not bar.icon or not bar.text or not bar.duration then
        return
    end

    local style = addon.Media:GetBarStyle()
    local iconInset = style.iconInset or 4
    local iconSize = math.max(12, math.min(24, bar:GetHeight() - (iconInset * 2)))
    bar.icon:SetSize(iconSize, iconSize)
    bar.icon:ClearAllPoints()
    bar.icon:SetPoint("LEFT", bar.fill, "LEFT", iconInset, 0)

    bar.duration:ClearAllPoints()
    bar.duration:SetPoint("RIGHT", bar.fill, "RIGHT", -(iconInset + 2), 0)
    bar.text:ClearAllPoints()
    bar.text:SetPoint("LEFT", bar.icon, "RIGHT", iconInset + 2, 0)
    bar.text:SetPoint("RIGHT", bar.duration, "LEFT", -8, 0)
end

local function blendColor(base, tint, amount)
    return {
        base[1] + (tint[1] - base[1]) * amount,
        base[2] + (tint[2] - base[2]) * amount,
        base[3] + (tint[3] - base[3]) * amount,
        base[4],
    }
end

local debuffTypePalette = {
    magic = { 0.2, 0.58, 1.0 },
    curse = { 0.62, 0.38, 0.95 },
    disease = { 0.78, 0.7, 0.12 },
    poison = { 0.12, 0.78, 0.24 },
}

local function getDebuffColor(aura, style)
    if addon.db and addon.db.profile and addon.db.profile.colorDebuffsByType and aura.debuffType then
        local typeName = string.lower(tostring(aura.debuffType))
        local color = debuffTypePalette[typeName]
        if color then
            return { color[1], color[2], color[3], style.debuff[4] }
        end
    end
    return style.debuff
end

local function getAuraPalette(style, aura)
    if aura and aura.type == "DEBUFF" then
        local debuff = getDebuffColor(aura, style)
        return {
            background = blendColor(style.background, { debuff[1] * 0.3, debuff[2] * 0.3, debuff[3] * 0.3, 1 }, 0.62),
            border = blendColor(style.border, { debuff[1], debuff[2], debuff[3], 1 }, 0.72),
            text = blendColor(style.text, { 1, debuff[2] * 0.65 + 0.35, debuff[3] * 0.65 + 0.35, 1 }, 0.46),
            duration = blendColor(style.duration, { debuff[1], debuff[2] * 0.7 + 0.3, debuff[3] * 0.7 + 0.3, 1 }, 0.6),
        }
    end

    if aura and aura.type == "WEAPON" then
        return {
            background = blendColor(style.background, { 0.28, 0.06, 0.48, 1 }, 0.72),
            border = blendColor(style.border, { 0.7, 0.34, 1, 1 }, 0.76),
            text = blendColor(style.text, { 0.92, 0.78, 1, 1 }, 0.48),
            duration = blendColor(style.duration, { 0.82, 0.58, 1, 1 }, 0.64),
        }
    end

    return {
        background = blendColor(style.background, { 0.015, 0.1, 0.25, 1 }, 0.52),
        border = blendColor(style.border, { 0.14, 0.68, 1, 1 }, 0.58),
        text = blendColor(style.text, { 0.74, 0.92, 1, 1 }, 0.38),
        duration = blendColor(style.duration, { 0.4, 0.82, 1, 1 }, 0.54),
    }
end

function Layout:ApplyBarStyle(bar, aura)
    local style = addon.Media:GetBarStyle()
    local borderSize = style.borderSize or 1
    local palette = getAuraPalette(style, aura)
    local background = palette.background
    local border = palette.border

    bar.fill:ClearAllPoints()
    bar.fill:SetPoint("TOPLEFT", bar, "TOPLEFT", borderSize, -borderSize)
    bar.fill:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -borderSize, borderSize)
    bar.fill:SetStatusBarTexture(addon.Media:GetBarStyleTexture(style))
    bar.background:SetColorTexture(background[1], background[2], background[3], background[4])

    local borders = bar.borders
    borders.top:ClearAllPoints()
    borders.top:SetPoint("TOPLEFT", bar, "TOPLEFT")
    borders.top:SetPoint("TOPRIGHT", bar, "TOPRIGHT")
    borders.top:SetHeight(borderSize)
    borders.bottom:ClearAllPoints()
    borders.bottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    borders.bottom:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    borders.bottom:SetHeight(borderSize)
    borders.left:ClearAllPoints()
    borders.left:SetPoint("TOPLEFT", bar, "TOPLEFT")
    borders.left:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    borders.left:SetWidth(borderSize)
    borders.right:ClearAllPoints()
    borders.right:SetPoint("TOPRIGHT", bar, "TOPRIGHT")
    borders.right:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    borders.right:SetWidth(borderSize)
    for _, edge in pairs(borders) do
        edge:SetColorTexture(border[1], border[2], border[3], border[4])
    end

    bar.text:SetTextColor(palette.text[1], palette.text[2], palette.text[3], palette.text[4])
    bar.duration:SetTextColor(palette.duration[1], palette.duration[2], palette.duration[3], palette.duration[4])
    self:UpdateBarLayout(bar)
end

function Layout:UpdateChainedAnchors()
    local spacing = addon.db and addon.db.profile and addon.db.profile.barSpacing or 4
    for _, group in pairs(addon.state.groups) do
        local parentId = group.config.anchorTo
        local parent = parentId and addon.state.groups[parentId]
        if parent and parent ~= group and parent.frame then
            local parentBars = parent.bars
            local terminalBar = parentBars[#parentBars]
            group.frame:ClearAllPoints()

            if parent.grow == "UP" then
                local anchorFrame = terminalBar or parent.frame
                group.frame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, group.height + spacing)
            else
                local anchorFrame = terminalBar or parent.frame
                group.frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -spacing)
            end
        end
    end
end

function Layout:ApplyAuraToBar(bar, aura)
    if not bar or not aura then
        return
    end

    if not InCombatLockdown() then
        local secureButton = bar.secureCancelButton
        if not aura.isDummy and aura.unit == "player" and aura.weaponSlot then
            secureButton:SetAttribute("unit", "player")
            secureButton:SetAttribute("*type2", "cancelaura")
            secureButton:SetAttribute("*index2", nil)
            secureButton:SetAttribute("*target-slot2", aura.weaponSlot)
            secureButton:Show()
        elseif not aura.isDummy and aura.unit == "player" and aura.isHelpful and aura.index then
            secureButton:SetAttribute("unit", "player")
            secureButton:SetAttribute("*type2", "cancelaura")
            secureButton:SetAttribute("*index2", aura.index)
            secureButton:SetAttribute("*target-slot2", nil)
            secureButton:Show()
        else
            secureButton:SetAttribute("unit", nil)
            secureButton:SetAttribute("*type2", nil)
            secureButton:SetAttribute("*index2", nil)
            secureButton:SetAttribute("*target-slot2", nil)
            secureButton:Hide()
        end
    end

    self:ApplyBarFont(bar)
    self:ApplyBarStyle(bar, aura)

    if bar.group.icon and aura.icon then
        bar.icon:SetTexture(aura.icon)
        bar.icon:Show()
    else
        bar.icon:Hide()
    end

    if bar.group.text then
        local stackText = aura.charges and aura.charges > 1 and " (" .. aura.charges .. ")" or ""
        bar.text.fullName = (aura.name or "") .. stackText
        bar.text:Show()
    else
        bar.text.fullName = ""
        bar.text:SetText("")
        bar.text:Hide()
    end
    bar.aura = aura
    self:UpdateBarDuration(bar)
    self:UpdateAuraName(bar)

    if aura.isDummy then
        local style = addon.Media:GetBarStyle()
        bar.fill:SetStatusBarTexture(addon.Media:GetBarStyleTexture(addon.Media:GetBarStyle()))
        if aura.type == "DEBUFF" then
            local debuff = getDebuffColor(aura, style)
            bar.fill:SetStatusBarColor(debuff[1], debuff[2], debuff[3], debuff[4])
        else
            bar.fill:SetStatusBarColor(style.buff[1], style.buff[2], style.buff[3], style.buff[4])
        end
        bar.duration:SetText("")
        bar.fill:SetValue(1)
        return
    end

    local style = addon.Media:GetBarStyle()
    bar.fill:SetStatusBarTexture(addon.Media:GetBarStyleTexture(style))
    if aura.type == "DEBUFF" then
        local debuff = getDebuffColor(aura, style)
        bar.fill:SetStatusBarColor(debuff[1], debuff[2], debuff[3], debuff[4])
    elseif aura.type == "WEAPON" then
        bar.fill:SetStatusBarColor(0.58, 0.26, 0.9, style.buff[4])
    else
        bar.fill:SetStatusBarColor(style.buff[1], style.buff[2], style.buff[3], style.buff[4])
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

function Layout:UpdateAuraName(bar)
    if not bar.text or not bar.text:IsShown() then
        return
    end

    local fullName = bar.text.fullName or ""
    local style = addon.Media:GetBarStyle()
    local iconInset = style.iconInset or 4
    local leftWidth = iconInset + bar.icon:GetWidth() + iconInset + 2
    local rightWidth = iconInset + 2 + bar.duration:GetStringWidth()
    local availableWidth = math.max(20, bar:GetWidth() - leftWidth - rightWidth - 8)
    bar.text:SetText(fullName)
    if bar.text:GetStringWidth() <= availableWidth then
        return
    end

    local characterCount = utf8Length(fullName)
    local low = 0
    local high = characterCount
    while low < high do
        local middle = math.ceil((low + high) / 2)
        bar.text:SetText(utf8Prefix(fullName, middle) .. "...")
        if bar.text:GetStringWidth() <= availableWidth then
            low = middle
        else
            high = middle - 1
        end
    end
    bar.text:SetText(utf8Prefix(fullName, low) .. "...")
end

local function formatRemainingTime(seconds)
    local remaining = math.max(0, math.floor(seconds))
    local minutes = math.floor(remaining / 60) % 60
    local hours = math.floor(remaining / 3600)
    local secondsPart = remaining % 60

    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end
    if minutes > 0 then
        return string.format("%dm %ds", minutes, secondsPart)
    end
    return string.format("%ds", secondsPart)
end

function Layout:UpdateBarDuration(bar)
    local aura = bar.aura
    if not aura then
        return
    end

    if not aura.duration or aura.duration <= 0 or not aura.expiresAt or aura.expiresAt <= 0 then
        bar.duration:SetText("")
        bar.fill:SetValue(1)
        self:UpdateAuraName(bar)
        return
    end

    local remaining = math.max(0, aura.expiresAt - GetTime())
    if remaining <= 0 then
        bar.duration:SetText("")
        bar.fill:SetValue(0)
        self:UpdateAuraName(bar)
        return
    end

    bar.duration:SetText(formatRemainingTime(remaining))
    bar.fill:SetValue(remaining / aura.duration)
    self:UpdateAuraName(bar)
end

addon.Layout = Layout
