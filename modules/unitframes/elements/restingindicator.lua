local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreateRestingIndicator(object)
    object.RestingIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
end

function Module.ConfigureRestingIndicator(object)
    local db = object.db.restingIndicator
    local element = object.RestingIndicator

    element:SetSize(db.size, db.size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('RestingIndicator')
    else
        object:DisableElement('RestingIndicator')
    end
end
