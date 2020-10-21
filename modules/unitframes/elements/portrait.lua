local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

--[[ TODO:
    currently hard coded to be a bar thats half the frame height

    give more options:
        trasparent on entire object/health/power
        3D ICON on the left/right side, (force it to be a square?)
--]]
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
