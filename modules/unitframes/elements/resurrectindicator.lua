local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreateResurrectIndicator(object)
    object.ResurrectIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
end

function Module.ConfigureResurrectIndicator(object)
    local db = object.db.resurrectIndicator
    local element = object.ResurrectIndicator

    -- Set the size to the parent size.
    local size = db.size == -1 and object.db.height or db.size

    element:SetSize(size, size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('ResurrectIndicator')
    else
        object:DisableElement('ResurrectIndicator')
    end
end
