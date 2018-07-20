local ADDON_NAME, Addon = ...

local MODULE_NAME = 'WorldMap'
local Module = Addon:NewModule(MODULE_NAME, 'AceHook-3.0')

local L = Addon.L

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {
        smallerWorldMap = true,
        alphaWhileMoving = 0.35,
        fadeWhileMoving = true,
    }
}

--------------------------------------------------------------------- Options --
function Module.get_module_options()
    return {
        type = 'group',
        name = L['WorldMap'],
        args = {

        }
    }
end

--------------------------------------------------------------------------------
function Module:OnInitialize()
    self.db = Addon.db:RegisterNamespace(MODULE_NAME, defaultDB)
end

function Module:OnEnable()
    if self.db.profile.smallerWorldMap then
        WorldMapFrame.BlackoutFrame.Blackout:SetTexture(nil)
        WorldMapFrame.BlackoutFrame:EnableMouse(false)

        self:SecureHook(WorldMapFrame, 'Maximize', 'SetLargeWorldMap')
        self:SecureHook(WorldMapFrame, 'Minimize', 'SetSmallWorldMap')
        self:SecureHook(WorldMapFrame, 'SynchronizeDisplayState')
        self:SecureHook(WorldMapFrame, 'UpdateMaximizedSize')

        self:SecureHookScript(WorldMapFrame, 'OnShow', function()
            if WorldMapFrame:IsMaximized() then
                self:SetLargeWorldMap()
                self:UpdateMaximizedSize()
            else
                self:SetSmallWorldMap()
                self:UpdateMaximizedSize()
            end

            self:Unhook(WorldMapFrame, 'OnShow')
        end)
    end

    -- Set alpha used when moving
    WORLD_MAP_MIN_ALPHA = self.db.profile.alphaWhileMoving
    SetCVar("mapAnimMinAlpha", self.db.profile.alphaWhileMoving)

    -- Enable/Disable map fading when moving
    SetCVar("mapFade", (self.db.profile.fadeMapWhenMoving == true and 1 or 0))
end

local tooltips = {
    WorldMapTooltip,
    WorldMapCompareTooltip1,
    WorldMapCompareTooltip2,
    WorldMapCompareTooltip3
}

local smallerMapScale = 0.7

function Module:SetLargeWorldMap()
    WorldMapFrame:SetParent(UIParent)
    WorldMapFrame:SetScale(1)
    WorldMapFrame.ScrollContainer.Child:SetScale(smallerMapScale)

    if WorldMapFrame:GetAttribute('UIPanelLayout-area') ~= 'center' then
        SetUIPanelAttribute(WorldMapFrame, "area", "center");
    end

    if WorldMapFrame:GetAttribute('UIPanelLayout-allowOtherPanels') ~= true then
        SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
    end

    WorldMapFrame:OnFrameSizeChanged()
    if WorldMapFrame:GetMapID() then
        WorldMapFrame.NavBar:Refresh()
    end

    for _, tt in pairs(tooltips) do
        if _G[tt] then _G[tt]:SetFrameStrata("TOOLTIP") end
    end
end

function Module:UpdateMaximizedSize()
    local width, height = WorldMapFrame:GetSize()
    local magicNumber = (1 - smallerMapScale) * 100
    WorldMapFrame:SetSize((width * smallerMapScale) - (magicNumber + 2), (height * smallerMapScale) - 2)
end

function Module:SynchronizeDisplayState()
    if WorldMapFrame:IsMaximized() then
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("TOP", UIParent, "TOP", 0, -94)
    end
end

function Module:SetSmallWorldMap()
    if not WorldMapFrame:IsMaximized() then
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -94)
    end
end
