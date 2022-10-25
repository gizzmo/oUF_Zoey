local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local function CornerOverride(object)
    local element = object.GroupRoleIndicator

    local role = UnitGroupRolesAssigned(object.unit)
    if role == 'TANK' then
        element:SetBackdropColor(1, 1, 1, 1)
        element:Show()
    elseif role == 'HEALER' then
        element:SetBackdropColor(0, 1, 0, 1)
        element:Show()
    else
        element:Hide()
    end
end

function Module.CreateGroupRoleIndicator(object)
    object.GroupRoleIndicator_Texture = object.Overlay:CreateTexture(nil, 'OVERLAY')

    object.GroupRoleIndicator_Corner = Module.CreateCornerIndicator(object.Overlay)
    object.GroupRoleIndicator_Corner.Override = CornerOverride
end

function Module.ConfigureGroupRoleIndicator(object)
    local db = object.db.grouproleIndicator
    local element

    -- Figure out which indicator style to show, and hide the other
    if db.simple then
        element = object.GroupRoleIndicator_Corner
        object.GroupRoleIndicator_Texture:Hide()
    else
        element = object.GroupRoleIndicator_Texture
        object.GroupRoleIndicator_Corner:Hide()
    end

    -- Assign the indicator, so oUF knows about it.
    object.GroupRoleIndicator = element

    element:SetSize(db.size, db.size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('GroupRoleIndicator')
    else
        object:DisableElement('GroupRoleIndicator')
    end
end
