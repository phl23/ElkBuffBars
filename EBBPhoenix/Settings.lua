local addonName, addon = ...

addon.defaults = {
    profile = {
        minimap = {
            hide = false,
            radius = 80,
            lock = false,
        },
        locked = false,
        barTexture = "Luna Minimalist",
        barStyle = "minimal_clean",
        barSpacing = 4,
        colorDebuffsByType = false,
        font = "Aldrich",
        fontShadow = true,
        hideBlizzardBuffs = false,
        hideBlizzardDebuffs = false,
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
                onlyMine = true,
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
                onlyMine = true,
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

    if self.db.profile.barTexture == "Luna Minimalist" then
        self.db.profile.barTexture = self.defaults.profile.barTexture
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
        if group.unit == "target" and group.maxBars == nil then
            group.maxBars = 16
        elseif group.unit ~= "target" then
            group.maxBars = nil
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

    if (self.db.profile.layoutVersion or 0) < 2 then
        for index, defaultGroup in ipairs(self.defaults.profile.groups) do
            local group = self.db.profile.groups[index]
            if group then
                group.anchor = CopyTable(defaultGroup.anchor)
                group.grow = defaultGroup.grow
            end
        end
    end

    self.db.profile.layoutVersion = 3
end

function addon:LoadSavedVariables()
    if self.db then
        return
    end

    local databaseName = addonName .. "DB"
    local savedVariables = _G[databaseName] or {}
    local migrateLegacyProfile = savedVariables.profile and not savedVariables.profiles

    if migrateLegacyProfile then
        savedVariables.profiles = { Default = savedVariables.profile }
        savedVariables.profile = nil
    end

    _G[databaseName] = savedVariables
    local AceDB = LibStub and LibStub("AceDB-3.0", true)
    if AceDB then
        self.usingAceDB = true
        self.db = AceDB:New(databaseName, self.defaults)
        if migrateLegacyProfile then
            self.db:SetProfile("Default")
        end

        self.db:RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
        self.db:RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
        self.db:RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    else
        self.usingAceDB = false
        savedVariables.profiles = savedVariables.profiles or {}
        savedVariables.profileKeys = savedVariables.profileKeys or {}

        local characterName = UnitName("player") or "Unknown"
        local realmName = GetRealmName() or "Unknown Realm"
        local characterKey = characterName .. " - " .. realmName
        local profileName = savedVariables.profileKeys[characterKey] or characterKey
        savedVariables.profileKeys[characterKey] = profileName
        savedVariables.profiles[profileName] = savedVariables.profiles[profileName] or {}

        self.db = {
            profile = savedVariables.profiles[profileName],
            profileName = profileName,
            savedVariables = savedVariables,
            characterKey = characterKey,
        }
    end
    self:ApplyProfileDefaults()
    self.state.config.groups = self.db.profile.groups
end

function addon:OnProfileChanged()
    self:ApplyProfileDefaults()
    self.state.config.groups = self.db.profile.groups
    self:BuildGroups()
    self:ApplyBlizzardAuraVisibility()
    self:RefreshAll()
    if self.Options and self.Options.panel then
        self.Options.panel:Refresh()
    end
end

function addon:GetProfileNames()
    local profiles = self.usingAceDB and self.db:GetProfiles() or {}
    if not self.usingAceDB then
        for profileName in pairs(self.db.savedVariables.profiles) do
            table.insert(profiles, profileName)
        end
    end
    table.sort(profiles)
    return profiles
end

function addon:GetCurrentProfile()
    return self.usingAceDB and self.db:GetCurrentProfile() or self.db.profileName
end

function addon:SetProfile(profileName)
    if type(profileName) ~= "string" or profileName == "" then
        return
    end

    if self.usingAceDB then
        self.db:SetProfile(profileName)
        return
    end

    local savedVariables = self.db.savedVariables
    savedVariables.profiles[profileName] = savedVariables.profiles[profileName] or {}
    savedVariables.profileKeys[self.db.characterKey] = profileName
    self.db.profileName = profileName
    self.db.profile = savedVariables.profiles[profileName]
    self:OnProfileChanged()
end

function addon:CopyProfile(profileName)
    if not profileName or profileName == self:GetCurrentProfile() then
        return
    end

    if self.usingAceDB then
        self.db:CopyProfile(profileName)
        return
    end

    local source = self.db.savedVariables.profiles[profileName]
    if source then
        self.db.profile = CopyTable(source)
        self.db.savedVariables.profiles[self.db.profileName] = self.db.profile
        self:OnProfileChanged()
    end
end

function addon:DeleteProfile(profileName)
    if not profileName or profileName == self:GetCurrentProfile() then
        return
    end

    if self.usingAceDB then
        self.db:DeleteProfile(profileName)
        return
    end

    self.db.savedVariables.profiles[profileName] = nil
    for characterKey, assignedProfile in pairs(self.db.savedVariables.profileKeys) do
        if assignedProfile == profileName then
            self.db.savedVariables.profileKeys[characterKey] = nil
        end
    end
end

function addon:ResetProfile()
    if self.usingAceDB then
        self.db:ResetProfile()
        return
    end

    self.db.profile = {}
    self.db.savedVariables.profiles[self.db.profileName] = self.db.profile
    self:OnProfileChanged()
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

function addon:SetBarsLocked(locked)
    self.db.profile.locked = locked == true
    self:RefreshAll()
end

function addon:SetBarSpacing(value)
    self.db.profile.barSpacing = math.max(0, math.min(20, value))
    self:RefreshAll()
end

function addon:SetGroupGrow(groupId, grow)
    local group = self.db.profile.groups[groupId]
    if not group then
        return
    end

    group.grow = grow == "UP" and "UP" or "DOWN"
    self:BuildGroups()
    self:RefreshAll()
end

function addon:SetGroupChain(groupId, parentId)
    local group = self.db.profile.groups[groupId]
    if not group then
        return
    end

    group.anchorTo = parentId or nil
    self:BuildGroups()
    self:RefreshAll()
end

function addon:SetTargetGroupMaxBars(groupId, value)
    local group = self.db.profile.groups[groupId]
    if not group or group.unit ~= "target" then
        return
    end

    group.maxBars = math.max(1, math.min(40, value))
    self:RefreshAll()
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
