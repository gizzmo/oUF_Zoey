local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

function Module.CreatePortrait(object)
    local element = CreateFrame('PlayerModel', nil, object)
    element:SetHeight((object:GetHeight() / 2) - 1.5)
    element:SetPoint('TOP', 0, -1)
    element:SetPoint('LEFT', 1, 0)
    element:SetPoint('RIGHT', -2, 0)
    element:SetAlpha(0.4)

    object.Portrait = element

    -- Reanchor the healthbar
    object.Health:SetPoint('TOP', object.Portrait, 'BOTTOM', 0, -1.5)
end
