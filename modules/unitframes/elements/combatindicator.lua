local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreateCombatIndicator(object)
    object.CombatIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
end

function Module.ConfigureCombatIndicator(object)
    local db = object.db.combatIndicator
    local element = object.CombatIndicator

    element:SetSize(db.size, db.size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('CombatIndicator')
    else
        object:DisableElement('CombatIndicator')
    end
end
