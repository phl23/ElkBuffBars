local addonName, addon = ...

_G[addonName] = addon

addon.name = addonName
addon.version = "3.0.0"
addon.state = {
    groups = {},
    activeUnitData = {},
    config = {
        groups = {
            {
                id = 1,
                name = "Player Buffs",
                unit = "player",
                filter = "HELPFUL",
                width = 220,
                height = 18,
                anchor = { "TOPLEFT", UIParent, "TOPLEFT", 20, -60 },
                grow = "RIGHT",
                icon = true,
                text = true,
            },
            {
                id = 2,
                name = "Player Debuffs",
                unit = "player",
                filter = "HARMFUL",
                width = 220,
                height = 18,
                anchor = { "TOPLEFT", UIParent, "TOPLEFT", 20, -120 },
                grow = "RIGHT",
                icon = true,
                text = true,
            },
        },
    },
}

addon.frame = CreateFrame("Frame", addonName .. "Frame", UIParent)
addon.frame:SetScript("OnEvent", function(frame, event, ...)
    if addon[event] then
        addon[event](addon, ...)
    end
end)

function addon:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true
    self:BuildGroups()
    self:RegisterCoreEvents()
    self:RefreshAll()
end

function addon:RegisterCoreEvents()
    local events = {
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "UNIT_AURA",
        "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED",
    }

    for _, event in ipairs(events) do
        addon.frame:RegisterEvent(event)
    end
end

function addon:PLAYER_LOGIN()
    self:RefreshAll()
end

function addon:PLAYER_ENTERING_WORLD()
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

function addon:BuildGroups()
    if not self.Layout or not self.Layout.CreateGroup then
        return
    end

    for _, groupConfig in ipairs(self.state.config.groups) do
        local group = self.Layout:CreateGroup(groupConfig)
        self.state.groups[groupConfig.id] = group
    end
end
