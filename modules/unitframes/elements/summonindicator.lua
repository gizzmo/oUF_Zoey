local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreateSummonIndicator(object)
    object.SummonIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
end

function Module.ConfigureSummonIndicator(object)
    local db = object.db.summonIndicator
    local element = object.SummonIndicator

    -- Set the size to the parent size.
    local size = db.size == -1 and object.db.height or db.size

    element:SetSize(size, size)

    element:ClearAllPoints()
    element:SetPoint('CENTER', object.Overlay, db.anchorPoint, db.xOffset, db.yOffset)

    if db.enabled then
        object:EnableElement('SummonIndicator')
    else
        object:DisableElement('SummonIndicator')
    end
end
