local _, addon = ...

addon.Options = addon.Options or {}

local Options = addon.Options

local colors = {
    heading = { 0.82, 0.9, 1.0 },
    label = { 0.72, 0.72, 0.72 },
    value = { 0.38, 0.84, 1.0 },
    enabled = { 0.24, 0.82, 0.42 },
    muted = { 0.58, 0.58, 0.58 },
    divider = { 0.2, 0.35, 0.45 },
}

local function createSettingsPanel()
    local panel = CreateFrame("Frame", "EBBPhoenixSettingsCategory", UIParent)
    panel:SetSize(520, 180)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EBB Phoenix")

    local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    openButton:SetSize(200, 26)
    openButton:SetText("Open EBB Phoenix")
    openButton:SetScript("OnClick", function()
        addon.Options:Open()
    end)

    return panel
end

local function createCheckbox(parent, label, getter, setter, anchor, relativeTo)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(20, 20)
    button:SetPoint(anchor, relativeTo, anchor, 0, 0)

    local box = button:CreateTexture(nil, "ARTWORK")
    box:SetAllPoints(button)
    box:SetColorTexture(0.08, 0.08, 0.08, 0.95)
    button.box = box

    local mark = button:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    mark:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    mark:SetColorTexture(unpack(colors.enabled))
    button.mark = mark

    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", button, "RIGHT", 8, 0)
    text:SetText(label)
    text:SetTextColor(unpack(colors.label))

    function button:Refresh()
        if getter() then
            mark:Show()
        else
            mark:Hide()
        end
    end

    button:SetScript("OnClick", function()
        setter(not getter())
        button:Refresh()
    end)
    button:Refresh()
    return button
end

local function createStepper(parent, label, getter, setter, anchor, relativeTo, offsetY)
    local caption = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    caption:SetPoint(anchor, relativeTo, anchor, 0, offsetY or 0)
    caption:SetText(label)
    caption:SetTextColor(unpack(colors.label))

    local value = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    value:SetPoint("LEFT", caption, "RIGHT", 12, 0)
    value:SetTextColor(unpack(colors.value))

    local decrease = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    decrease:SetText("-")
    decrease:SetPoint("LEFT", value, "RIGHT", 10, 0)
    decrease:SetSize(24, 20)

    local increase = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    increase:SetText("+")
    increase:SetPoint("LEFT", decrease, "RIGHT", 4, 0)
    increase:SetSize(24, 20)

    local control = {}
    control.caption = caption
    control.value = value
    control.decrease = decrease
    control.increase = increase
    function control:Refresh()
        value:SetText(tostring(getter()))
    end

    decrease:SetScript("OnClick", function()
        setter(getter() - 1)
        control:Refresh()
    end)
    increase:SetScript("OnClick", function()
        setter(getter() + 1)
        control:Refresh()
    end)
    control:Refresh()
    function control:SetShown(shown)
        if shown then
            caption:Show()
            value:Show()
            decrease:Show()
            increase:Show()
        else
            caption:Hide()
            value:Hide()
            decrease:Hide()
            increase:Hide()
        end
    end
    return control
end

local function createProfileNameInput(parent)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(164, 24)
    input:SetAutoFocus(false)
    input:SetMaxLetters(40)
    return input
end

local function buildPanel()
    local panel = CreateFrame("Frame", "EBBPhoenixOptionsPanel", UIParent)
    panel:SetWidth(760)
    panel:SetHeight(560)
    UISpecialFrames = UISpecialFrames or {}
    table.insert(UISpecialFrames, "EBBPhoenixOptionsPanel")
    panel.name = "EBB Phoenix"
    panel:SetFrameStrata("DIALOG")
    panel:Hide()
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetColorTexture(0.03, 0.03, 0.03, 0.96)

    local border = panel:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    border:SetColorTexture(unpack(colors.divider))

    local inner = panel:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    inner:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    inner:SetColorTexture(0.03, 0.03, 0.03, 0.96)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EBB Phoenix")
    title:SetTextColor(1, 0.82, 0.2)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Modern buff and debuff bar groups")
    subtitle:SetTextColor(unpack(colors.muted))

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -32, 16)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(710, 720)
    scrollFrame:SetScrollChild(content)

    local generalColumn = CreateFrame("Frame", nil, content)
    generalColumn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    generalColumn:SetSize(340, 680)

    local groupColumn = CreateFrame("Frame", nil, content)
    groupColumn:SetPoint("TOPLEFT", generalColumn, "TOPRIGHT", 22, 0)
    groupColumn:SetSize(340, 680)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", generalColumn, "TOPRIGHT", 10, 0)
    divider:SetPoint("BOTTOMLEFT", generalColumn, "BOTTOMRIGHT", 10, 0)
    divider:SetWidth(1)
    divider:SetColorTexture(unpack(colors.divider))

    local generalTitle = generalColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    generalTitle:SetPoint("TOPLEFT", 0, 0)
    generalTitle:SetText("General")
    generalTitle:SetTextColor(unpack(colors.heading))

    local refreshButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    refreshButton:SetText("Refresh")
    refreshButton:SetPoint("TOPLEFT", generalTitle, "BOTTOMLEFT", 0, -12)
    refreshButton:SetSize(120, 24)
    refreshButton:SetScript("OnClick", function()
        addon:RefreshAll()
    end)

    local globalControls = {}
    local function placeBelow(control, previous, gap)
        control:ClearAllPoints()
        control:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -(gap or 8))
    end

    local minimapToggle = createCheckbox(generalColumn, "Show minimap button", function()
        return not addon.db.profile.minimap.hide
    end, function(value)
        addon.db.profile.minimap.hide = not value
        addon.Minimap:Refresh()
    end, "TOPLEFT", refreshButton)
    placeBelow(minimapToggle, refreshButton, 16)
    table.insert(globalControls, minimapToggle)

    local previewToggle = createCheckbox(generalColumn, "Show preview bars", function()
        return addon.db.profile.locked ~= true
    end, function(value)
        addon:SetBarsLocked(not value)
    end, "TOPLEFT", refreshButton)
    placeBelow(previewToggle, minimapToggle, 8)
    table.insert(globalControls, previewToggle)

    local iconsToggle = createCheckbox(generalColumn, "Show icons", function()
        return addon.db.profile.groups[1].icon ~= false
    end, function(value)
        addon:SetAllGroupsField("icon", value)
    end, "TOPLEFT", refreshButton)
    placeBelow(iconsToggle, previewToggle, 8)
    table.insert(globalControls, iconsToggle)

    local namesToggle = createCheckbox(generalColumn, "Show aura names", function()
        return addon.db.profile.groups[1].text ~= false
    end, function(value)
        addon:SetAllGroupsField("text", value)
    end, "TOPLEFT", refreshButton)
    placeBelow(namesToggle, iconsToggle, 8)
    table.insert(globalControls, namesToggle)

    local styleButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    styleButton:SetPoint("TOPLEFT", namesToggle, "BOTTOMLEFT", 0, -14)
    styleButton:SetSize(250, 24)
    function styleButton:Refresh()
        self:SetText("Style: " .. addon.Media:GetBarStyle().name)
    end
    styleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    styleButton:SetScript("OnClick", function(_, button)
        addon.Media:CycleBarStyle(button == "RightButton" and -1 or 1)
        addon:RefreshAll()
        styleButton:Refresh()
    end)
    styleButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Aura bar appearance", 1, 1, 1)
        GameTooltip:AddLine("Click to cycle through 10 presets.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    styleButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    styleButton:Refresh()
    table.insert(globalControls, styleButton)

    local debuffTypeColorsToggle = createCheckbox(generalColumn, "Debuff type colored bars", function()
        return addon.db.profile.colorDebuffsByType == true
    end, function(value)
        addon.db.profile.colorDebuffsByType = value
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    placeBelow(debuffTypeColorsToggle, styleButton, 8)
    table.insert(globalControls, debuffTypeColorsToggle)

    local spacingControl = createStepper(generalColumn, "Bar spacing", function()
        return addon.db.profile.barSpacing or 4
    end, function(value)
        addon:SetBarSpacing(value)
    end, "TOPLEFT", debuffTypeColorsToggle, -26)
    table.insert(globalControls, spacingControl)

    local fontButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    fontButton:SetPoint("TOPLEFT", spacingControl.caption, "BOTTOMLEFT", 0, -12)
    fontButton:SetSize(250, 24)
    function fontButton:Refresh()
        self:SetText("Font: " .. (addon.db.profile.font or addon.Media.defaultFont))
    end
    fontButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    fontButton:SetScript("OnClick", function(_, button)
        local fonts = addon.Media:GetFontNames()
        local currentFont = addon.db.profile.font or addon.Media.defaultFont
        local selectedIndex = 1
        for index, fontName in ipairs(fonts) do
            if fontName == currentFont then
                selectedIndex = index
                break
            end
        end
        local direction = button == "RightButton" and -1 or 1
        local nextIndex = selectedIndex + direction
        if nextIndex < 1 then
            nextIndex = #fonts
        elseif nextIndex > #fonts then
            nextIndex = 1
        end
        addon.db.profile.font = fonts[nextIndex]
        addon:RefreshAll()
        fontButton:Refresh()
    end)
    fontButton:Refresh()
    table.insert(globalControls, fontButton)

    local fontShadowToggle = createCheckbox(generalColumn, "Font shadow", function()
        return addon.db.profile.fontShadow ~= false
    end, function(value)
        addon.db.profile.fontShadow = value
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    placeBelow(fontShadowToggle, fontButton, 8)
    table.insert(globalControls, fontShadowToggle)

    local hideBlizzardBuffsToggle = createCheckbox(generalColumn, "Hide Blizzard buffs", function()
        return addon.db.profile.hideBlizzardBuffs == true
    end, function(value)
        addon.db.profile.hideBlizzardBuffs = value
        addon:ApplyBlizzardAuraVisibility()
    end, "TOPLEFT", refreshButton)
    placeBelow(hideBlizzardBuffsToggle, fontShadowToggle, 8)
    table.insert(globalControls, hideBlizzardBuffsToggle)

    local hideBlizzardDebuffsToggle = createCheckbox(generalColumn, "Hide Blizzard debuffs", function()
        return addon.db.profile.hideBlizzardDebuffs == true
    end, function(value)
        addon.db.profile.hideBlizzardDebuffs = value
        addon:ApplyBlizzardAuraVisibility()
    end, "TOPLEFT", refreshButton)
    placeBelow(hideBlizzardDebuffsToggle, hideBlizzardBuffsToggle, 8)
    table.insert(globalControls, hideBlizzardDebuffsToggle)

    local resetButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    resetButton:SetText("Reset Positions")
    resetButton:SetPoint("TOPLEFT", hideBlizzardDebuffsToggle, "BOTTOMLEFT", 0, -16)
    resetButton:SetSize(120, 24)
    resetButton:SetScript("OnClick", function()
        addon:ResetPositions()
    end)

    local profileTitle = generalColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileTitle:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
    profileTitle:SetText("Profiles")
    profileTitle:SetTextColor(unpack(colors.heading))

    local profileControls = {}
    local profileButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    profileButton:SetPoint("TOPLEFT", profileTitle, "BOTTOMLEFT", 0, -8)
    profileButton:SetSize(250, 24)
    function profileButton:Refresh()
        self:SetText("Profile: " .. addon:GetCurrentProfile())
    end
    profileButton:SetScript("OnClick", function()
        local profiles = addon:GetProfileNames()
        local currentProfile = addon:GetCurrentProfile()
        local currentIndex = 1
        for index, profileName in ipairs(profiles) do
            if profileName == currentProfile then
                currentIndex = index
                break
            end
        end
        local nextIndex = currentIndex + 1
        if nextIndex > #profiles then
            nextIndex = 1
        end
        addon:SetProfile(profiles[nextIndex])
    end)
    table.insert(profileControls, profileButton)

    local newProfileInput = createProfileNameInput(generalColumn)
    newProfileInput:SetPoint("TOPLEFT", profileButton, "BOTTOMLEFT", 4, -10)

    local useProfileButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    useProfileButton:SetPoint("LEFT", newProfileInput, "RIGHT", 8, 0)
    useProfileButton:SetSize(68, 24)
    useProfileButton:SetText("Use")
    local function useEnteredProfile()
        local profileName = string.match(newProfileInput:GetText() or "", "^%s*(.-)%s*$")
        if profileName and profileName ~= "" then
            addon:SetProfile(profileName)
            newProfileInput:SetText("")
            newProfileInput:ClearFocus()
        end
    end
    useProfileButton:SetScript("OnClick", useEnteredProfile)
    newProfileInput:SetScript("OnEnterPressed", useEnteredProfile)

    local copySourceName
    local copySourceButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    copySourceButton:SetPoint("TOPLEFT", newProfileInput, "BOTTOMLEFT", -4, -10)
    copySourceButton:SetSize(160, 24)
    function copySourceButton:Refresh()
        local currentProfile = addon:GetCurrentProfile()
        local profiles = addon:GetProfileNames()
        local sourceExists = false
        for _, profileName in ipairs(profiles) do
            if profileName == copySourceName and profileName ~= currentProfile then
                sourceExists = true
                break
            end
        end
        if not sourceExists then
            copySourceName = nil
            for _, profileName in ipairs(profiles) do
                if profileName ~= currentProfile then
                    copySourceName = profileName
                    break
                end
            end
        end
        self:SetText(copySourceName and "Copy from: " .. copySourceName or "Copy from: None")
    end
    copySourceButton:SetScript("OnClick", function()
        local profiles = addon:GetProfileNames()
        local currentProfile = addon:GetCurrentProfile()
        local candidates = {}
        for _, profileName in ipairs(profiles) do
            if profileName ~= currentProfile then
                table.insert(candidates, profileName)
            end
        end
        if #candidates == 0 then
            return
        end
        local currentIndex = 0
        for index, profileName in ipairs(candidates) do
            if profileName == copySourceName then
                currentIndex = index
                break
            end
        end
        copySourceName = candidates[(currentIndex % #candidates) + 1]
        copySourceButton:Refresh()
    end)
    table.insert(profileControls, copySourceButton)

    local copyProfileButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    copyProfileButton:SetPoint("LEFT", copySourceButton, "RIGHT", 8, 0)
    copyProfileButton:SetSize(68, 24)
    copyProfileButton:SetText("Copy")
    copyProfileButton:SetScript("OnClick", function()
        addon:CopyProfile(copySourceName)
    end)

    local resetProfileButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    resetProfileButton:SetPoint("TOPLEFT", copySourceButton, "BOTTOMLEFT", 0, -10)
    resetProfileButton:SetSize(120, 24)
    resetProfileButton:SetText("Reset Profile")
    resetProfileButton:SetScript("OnClick", function()
        addon:ResetProfile()
    end)

    local deleteProfileButton = CreateFrame("Button", nil, generalColumn, "UIPanelButtonTemplate")
    deleteProfileButton:SetPoint("LEFT", resetProfileButton, "RIGHT", 8, 0)
    deleteProfileButton:SetSize(100, 24)
    deleteProfileButton:SetText("Delete Source")
    deleteProfileButton:SetScript("OnClick", function()
        addon:DeleteProfile(copySourceName)
        copySourceName = nil
        copySourceButton:Refresh()
    end)

    local activeGroupIndex = 1
    local groupTitle = groupColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupTitle:SetPoint("TOPLEFT", 0, 0)
    groupTitle:SetTextColor(unpack(colors.heading))

    local previousGroup = CreateFrame("Button", nil, groupColumn, "UIPanelButtonTemplate")
    previousGroup:SetText("Prev")
    previousGroup:SetPoint("LEFT", groupTitle, "RIGHT", 10, 0)
    previousGroup:SetSize(52, 22)

    local nextGroup = CreateFrame("Button", nil, groupColumn, "UIPanelButtonTemplate")
    nextGroup:SetText("Next")
    nextGroup:SetPoint("LEFT", previousGroup, "RIGHT", 4, 0)
    nextGroup:SetSize(52, 22)

    local groupControls = {}
    local function activeGroup()
        return addon.db.profile.groups[activeGroupIndex]
    end

    local function refreshGroupControls()
        local group = activeGroup()
        groupTitle:SetText("Group " .. activeGroupIndex .. "/" .. #addon.db.profile.groups .. ": " .. (group and group.name or "Unknown"))
        for _, control in ipairs(groupControls) do
            control:Refresh()
        end
    end

    local groupEnabled = createCheckbox(groupColumn, "Enable this group", function()
        local group = activeGroup()
        return group and group.enabled ~= false
    end, function(value)
        local group = activeGroup()
        group.enabled = value
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", groupTitle)
    groupEnabled:SetPoint("TOPLEFT", groupTitle, "BOTTOMLEFT", 0, -16)
    table.insert(groupControls, groupEnabled)

    local onlyMineToggle = createCheckbox(groupColumn, "Only my auras", function()
        return activeGroup().onlyMine == true
    end, function(value)
        activeGroup().onlyMine = value
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled)
    onlyMineToggle:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -14)
    table.insert(groupControls, onlyMineToggle)

    local permanentToggle = createCheckbox(groupColumn, "Hide permanent auras", function()
        return activeGroup().hidePermanent == true
    end, function(value)
        activeGroup().hidePermanent = value
        addon:RefreshAll()
    end, "TOPLEFT", onlyMineToggle)
    permanentToggle:SetPoint("TOPLEFT", onlyMineToggle, "BOTTOMLEFT", 0, -8)
    table.insert(groupControls, permanentToggle)

    local widthControl = createStepper(groupColumn, "Bar width", function()
        return activeGroup().width or 220
    end, function(value)
        local group = activeGroup()
        group.width = math.max(120, math.min(500, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", permanentToggle, -26)
    table.insert(groupControls, widthControl)

    local heightControl = createStepper(groupColumn, "Bar height", function()
        return activeGroup().height or 18
    end, function(value)
        local group = activeGroup()
        group.height = math.max(12, math.min(40, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", widthControl.caption, -26)
    table.insert(groupControls, heightControl)

    local targetMaxBarsControl = createStepper(groupColumn, "Target max bars", function()
        return activeGroup().maxBars or 16
    end, function(value)
        addon:SetTargetGroupMaxBars(activeGroup().id, value)
    end, "TOPLEFT", heightControl.caption, -26)
    function targetMaxBarsControl:Refresh()
        self:SetShown(activeGroup().unit == "target")
        if activeGroup().unit == "target" then
            self.value:SetText(tostring(activeGroup().maxBars or 16))
        end
    end
    table.insert(groupControls, targetMaxBarsControl)

    local sortButton = CreateFrame("Button", nil, groupColumn, "UIPanelButtonTemplate")
    sortButton:SetPoint("TOPLEFT", targetMaxBarsControl.caption, "BOTTOMLEFT", 0, -18)
    sortButton:SetSize(240, 24)
    function sortButton:Refresh()
        local mode = activeGroup().sort or "EXPIRATION"
        self:SetText(mode == "NAME" and "Sort: Name" or "Sort: Expiration")
    end
    sortButton:SetScript("OnClick", function()
        local group = activeGroup()
        group.sort = group.sort == "NAME" and "EXPIRATION" or "NAME"
        addon:RefreshAll()
        sortButton:Refresh()
    end)
    table.insert(groupControls, sortButton)

    local growButton = CreateFrame("Button", nil, groupColumn, "UIPanelButtonTemplate")
    growButton:SetPoint("TOPLEFT", sortButton, "BOTTOMLEFT", 0, -10)
    growButton:SetSize(240, 24)
    function growButton:Refresh()
        self:SetText(activeGroup().grow == "UP" and "Grow: Up" or "Grow: Down")
    end
    growButton:SetScript("OnClick", function()
        local group = activeGroup()
        addon:SetGroupGrow(group.id, group.grow == "UP" and "DOWN" or "UP")
        growButton:Refresh()
    end)
    table.insert(groupControls, growButton)

    local chainButton = CreateFrame("Button", nil, groupColumn, "UIPanelButtonTemplate")
    chainButton:SetPoint("TOPLEFT", growButton, "BOTTOMLEFT", 0, -10)
    chainButton:SetSize(260, 24)
    local function getChainCandidates(group)
        local candidates = { nil }
        for _, candidate in ipairs(addon.db.profile.groups) do
            if candidate.id < group.id then
                table.insert(candidates, candidate.id)
            end
        end
        return candidates
    end
    function chainButton:Refresh()
        local parentId = activeGroup().anchorTo
        local parent = parentId and addon.db.profile.groups[parentId]
        self:SetText(parent and "Chain after: " .. parent.name or "Chain after: None")
    end
    chainButton:SetScript("OnClick", function()
        local group = activeGroup()
        local candidates = getChainCandidates(group)
        local currentIndex = 1
        for index, candidateId in ipairs(candidates) do
            if candidateId == group.anchorTo then
                currentIndex = index
                break
            end
        end
        local nextIndex = currentIndex + 1
        if nextIndex > #candidates then
            nextIndex = 1
        end
        addon:SetGroupChain(group.id, candidates[nextIndex])
        chainButton:Refresh()
    end)
    table.insert(groupControls, chainButton)

    local function cycleGroup(direction)
        activeGroupIndex = activeGroupIndex + direction
        if activeGroupIndex < 1 then
            activeGroupIndex = #addon.db.profile.groups
        elseif activeGroupIndex > #addon.db.profile.groups then
            activeGroupIndex = 1
        end
        refreshGroupControls()
    end

    previousGroup:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    previousGroup:SetScript("OnClick", function(_, button)
        cycleGroup(button == "RightButton" and 1 or -1)
    end)
    nextGroup:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    nextGroup:SetScript("OnClick", function(_, button)
        cycleGroup(button == "RightButton" and -1 or 1)
    end)
    function panel:Refresh()
        for _, control in ipairs(globalControls) do
            control:Refresh()
        end
        for _, control in ipairs(profileControls) do
            control:Refresh()
        end
        refreshGroupControls()
    end

    panel:SetScript("OnShow", function()
        panel:Refresh()
    end)
    panel:Refresh()

    local closeButton = CreateFrame("Button", "EBBPhoenixCloseButton", panel, "UIPanelButtonTemplate")
    closeButton:SetText("Close")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -12)
    closeButton:SetSize(90, 24)
    closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)

    panel.okay = function()
        addon:RefreshAll()
    end

    panel.cancel = function()
        addon:RefreshAll()
    end

    return panel
end

function Options:Open()
    if not self.panel then
        self.panel = buildPanel()
    end
    self.panel:Show()
end

function Options:RegisterSettingsCategory()
    if self.settingsRegistered or not Settings or not Settings.RegisterCanvasLayoutCategory then
        return
    end

    self.settingsPanel = createSettingsPanel()
    local category = Settings.RegisterCanvasLayoutCategory(self.settingsPanel, "EBB Phoenix")
    category.ID = "EBBPhoenix"
    Settings.RegisterAddOnCategory(category)
    self.settingsRegistered = true
end

function addon:ToggleOptions()
    if self.Options and self.Options.Open then
        self.Options:Open()
    else
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("EBB Phoenix: options not available yet")
        end
    end
end

function addon:ToggleMainWindow()
    self.state.showing = not self.state.showing
    for _, group in pairs(self.state.groups) do
        if group and group.frame then
            if self.state.showing then
                group.frame:Show()
            else
                group.frame:Hide()
            end
        end
    end
end

addon.Options = Options
