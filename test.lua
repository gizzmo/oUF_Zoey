local addon, ns = ...

local RealUnitAura = UnitAura
local function FakeUnitAura()
    -- todo: give back random aura
    return "Hunter's Mark", "", "Interface\\Icons\\Ability_Hunter_SniperShot", 0, "", 0, 0, "player"
end

local function toggle_unit(f)
    if not f.__realunit then
        -- Set the unit to 'player' and show it
        f.__realunit = f:GetAttribute("unit") or f.unit
        f:SetAttribute("unit", "player")
        f.unit = "player"
        f:Show()

        -- Refresh auras
        if f.UNIT_AURA then
            f:UNIT_AURA("UNIT_AURA", 'player')
        end
    else
        -- Reset all units and cleanup
        f:SetAttribute("unit", f.__realunit)
        f.unit = f.__realunit
        f.__realunit = nil
        f:Hide()
    end
end

local function toggle_unitaura()
    if UnitAura == RealUnitAura then
        UnitAura = FakeUnitAura
    else
        UnitAura = RealUnitAura
    end
end

SLASH_OUF_ZOEY1 = '/zoey'
SlashCmdList.OUF_ZOEY = function(param)

    if param == 'test' then
        toggle_unitaura()
        for _,v in next, oUF.objects do
            toggle_unit(v)
        end
    else
        print("No param given.")
    end

end
