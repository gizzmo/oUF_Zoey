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
        WorldMapFrame.BlackoutFrame.Blackout:SetTexture()
        WorldMapFrame.BlackoutFrame:EnableMouse(false)

        self:SecureHook(WorldMapFrame, 'Maximize', 'SetLargeWorldMap')
        self:SecureHook(WorldMapFrame, 'Minimize', 'SetSmallWorldMap')
        self:SecureHook(WorldMapFrame, 'SynchronizeDisplayState')
        self:SecureHook(WorldMapFrame, 'UpdateMaximizedSize')
    end

    self:SecureHookScript(WorldMapFrame, 'OnShow', self.WorldMap_FirstShow)
end

function Module:OnDisable()
    -- TODO: find way to disable without reloading the UI.
end

-- TODO: enable this as an option.
local smallerMapScale = 0.7

function Module:SetLargeWorldMap()
    WorldMapFrame:SetParent(UIParent)
    WorldMapFrame:SetScale(1)
    WorldMapFrame.ScrollContainer.Child:SetScale(smallerMapScale)

    WorldMapFrame:OnFrameSizeChanged()
    if WorldMapFrame:GetMapID() then
        WorldMapFrame.NavBar:Refresh()
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
        -- TODO: scale placement to be slightly above center
    end
end

function Module:SetSmallWorldMap()
    if not WorldMapFrame:IsMaximized() then
        WorldMapFrame:ClearAllPoints()
        WorldMapFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -94)
    end
end

function Module:WorldMap_FirstShow()
    local frame = WorldMapFrame
    local maxed = frame:IsMaximized()

    if maxed then -- this needs to be called outside of smallerWorldMap
        frame:UpdateMaximizedSize()
    end

    if Module.db.profile.smallerWorldMap then
        if maxed then
            Module:SetLargeWorldMap()
        else
            Module:SetSmallWorldMap()
        end
    end

    Module:Unhook(frame, 'OnShow') -- only need the first
end
