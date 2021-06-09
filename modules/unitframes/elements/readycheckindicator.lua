local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreateReadyCheckIndicator(object)
    object.ReadyCheckIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
end

function Module.ConfigureReadyCheckIndicator(object)
    local db = object.db.readyCheckIndicator
    local element = object.ReadyCheckIndicator

    -- Set the size to the parent size.
    local size = db.size == -1 and object.db.height or db.size

    element:SetSize(size, size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('ReadyCheckIndicator')
    else
        object:DisableElement('ReadyCheckIndicator')
    end
end
