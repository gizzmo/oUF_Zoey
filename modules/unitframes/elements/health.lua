local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local ACD = LibStub('AceConfigDialog-3.0')

local L = Addon.L
local CreateStatusBar = Module.CreateStatusBar

function Module.GetHealthOptions()
    return {
        type = 'group',
        name = 'Health',
        args = {
            reverseFill = {
                order = 1,
                type = 'toggle',
                name = L['Reverse Fill'],
                desc = L['Change the direction the healthbar moves when filling.'],
            },
            orientation = {
                type = 'select',
                order = 1,
                name = L["Statusbar Fill Orientation"],
                values = {
                    HORIZONTAL = L["Horizontal"],
                    VERTICAL = L["Vertical"],
                },
                hidden = function(info) -- Hide if not in 'headers' table
                    return not Module.headers[info.handler.name]
                end
            },
            colorConfigureButton = {
                order = 2,
                name = L["Coloring"],
                desc = L["This opens the UnitFrames Color settings. These settings affect all unitframes."],
                type = 'execute',
                func = function() ACD:SelectGroup('ZoeyUI', 'Unitframes', 'generalGroup', 'colorsGroup') end,
            },
        },
    }
end

--[[ TODO:

--]]
local function UpdateColor(self, event, unit)
    local db = Module.db.profile.colors
    local element = self.Health
    local r, g, b, t

    if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        t = self.colors.tapped
    elseif element.disconnected then
        t = self.colors.disconnected
    elseif db.health_class and UnitIsPlayer(unit) and not db.health_force_reaction then
        local _, class = UnitClass(unit)
        t = self.colors.class[class]
    elseif db.health_class and UnitReaction(unit, 'player') then
        t = self.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.health_by_value then
        r, g, b = self.ColorGradient(element.cur, element.max, unpack(self.colors.smooth))
    else
        t = self.colors.health
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        element:SetStatusBarColor(r, g, b)

        local bg = element.bg
        if bg then
            local t

            if db.use_health_backdrop_dead and UnitIsDeadOrGhost(unit) then
                t = db.health_backdrop_dead
                r, g, b = t[1], t[2], t[3]
            elseif db.health_backdrop_class then
                local t
                if UnitIsPlayer(unit) then
                    local _, class = UnitClass(unit)
                    t = self.colors.class[class]
                elseif UnitReaction(unit, 'player') then
                    t = self.colors.reaction[UnitReaction(unit, 'player')]
                end

                if t then
                    r, g, b = t[1], t[2], t[3]
                end
            elseif db.health_backdrop_custom then
                t = db.health_backdrop
                r, g, b = t[1], t[2], t[3]
            else -- defaults to a multiplier
                local mult = 0.4
                r, g, b = r * mult, g * mult, b * mult
            end

            bg:SetVertexColor(r, g, b)
        end
    end
end

function Module.CreateHealth(object)
    local element = CreateStatusBar(object)
    element.UpdateColor = UpdateColor

    object.Health = element
end

function Module.ConfigureHealth(object)
    local db = object.db
    local element = object.Health

    -- Anchoring
    element:ClearAllPoints()
    element:SetPoint('TOP', 0, -1)
    element:SetPoint('LEFT', 1, 0)
    element:SetPoint('RIGHT', -1, 0)
    element:SetPoint('BOTTOM', 0, 1)

    -- Not every frame will have this option.
    element:SetOrientation(db.health.orientation or 'HORIZONTAL')
    element:SetReverseFill(db.health.reverseFill)
end
