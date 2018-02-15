local ADDON_NAME, Addon = ...

local MODULE_NAME = 'WorldMap'
local Module = Addon:NewModule(MODULE_NAME, 'AceHook-3.0')

local L = Addon.L

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {

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
    self:SecureHook("WorldMap_ToggleSizeUp", "SetLargeWorldMap")
    BlackoutWorld:SetTexture(nil)

    if WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE then
        self:SetLargeWorldMap()
    end
end

--------------------------------------------------------------------------------
function Module:SetLargeWorldMap()
	if InCombatLockdown() then return end

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
