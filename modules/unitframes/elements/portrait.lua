local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local L = Addon.L

function Module.GetPortraitOptions()
    return {
        type = 'group',
        name = L['Portrait'],
        args = {
            enabled = {
                order = 1,
                type = 'toggle',
                name = L['Enable'],
            },
            size = {
                order = 10,
                type = 'range',
                name = L['Size'],
                desc = L['The size of the portrait frame.'],
                min = 1, max = 100, step = 1, softMax = 50
            },
            position = { disabled = true,
                order = 11,
                type = 'select',
                name = L['Position'],
                desc = L['Where is the portrait positioned.'],
                values = {
                },
            },
        },
    }
end

--[[ TODO:
    currently hard coded to be a bar thats half the frame height

    give more options:
        trasparent on entire object/health/power
        3D ICON on the left/right side, (force it to be a square?)
--]]
function Module.CreatePortrait(object)
    local element = CreateFrame('PlayerModel', nil, object)
    object.Portrait = element
end

function Module.ConfigurePortrait(object)
    local db = object.db
    local element = object.Portrait

    if db.portrait.enabled then
        object:EnableElement('Portrait')

        element:ClearAllPoints()
        element:SetPoint('TOP', 0, -1)
        element:SetPoint('LEFT', 1, 0)
        element:SetPoint('RIGHT', -2, 0)
        element:SetAlpha(0.4)

        element:SetHeight(math.max(1, math.min(db.portrait.size or 1, db.height - 5)) - 1.5)

        -- Reanchor the healthbar
        object.Health:SetPoint('TOP', element, 'BOTTOM', 0, -1.5)
    else
        object:DisableElement('Portrait')
    end
end
