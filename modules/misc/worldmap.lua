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
Module.options = {
    type = 'group',
    name = L['WorldMap'],
    args = {

    }
}

-- Register the modules with the Addon
Addon.options.args[MODULE_NAME] = Module.options

--------------------------------------------------------------------------------
function Module:OnInitialize()
    self.db = Addon.db:RegisterNamespace(MODULE_NAME, defaultDB)
end

function Module:OnEnable()
    if self.db.profile.smallerWorldMap then
        self:SecureHook("WorldMap_ToggleSizeUp", "SetLargeWorldMap")
        self:RawHookScript(WorldMapScrollFrame, 'OnMouseWheel', 'FixWorldMapZoom')

        if WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE then
            self:SetLargeWorldMap()
        end
    end

    -- Set alpha used when moving
    WORLD_MAP_MIN_ALPHA = self.db.profile.alphaWhileMoving
    SetCVar("mapAnimMinAlpha", self.db.profile.alphaWhileMoving)

    -- Enable/Disable map fading when moving
    SetCVar("mapFade", (self.db.profile.fadeMapWhenMoving == true and 1 or 0))
end

-- Fixes how the scroll zooming in the fullscreen world map
-- Doesnt really work. Causes taint. May not be possible. Yet
do
    local Real_WorldMapFrame_InWindowedMode = WorldMapFrame_InWindowedMode;
    local function Fake_WorldMapFrame_InWindowedMode()
        return true
    end

    function Module:FixWorldMapZoom(frame, ...)
        WorldMapFrame_InWindowedMode = Fake_WorldMapFrame_InWindowedMode
        self.hooks[frame].OnMouseWheel(frame, ...)
        WorldMapFrame_InWindowedMode = Real_WorldMapFrame_InWindowedMode
    end
end

function Module:SetLargeWorldMap()
    BlackoutWorld:SetTexture(nil)
    WorldMapFrame:SetParent(UIParent)
    WorldMapFrame:EnableKeyboard(false)
    WorldMapFrame:SetScale(1)
    WorldMapFrame:EnableMouse(true)
    WorldMapTooltip:SetFrameStrata("TOOLTIP")
    WorldMapCompareTooltip1:SetFrameStrata("TOOLTIP")
    WorldMapCompareTooltip2:SetFrameStrata("TOOLTIP")

    if WorldMapFrame:GetAttribute('UIPanelLayout-area') ~= 'center' then
        SetUIPanelAttribute(WorldMapFrame, "area", "center");
    end

    if WorldMapFrame:GetAttribute('UIPanelLayout-allowOtherPanels') ~= true then
        SetUIPanelAttribute(WorldMapFrame, "allowOtherPanels", true)
    end

    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    WorldMapFrame:SetSize(1002, 668)
end

-- Wrap so it happens after combat
Module.SetLargeWorldMap = Addon:AfterCombatWrapper(Module.SetLargeWorldMap)
