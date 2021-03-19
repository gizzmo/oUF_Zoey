local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local ACD = LibStub('AceConfigDialog-3.0')

local L = Addon.L
local CreateStatusBar = Module.CreateStatusBar

function Module.GetPowerOptions()
    return {
        type = 'group',
        name = L['Power'],
        args = {
            enabled = {
                type = 'toggle',
                order = 1,
                name = L["Enable"],
            },
            height = {
                order = 2,
                type = 'range',
                name = L['Height'],
                desc = L['The height of the power bar.'],
                min = 1, max = 100, step = 1, softMax = 50
            },
            reverseFill = {
                order = 3,
                type = 'toggle',
                name = L['Reverse Fill'],
                desc = L['Change the direction the powerbar moves when filling.'],
            },
            powerPrediction = {
                type = 'toggle',
                order = 4,
                name = L["Power Prediction"],
                disabled = true,
            },

            configureButton = {
                order = 10,
                name = L["Coloring"],
                desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
                type = 'execute',
                func = function() ACD:SelectGroup('ZoeyUI', 'Unitframes', 'generalGroup', 'colorsGroup') end,
            },
        },
    }
end

--[[ TODO:
    current design is inline

    more options:
        Detatched Power bar? Have it overlay ontop of the lower half of the healthbar
--]]
local function UpdateColor(self, event, unit)
    local db = Module.db.profile.colors
    local element = self.Power
    local r, g, b, t

    if db.power_class and UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        t = self.colors.class[class]
    elseif db.power_class and UnitReaction(unit, 'player') then
        t = self.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.power_custom then
        t = self.colors.power.custom
    else
        local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

        t = self.colors.power[ptoken]
        if not t then
            if altR then
                r, g, b = altR, altG, altB

                if r > 1 or g > 1 or b > 1 then
                    -- BUG: As of 7.0.3, altR, altG, altB may be in 0-1 or 0-255 range.
                    r, g, b = r / 255, g / 255, b / 255
                end
            else
                t = self.colors.power[ptype]
            end
        end
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        element:SetStatusBarColor(r, g, b)

        local bg = element.bg
        if bg then
            local mult = 0.4
            bg:SetVertexColor(r * mult, g * mult, b * mult)
        end
    end
end

local function PostUpdate(Power, unit, cur, min, max)
    -- Fixes the issue of a bar with MinMaxValues of 0,0 showing as empty.
    if max == 0 then Power:SetMinMaxValues(-1, 0) end
end

function Module.CreatePower(object)
    local element = CreateStatusBar(object)
    element.frequentUpdates = true
    element.UpdateColor = UpdateColor
    element.PostUpdate = PostUpdate

    object.Power = element
end

function Module.ConfigurePower(object)
    local db = object.db
    local element = object.Power

    if db.power.enabled then
        -- Enable the oUF Element
        object:EnableElement('Power')

        -- Anchor the element
        element:ClearAllPoints()
        element:SetPoint('LEFT', 1, 0)
        element:SetPoint('RIGHT', -1, 0)
        element:SetPoint('BOTTOM', 0, 1)
        object.Health:SetPoint('BOTTOM', element, 'TOP', 0, 1)

        element:SetHeight(math.max(1, math.min(db.power.height, db.height - 5)))

        element:SetReverseFill(db.power.reverseFill)

    else
        -- Disable the element, we dont need it anymore.
        object:DisableElement('Power')

        -- Undo health reanchoring we did.
        object.Health:SetPoint('BOTTOM', 0, 1)
    end
end
