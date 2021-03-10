local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local ACD = LibStub('AceConfigDialog-3.0')

local L = Addon.L
local CreateStatusBar = Module.CreateStatusBar

function Module.GetHealthOptions()
    return {
        type = 'group',
        name = 'Health',
        inline = true,
        get = function(info)
            return info.handler.object.db.health[info[#info]]
        end,
        set = function(info, value)
            info.handler.object.db.health[info[#info]] = value
            info.handler.object:Update()
        end,
        args = {
            fillDirection = {
    			type = 'select',
    			order = 1,
    			name = L["Statusbar Fill Direction"],
    			desc = L["Direction the health bar moves when filling."],
    			values = {
                    BOTTOM_TOP = L['Bottom to Top'],
                    LEFT_RIGHT = L['Left to Right'],
                    TOP_BOTTOM = L['Top to Bottom'],
                    RIGHT_LEFT = L['Right to Left'],
    			},
                sorting = {'BOTTOM_TOP', 'LEFT_RIGHT', 'TOP_BOTTOM', 'RIGHT_LEFT'}
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
    local Health = self.Health
    local parent = Health.__owner
    local r, g, b, t

    if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        t = parent.colors.tapped
    elseif Health.disconnected then
        t = parent.colors.disconnected
    elseif db.health_class and UnitIsPlayer(unit) and not db.health_force_reaction then
        local _, class = UnitClass(unit)
        t = parent.colors.class[class]
    elseif db.health_class and UnitReaction(unit, 'player') then
        t = parent.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.health_by_value then
        r, g, b = parent.ColorGradient(element.cur, element.max, unpack(parent.colors.smooth))
    else
        t = parent.colors.health
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        Health:SetStatusBarColor(r, g, b)

        local bg = Health.bg
        if bg then
            local t

            if db.use_health_backdrop_dead and UnitIsDeadOrGhost(unit) then
                t = db.health_backdrop_dead
                r, g, b = t[1], t[2], t[3]
            elseif db.health_backdrop_class then
                local t
                if UnitIsPlayer(unit) then
                    local _, class = UnitClass(unit)
                    t = parent.colors.class[class]
                elseif UnitReaction(unit, 'player') then
                    t = parent.colors.reaction[UnitReaction(unit, 'player')]
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
    element:SetPoint('TOP', 0, -1)
    element:SetPoint('LEFT', 1, 0)
    element:SetPoint('RIGHT', -1, 0)
    element:SetPoint('BOTTOM', 0, 1)
    element.UpdateColor = UpdateColor

    object.Health = element
end

function Module.ConfigureHealth(object)
    local db = object.db
    local health = object.Health

    local fill = db.health.fillDirection

    local orientation = (fill == 'TOP_BOTTOM' or fill == 'BOTTOM_TOP')
    local reverseFill = (fill == 'TOP_BOTTOM' or fill == 'RIGHT_LEFT')

    health:SetOrientation(orientation and 'VERTICAL' or 'HORIZONTAL')
    health:SetReverseFill(reverseFill)
end
