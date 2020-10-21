local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local function UpdateColor(self, event, unit)
    local db = Module.db.profile.colors
    local Power = self.Power
    local parent = Power.__owner
    local r, g, b, t

    if db.power_class and UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        t = parent.colors.class[class]
    elseif db.power_class and UnitReaction(unit, 'player') then
        t = parent.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.power_custom then
        t = parent.colors.power.custom
    else
        local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

        t = parent.colors.power[ptoken]
        if not t then
            if altR then
                r, g, b = altR, altG, altB

                if r > 1 or g > 1 or b > 1 then
                    -- BUG: As of 7.0.3, altR, altG, altB may be in 0-1 or 0-255 range.
                    r, g, b = r / 255, g / 255, b / 255
                end
            else
                t = parent.colors.power[ptype]
            end
        end
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        Power:SetStatusBarColor(r, g, b)

        local bg = Power.bg
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

function Module.CreatePower(object, height)
    local height = height or 10

    local element = CreateStatusBar(object)
    element:SetHeight(height)
    element:SetPoint('LEFT', 1, 0)
    element:SetPoint('RIGHT', -1, 0)
    element:SetPoint('BOTTOM', 0, 1)
    element.frequentUpdates = true
    element.UpdateColor = UpdateColor
    element.PostUpdate = PostUpdate

    object.Power = element

    -- Reanchor the health bar.
    object.Health:SetPoint('BOTTOM', object.Power, 'TOP', 0, 1)
end
