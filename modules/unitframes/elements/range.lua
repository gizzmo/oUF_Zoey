local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')
local ElementName = IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'

local L = Addon.L
local CreateStatusBar = Module.CreateStatusBar

function Module.GetRangeOptions()
    return {
        type = 'group',
        name = 'Range',
        args = {

        },
    }
end

function Module.CreateRange(object)
    object[ElementName] = {}
end

function Module.ConfigureRange(object)
    local db = object.db
    local element = object[ElementName]

    element.outsideAlpha = db.rangeAlpha
end
