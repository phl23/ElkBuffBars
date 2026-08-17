local _, addon = ...

addon.Options = addon.Options or {}

local Options = addon.Options

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
    return control
end

local function buildPanel()
    local panel = CreateFrame("Frame", "EBBPhoenixOptionsPanel", UIParent)
    panel.name = "EBB Phoenix"
    panel:SetWidth(320)
    panel:SetHeight(700)
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

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("EBB Phoenix")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Modern buff and debuff bar groups")

    local refreshButton = CreateFrame("Button", "EBBPhoenixRefreshButton", panel, "UIPanelButtonTemplate")
    refreshButton:SetText("Refresh")
    refreshButton:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    refreshButton:SetSize(120, 24)
    refreshButton:SetScript("OnClick", function()
        addon:RefreshAll()
    end)

    local minimapToggle = createCheckbox(panel, "Show minimap button", function()
        return not addon.db.profile.minimap.hide
    end, function(value)
        addon.db.profile.minimap.hide = not value
        addon.Minimap:Refresh()
    end, "TOPLEFT", refreshButton)
    minimapToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -20)

    local buffGroup = addon.db.profile.groups[1]
    local buffToggle = createCheckbox(panel, "Show player buffs", function()
        return buffGroup and buffGroup.enabled ~= false
    end, function(value)
        buffGroup.enabled = value
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    buffToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -48)

    local debuffGroup = addon.db.profile.groups[2]
    local debuffToggle = createCheckbox(panel, "Show player debuffs", function()
        return debuffGroup and debuffGroup.enabled ~= false
    end, function(value)
        debuffGroup.enabled = value
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    debuffToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -76)

    local targetBuffGroup = addon.db.profile.groups[3]
    local targetBuffToggle = createCheckbox(panel, "Show target buffs", function()
        return targetBuffGroup and targetBuffGroup.enabled ~= false
    end, function(value)
        targetBuffGroup.enabled = value
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    targetBuffToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -104)

    local targetDebuffGroup = addon.db.profile.groups[4]
    local targetDebuffToggle = createCheckbox(panel, "Show target debuffs", function()
        return targetDebuffGroup and targetDebuffGroup.enabled ~= false
    end, function(value)
        targetDebuffGroup.enabled = value
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", refreshButton)
    targetDebuffToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -132)

    local lockToggle = createCheckbox(panel, "Lock bar positions", function()
        return addon.db.profile.locked == true
    end, function(value)
        addon.db.profile.locked = value
    end, "TOPLEFT", refreshButton)
    lockToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -168)

    local iconsToggle = createCheckbox(panel, "Show icons", function()
        return addon.db.profile.groups[1].icon ~= false
    end, function(value)
        addon:SetAllGroupsField("icon", value)
    end, "TOPLEFT", refreshButton)
    iconsToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -196)

    local namesToggle = createCheckbox(panel, "Show aura names", function()
        return addon.db.profile.groups[1].text ~= false
    end, function(value)
        addon:SetAllGroupsField("text", value)
    end, "TOPLEFT", refreshButton)
    namesToggle:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -228)

    local maxBarsControl = createStepper(panel, "Max bars", function()
        return addon.db.profile.groups[1].maxBars or 16
    end, function(value)
        addon:SetAllGroupsMaxBars(value)
    end, "TOPLEFT", refreshButton, -260)
    maxBarsControl:Refresh()

    local resetButton = CreateFrame("Button", "EBBPhoenixResetButton", panel, "UIPanelButtonTemplate")
    resetButton:SetText("Reset Positions")
    resetButton:SetPoint("TOPLEFT", refreshButton, "BOTTOMLEFT", 0, -296)
    resetButton:SetSize(120, 24)
    resetButton:SetScript("OnClick", function()
        addon:ResetPositions()
    end)

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -18)
    divider:SetSize(288, 1)
    divider:SetColorTexture(0.55, 0.4, 0.08, 1)

    local activeGroupIndex = 1
    local groupTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    groupTitle:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -14)

    local previousGroup = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previousGroup:SetText("<")
    previousGroup:SetPoint("LEFT", groupTitle, "RIGHT", 10, 0)
    previousGroup:SetSize(24, 20)

    local nextGroup = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
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

    local groupEnabled = createCheckbox(panel, "Enable this group", function()
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

    local onlyMineToggle = createCheckbox(panel, "Only my auras", function()
        return activeGroup().onlyMine == true
    end, function(value)
        activeGroup().onlyMine = value
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled)
    onlyMineToggle:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -28)
    table.insert(groupControls, onlyMineToggle)

    local permanentToggle = createCheckbox(panel, "Hide permanent auras", function()
        return activeGroup().hidePermanent == true
    end, function(value)
        activeGroup().hidePermanent = value
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled)
    permanentToggle:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -56)
    table.insert(groupControls, permanentToggle)

    local widthControl = createStepper(panel, "Bar width", function()
        return activeGroup().width or 220
    end, function(value)
        local group = activeGroup()
        group.width = math.max(120, math.min(500, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled, -90)
    table.insert(groupControls, widthControl)

    local heightControl = createStepper(panel, "Bar height", function()
        return activeGroup().height or 18
    end, function(value)
        local group = activeGroup()
        group.height = math.max(12, math.min(40, value))
        addon:BuildGroups()
        addon:RefreshAll()
    end, "TOPLEFT", groupEnabled, -116)
    table.insert(groupControls, heightControl)

    local sortButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    sortButton:SetPoint("TOPLEFT", groupEnabled, "BOTTOMLEFT", 0, -150)
    sortButton:SetSize(180, 24)
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
    refreshGroupControls()

    local closeButton = CreateFrame("Button", "EBBPhoenixCloseButton", panel, "UIPanelButtonTemplate")
    closeButton:SetText("Close")
    closeButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
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
