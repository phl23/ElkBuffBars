local addonName, addon = ...

addon.Minimap = addon.Minimap or {}

local Minimap = addon.Minimap

local minimapButton

function Minimap:Create()
    if minimapButton then
        return
    end

    minimapButton = CreateFrame("Button", addonName .. "MinimapButton", MinimapCluster or UIParent)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetMovable(false)

    minimapButton.texture = minimapButton:CreateTexture(nil, "ARTWORK")
    minimapButton.texture:SetAllPoints()
    minimapButton.texture:SetTexture("Interface\\Icons\\Ability_Paladin_BlessedHands")

    minimapButton:SetNormalTexture("Interface\\Icons\\Ability_Paladin_BlessedHands")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    minimapButton:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            addon:ToggleOptions()
        else
            addon:ToggleMainWindow()
        end
    end)

    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(addonName)
        GameTooltip:AddLine("Left click: toggle view")
        GameTooltip:AddLine("Right click: options")
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    minimapButton:SetPoint("TOPLEFT", MinimapCluster or UIParent, "TOPLEFT", 20, -20)
    minimapButton:Show()
    self.button = minimapButton
    self:Refresh()
end

function Minimap:Refresh()
    if not self.button then
        return
    end

    if addon.db and addon.db.profile and addon.db.profile.minimap and addon.db.profile.minimap.hide then
        self.button:Hide()
    else
        self.button:Show()
    end
end

addon.Minimap = Minimap
