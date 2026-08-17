local addonName, addon = ...

addon.defaults = {
    profile = {
        minimap = {
            hide = false,
            radius = 80,
            lock = false,
        },
        locked = false,
        groups = {
            {
                id = 1,
                name = "Player Buffs",
                unit = "player",
                filter = "HELPFUL",
                width = 220,
                height = 18,
                anchor = { "TOPLEFT", nil, "TOPLEFT", 20, -60 },
                grow = "DOWN",
                enabled = true,
                maxBars = 16,
                sort = "EXPIRATION",
                onlyMine = false,
                hidePermanent = false,
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
                anchor = { "TOPLEFT", nil, "TOPLEFT", 20, -310 },
                grow = "DOWN",
                enabled = true,
                maxBars = 16,
                sort = "EXPIRATION",
                onlyMine = false,
                hidePermanent = false,
                icon = true,
                text = true,
            },
            {
                id = 3,
                name = "Target Buffs",
                unit = "target",
                filter = "HELPFUL",
                width = 220,
                height = 18,
                anchor = { "TOPLEFT", nil, "TOPLEFT", 270, -60 },
                grow = "DOWN",
                enabled = true,
                maxBars = 16,
                sort = "EXPIRATION",
                onlyMine = false,
                hidePermanent = false,
                icon = true,
                text = true,
            },
            {
                id = 4,
                name = "Target Debuffs",
                unit = "target",
                filter = "HARMFUL",
                width = 220,
                height = 18,
                anchor = { "TOPLEFT", nil, "TOPLEFT", 270, -310 },
                grow = "DOWN",
                enabled = true,
                maxBars = 16,
                sort = "EXPIRATION",
                onlyMine = false,
                hidePermanent = false,
                icon = true,
                text = true,
            },
        },
    },
}

function addon:ApplyProfileDefaults()
    if not self.db or not self.db.profile then
        return
    end

    for key, value in pairs(self.defaults.profile) do
        if self.db.profile[key] == nil then
            if type(value) == "table" then
                self.db.profile[key] = CopyTable(value)
            else
                self.db.profile[key] = value
            end
        end
    end

    if type(self.db.profile.groups) ~= "table" or #self.db.profile.groups == 0 then
        self.db.profile.groups = CopyTable(self.defaults.profile.groups)
    end

    for _, group in ipairs(self.db.profile.groups) do
        if group.grow == "RIGHT" then
            group.grow = "DOWN"
        end
        if group.enabled == nil then
            group.enabled = true
        end
        if group.maxBars == nil then
            group.maxBars = 16
        end
        if group.sort == nil then
            group.sort = "EXPIRATION"
        end
        if group.onlyMine == nil then
            group.onlyMine = false
        end
        if group.hidePermanent == nil then
            group.hidePermanent = false
        end
        if type(group.anchor) ~= "table" then
            group.anchor = { "TOPLEFT", nil, "TOPLEFT", 20, -60 }
        end
        group.anchor[2] = nil
    end

    for index, defaultGroup in ipairs(self.defaults.profile.groups) do
        if not self.db.profile.groups[index] then
            self.db.profile.groups[index] = CopyTable(defaultGroup)
        end
    end

    if self.db.profile.layoutVersion ~= 2 then
        for index, defaultGroup in ipairs(self.defaults.profile.groups) do
            local group = self.db.profile.groups[index]
            if group then
                group.anchor = CopyTable(defaultGroup.anchor)
                group.grow = defaultGroup.grow
            end
        end
        self.db.profile.layoutVersion = 2
    end
end

function addon:LoadSavedVariables()
    _G[addonName .. "DB"] = _G[addonName .. "DB"] or {}
    self.db = _G[addonName .. "DB"]
    self.db.profile = self.db.profile or {}
    self:ApplyProfileDefaults()
    self.state.config.groups = self.db.profile.groups
end

function addon:AddGroup(groupConfig)
    local config = groupConfig or {
        id = #self.db.profile.groups + 1,
        name = "Group " .. (#self.db.profile.groups + 1),
        unit = "player",
        filter = "HELPFUL",
        width = 220,
        height = 18,
        anchor = { "TOPLEFT", nil, "TOPLEFT", 20, -60 },
        grow = "DOWN",
        enabled = true,
        maxBars = 16,
        icon = true,
        text = true,
    }

    table.insert(self.db.profile.groups, config)
    self.state.config.groups = self.db.profile.groups
    self:BuildGroups()
end

function addon:RemoveGroup(groupId)
    for index, group in ipairs(self.db.profile.groups) do
        if group.id == groupId then
            table.remove(self.db.profile.groups, index)
            break
        end
    end

    self.state.config.groups = self.db.profile.groups
    self:BuildGroups()
end

function addon:SetAllGroupsField(field, value)
    for _, group in ipairs(self.db.profile.groups) do
        group[field] = value
    end

    self:BuildGroups()
    self:RefreshAll()
end

function addon:SetAllGroupsMaxBars(value)
    local maxBars = math.max(1, math.min(40, value))
    self:SetAllGroupsField("maxBars", maxBars)
end

function addon:AdjustGroupField(groupId, field, delta, minimum, maximum)
    local group = self.db.profile.groups[groupId]
    if not group then
        return
    end

    local current = group[field] or minimum
    group[field] = math.max(minimum, math.min(maximum, current + delta))
    self:BuildGroups()
    self:RefreshAll()
end

function addon:ResetPositions()
    for index, group in ipairs(self.db.profile.groups) do
        local defaultGroup = self.defaults.profile.groups[index]
        if defaultGroup then
            group.anchor = CopyTable(defaultGroup.anchor)
        end
    end

    self:BuildGroups()
    self:RefreshAll()
end
