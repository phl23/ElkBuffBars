local _, addon = ...

addon.Options = addon.Options or {}

local Options = addon.Options

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
    mark:SetColorTexture(0.95, 0.75, 0.12, 1)
    button.mark = mark

    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", button, "RIGHT", 8, 0)
    text:SetText(label)

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

    local value = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    value:SetPoint("LEFT", caption, "RIGHT", 12, 0)

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

local function buildPanel()
    local panel = CreateFrame("Frame", "EBBPhoenixOptionsPanel", UIParent)
    panel:SetWidth(400)
    panel:SetHeight(640)
    local content = panel
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
    border:SetColorTexture(0.55, 0.4, 0.08, 1)

    local inner = panel:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    inner:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    inner:SetColorTexture(0.03, 0.03, 0.03, 0.96)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EBB Phoenix")

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Modern buff and debuff bar groups")

    local refreshButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    refreshButton:SetText("Refresh")
    refreshButton:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    refreshButton:SetSize(120, 24)
    refreshButton:SetScript("OnClick", function()
        addon:RefreshAll()
    end)

    local globalControls = {}

    local minimapToggle = createCheckbox(content, "Show minimap button", function()
        return not addon.db.profile.minimap.hide
    end, function(value)
        addon.db.profile.minimap.hide = not value
        addon.Minimap:Refresh()
    end, "TOPLEFT", refreshButton)
    minimapToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -20)
    table.insert(globalControls, minimapToggle)

    local lockToggle = createCheckbox(content, "Lock bar positions", function()
        return addon.db.profile.locked == true
    end, function(value)
        addon:SetBarsLocked(value)
    end, "TOPLEFT", refreshButton)
    lockToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -48)
    table.insert(globalControls, lockToggle)

    local iconsToggle = createCheckbox(content, "Show icons", function()
        return addon.db.profile.groups[1].icon ~= false
    end, function(value)
        addon:SetAllGroupsField("icon", value)
    end, "TOPLEFT", refreshButton)
    iconsToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -76)
    table.insert(globalControls, iconsToggle)

    local namesToggle = createCheckbox(content, "Show aura names", function()
        return addon.db.profile.groups[1].text ~= false
    end, function(value)
        addon:SetAllGroupsField("text", value)
    end, "TOPLEFT", refreshButton)
    namesToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -104)
    table.insert(globalControls, namesToggle)

    local fontButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    fontButton:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -132)
    fontButton:SetSize(250, 24)
    function fontButton:Refresh()
        self:SetText("Font: " .. (addon.db.profile.font or addon.Media.defaultFont))
    end
    fontButton:SetScript("OnClick", function()
        local fonts = addon.Media:GetFontNames()
        local currentFont = addon.db.profile.font or addon.Media.defaultFont
        local selectedIndex = 1
        for index, fontName in ipairs(fonts) do
            if fontName == currentFont then
                selectedIndex = index
                break
            end
        end
        addon.db.profile.font = fonts[(selectedIndex % #fonts) + 1]
        addon:RefreshAll()
        fontButton:Refresh()
    end)
    fontButton:Refresh()
    table.insert(globalControls, fontButton)

    local fontShadowToggle = createCheckbox(content, "Font shadow", function()
        return addon.db.profile.fontShadow ~= false
    end, function(value)
        addon.db.profile.fontShadow = value
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    fontShadowToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -160)
    table.insert(globalControls, fontShadowToggle)

    local hideBlizzardBuffsToggle = createCheckbox(content, "Hide Blizzard buffs", function()
        return addon.db.profile.hideBlizzardBuffs == true
    end, function(value)
        addon.db.profile.hideBlizzardBuffs = value
        addon:ApplyBlizzardAuraVisibility()
    end, "TOPLEFT", refreshButton)
    hideBlizzardBuffsToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -188)
    table.insert(globalControls, hideBlizzardBuffsToggle)

    local hideBlizzardDebuffsToggle = createCheckbox(content, "Hide Blizzard debuffs", function()
        return addon.db.profile.hideBlizzardDebuffs == true
    end, function(value)
        addon.db.profile.hideBlizzardDebuffs = value
        addon:ApplyBlizzardAuraVisibility()
    end, "TOPLEFT", refreshButton)
    hideBlizzardDebuffsToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -216)
    table.insert(globalControls, hideBlizzardDebuffsToggle)

    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetText("Reset Positions")
    resetButton:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -252)
    resetButton:SetSize(120, 24)
    resetButton:SetScript("OnClick", function()
        addon:ResetPositions()
    end)

    local divider = content:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -18)
    divider:SetSize(368, 1)
    divider:SetColorTexture(0.55, 0.4, 0.08, 1)

    local activeGroupIndex = 1
    local groupTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -14)

    local previousGroup = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    previousGroup:SetText("<")
    previousGroup:SetPoint("LEFT", groupTitle, "RIGHT", 10, 0)
    previousGroup:SetSize(24, 20)

    local nextGroup = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    nextGroup:SetText(">")
    nextGroup:SetPoint("LEFT", previousGroup, "RIGHT", 4, 0)
    nextGroup:SetSize(24, 20)

    local groupControls = {}
    local function activeGroup()
        return addon.db.profile.groups[activeGroupIndex]
    end

    local function refreshGroupControls()
        local group = activeGroup()
        groupTitle:SetText("Configure: " .. (group and group.name or "Unknown"))
        for _, control in ipairs(groupControls) do
            control:Refresh()
        end
    end

    local groupEnabled = createCheckbox(content, "Enable this group", function()
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

    local onlyMineToggle = createCheckbox(content, "Only my auras", function()
        return activeGroup().onlyMine == true
    end, function(value)
        activeGroup().onlyMine = value
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled)
    onlyMineToggle:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -28)
    table.insert(groupControls, onlyMineToggle)

    local permanentToggle = createCheckbox(content, "Hide permanent auras", function()
        return activeGroup().hidePermanent == true
    end, function(value)
        activeGroup().hidePermanent = value
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled)
    permanentToggle:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -56)
    table.insert(groupControls, permanentToggle)

    local widthControl = createStepper(content, "Bar width", function()
        return activeGroup().width or 220
    end, function(value)
        local group = activeGroup()
        group.width = math.max(120, math.min(500, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled, -90)
    table.insert(groupControls, widthControl)

    local heightControl = createStepper(content, "Bar height", function()
        return activeGroup().height or 18
    end, function(value)
        local group = activeGroup()
        group.height = math.max(12, math.min(40, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled, -116)
    table.insert(groupControls, heightControl)

    local targetMaxBarsControl = createStepper(content, "Target max bars", function()
        return activeGroup().maxBars or 16
    end, function(value)
        addon:SetTargetGroupMaxBars(activeGroup().id, value)
    end, "TOPLEFT", groupEnabled, -142)
    function targetMaxBarsControl:Refresh()
        self:SetShown(activeGroup().unit == "target")
        if activeGroup().unit == "target" then
            self.value:SetText(tostring(activeGroup().maxBars or 16))
        end
    end
    table.insert(groupControls, targetMaxBarsControl)

    local sortButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    sortButton:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -170)
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

    local growButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    growButton:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -200)
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

    local chainButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    chainButton:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -230)
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

    previousGroup:SetScript("OnClick", function()
        activeGroupIndex = activeGroupIndex - 1
        if activeGroupIndex < 1 then
            activeGroupIndex = #addon.db.profile.groups
        end
        refreshGroupControls()
    end)
    nextGroup:SetScript("OnClick", function()
        activeGroupIndex = activeGroupIndex + 1
        if activeGroupIndex > #addon.db.profile.groups then
            activeGroupIndex = 1
        end
        refreshGroupControls()
    end)
    function panel:Refresh()
        for _, control in ipairs(globalControls) do
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
