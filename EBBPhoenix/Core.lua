local addonName, addon = ...

_G[addonName] = addon

addon.name = addonName
addon.version = "3.0.0"
addon.state = {
    groups = {},
    activeUnitData = {},
    config = {
        groups = {},
    },
    lastRefresh = 0,
    showing = true,
}

addon.frame = CreateFrame("Frame", addonName .. "Frame", UIParent)
addon.frame:RegisterEvent("PLAYER_LOGIN")
addon.frame:SetScript("OnEvent", function(frame, event, ...)
    if addon[event] then
        addon[event](addon, ...)
    end
end)
addon.frame:SetScript("OnUpdate", function(_, elapsed)
    addon:UpdateDurationDisplays(elapsed)
end)

function addon:RegisterSlashCommands()
    if self.slashCommandsRegistered then
        return
    end

    if not _G.SlashCmdList then
        _G.SlashCmdList = {}
    end

    _G.SlashCmdList["EBBPHOENIX"] = function(msg)
        local command = string.lower(tostring(msg or ""))

        if command == "status" then
            addon:PrintStatus()
        elseif command == "reset" then
            addon:ResetPositions()
            DEFAULT_CHAT_FRAME:AddMessage("EBB Phoenix: bar positions reset")
        elseif addon.Options and addon.Options.Open then
            addon.Options:Open()
        else
            DEFAULT_CHAT_FRAME:AddMessage("EBB Phoenix: options not available yet")
        end
    end

    _G.SLASH_EBBPHOENIX1 = "/px"
    _G.SLASH_EBBPHOENIX2 = "/phoenix"
    _G.SLASH_EBBPHOENIX3 = "/pheonix"
    self.slashCommandsRegistered = true
end

addon:RegisterSlashCommands()

local hiddenBlizzardFrames = {}
local blizzardFrameHooks = {}

local function ensureBlizzardFrameHook(frameName)
    if blizzardFrameHooks[frameName] then
        return
    end

    local frame = _G[frameName]
    if not frame or not frame.HookScript then
        return
    end

    frame:HookScript("OnShow", function(currentFrame)
        if hiddenBlizzardFrames[frameName] then
            currentFrame:Hide()
        end
    end)
    blizzardFrameHooks[frameName] = true
end

function addon:SetBlizzardFrameHidden(frameName, hidden)
    local frame = _G[frameName]
    if not frame then
        return
    end

    ensureBlizzardFrameHook(frameName)
    if hidden then
        hiddenBlizzardFrames[frameName] = true
        frame:Hide()
        return
    end

    hiddenBlizzardFrames[frameName] = nil
    frame:Show()
    if frame.Update then
        frame:Update()
    elseif frameName == "BuffFrame" and BuffFrame_Update then
        BuffFrame_Update()
    end
end

function addon:ApplyBlizzardAuraVisibility()
    if not self.db or not self.db.profile then
        return
    end

    self:SetBlizzardFrameHidden("BuffFrame", self.db.profile.hideBlizzardBuffs)
    self:SetBlizzardFrameHidden("DebuffFrame", self.db.profile.hideBlizzardDebuffs)
end

function addon:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
    self:LoadSavedVariables()
    local ebbIsInUse = false
    for globalName, alias in pairs(_G) do
        if type(globalName) == "string" and string.find(globalName, "^SLASH_") and type(alias) == "string" and string.lower(alias) == "/ebb" then
            ebbIsInUse = true
            break
        end
    end

    if not ebbIsInUse and not _G.SlashCmdList["EBB"] then
        _G.SlashCmdList["EBB"] = _G.SlashCmdList["EBBPHOENIX"]
        _G.SLASH_EBB1 = "/ebb"
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("EBB Phoenix: /ebb is already used; use /px or /phoenix")
    end

    self:BuildGroups()
    self:RegisterCoreEvents()
    self:CreateMinimapButton()
    self:ApplyBlizzardAuraVisibility()
    self.Options:RegisterSettingsCategory()
    self:RefreshAll()
end

function addon:RegisterCoreEvents()
    local events = {
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "UNIT_AURA",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
        "UNIT_TARGET",
        "GROUP_ROSTER_UPDATE",
        "UPDATE_SHAPESHIFT_FORM",
    }

    for _, event in ipairs(events) do
        addon.frame:RegisterEvent(event)
    end
end

function addon:PLAYER_LOGIN()
    self:LoadSavedVariables()
    self:BuildGroups()
    self.Options:RegisterSettingsCategory()
    self:RefreshAll()
end

function addon:PLAYER_ENTERING_WORLD()
    self:ApplyBlizzardAuraVisibility()
    self:RefreshAll()
end

function addon:UNIT_AURA(unitToken)
    if not unitToken then
        return
    end
    self:RefreshUnit(unitToken)
end

function addon:PLAYER_TARGET_CHANGED()
    self:RefreshUnit("target")
end

function addon:PLAYER_FOCUS_CHANGED()
    self:RefreshUnit("focus")
end

function addon:UNIT_TARGET(unitToken)
    if unitToken == "player" then
        self:RefreshUnit("player")
    end
end

function addon:GROUP_ROSTER_UPDATE()
    self:RefreshAll()
end

function addon:UPDATE_SHAPESHIFT_FORM()
    self:RefreshAll()
end

function addon:RefreshAll()
    if not self.Main or not self.Main.RefreshAll then
        return
    end
    self.Main:RefreshAll()
end

function addon:RefreshUnit(unitToken)
    if not self.Main or not self.Main.RefreshUnit then
        return
    end
    self.Main:RefreshUnit(unitToken)
end

function addon:UpdateDurationDisplays(elapsed)
    self.state.durationElapsed = (self.state.durationElapsed or 0) + elapsed
    if self.state.durationElapsed < 0.1 then
        return
    end

    self.state.durationElapsed = 0
    if self.Main and self.Main.UpdateDurationDisplays then
        self.Main:UpdateDurationDisplays()
    end
end

function addon:BuildGroups()
    if not self.Layout or not self.Layout.CreateGroup then
        return
    end

    for _, oldGroup in pairs(self.state.groups) do
        if oldGroup.frame then
            oldGroup.frame:Hide()
        end
    end

    self.state.groups = {}
    for _, groupConfig in ipairs(self.state.config.groups) do
        local group = self.Layout:CreateGroup(groupConfig)
        self.state.groups[groupConfig.id] = group
    end

    self.Layout:UpdateChainedAnchors()
end

function addon:CreateMinimapButton()
    if self.Minimap and self.Minimap.Create then
        self.Minimap:Create()
    end
end

function addon:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("EBB Phoenix " .. self.version .. " status")
    for _, groupConfig in ipairs(self.state.config.groups) do
        local group = self.state.groups[groupConfig.id]
        if group then
            local auraList = self.AuraData:CollectForGroup(group)
            local _, _, _, x, y = group.frame:GetPoint(1)
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "%s: %d %s auras, %d bars, shown=%s, x=%d y=%d",
                group.name,
                #auraList,
                group.filter,
                #group.bars,
                tostring(group.frame:IsShown()),
                x or 0,
                y or 0
            ))
        end
    end
end

addon:Initialize()
