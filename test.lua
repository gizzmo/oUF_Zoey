local addon, ns = ...

local RealUnitAura = UnitAura
local function FakeUnitAura(unit, index, rank, filter)
    -- if a aura really does exist, show that one.
    local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = RealUnitAura(unit, index, rank, filter)
    if name then
        return name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
    end

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
        if (f.Auras) then f.Auras:ForceUpdate() end
        if (f.Buffs) then f.Buffs:ForceUpdate() end
        if (f.Defuffs) then f.Defuffs:ForceUpdate() end

        f.old_OnUpdate = f:GetScript("OnUpdate")
        f:SetScript("OnUpdate", nil)

        UnregisterUnitWatch(f)
        RegisterUnitWatch(f, true)

    else
        -- Reset all units and cleanup
        f:SetAttribute("unit", f.__realunit)
        f.unit = f.__realunit
        f.__realunit = nil
        f:Hide()

        f:SetScript("OnUpdate", f.old_OnUpdate)
        f.old_OnUpdate = nil

        UnregisterUnitWatch(f) -- Reset the fect
        RegisterUnitWatch(f)

        -- f:UpdateAllElements("OnShow")
    end
end

local function ToggleHeader(f)
    -- /run SecureStateDriverManager:SetAttribute("setframe", oUF_ZoeyRaid10_g1)  print(SecureStateDriverManager:GetAttribute("setstate"):gsub("state%-visibility%s", ""))
    if not f.oldstate_driver then
        -- This is just a "hack" to get the old visibility attribute
        SecureStateDriverManager:SetAttribute('setframe', f)
        f.oldstate_driver = SecureStateDriverManager:GetAttribute("setstate"):gsub("state%-visibility%s", "")
        RegisterAttributeDriver(f, 'state-visibility', 'show')

        -- Setting the starting index to -3, so we have three frames: -3, -2, -1, 0
        f:SetAttribute("startingIndex", 3)

        for i = 1, f:GetNumChildren() do
            local obj = select(i, f:GetChildren())
            toggle_unit(obj)
        end
    else
        -- Reset the visibility (bug: doesnt really set it)
        RegisterAttributeDriver(f, 'state-visibility', f.oldstate_driver)
        f.oldstate_driver = nil

        -- Setting it to default (1)
        f:SetAttribute("startingIndex", nil)

        for i = 1, f:GetNumChildren() do
            local obj = select(i, f:GetChildren())
            toggle_unit(obj)
        end

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
    local param1, param2 = string.split(' ', param)

    if param1 == 'test' then
        toggle_unitaura()
        for _,v in next, oUF.objects do
            toggle_unit(v)
        end

        -- Still a bit buggy.
        -- if not param2 or param == 'party' then
        --     ToggleHeader(oUF_ZoeyParty)
        --     ToggleHeader(oUF_ZoeyPartyTargets)
        --     ToggleHeader(oUF_ZoeyPartyPets)
        -- elseif param2 == 'raid' or param2 == 'raid10' then
        --     ToggleHeader(oUF_ZoeyRaid10_g1)
        --     ToggleHeader(oUF_ZoeyRaid10_g2)
        -- elseif param2 == 'raid25' then
        --     ToggleHeader(oUF_ZoeyRaid25_g1)
        --     ToggleHeader(oUF_ZoeyRaid25_g2)
        --     ToggleHeader(oUF_ZoeyRaid25_g3)
        --     ToggleHeader(oUF_ZoeyRaid25_g4)
        --     ToggleHeader(oUF_ZoeyRaid25_g5)
        -- elseif param2 == 'raid40' then
        --     ToggleHeader(oUF_ZoeyRaid40_g1)
        --     ToggleHeader(oUF_ZoeyRaid40_g2)
        --     ToggleHeader(oUF_ZoeyRaid40_g3)
        --     ToggleHeader(oUF_ZoeyRaid40_g4)
        --     ToggleHeader(oUF_ZoeyRaid40_g5)
        --     ToggleHeader(oUF_ZoeyRaid40_g6)
        --     ToggleHeader(oUF_ZoeyRaid40_g7)
        --     ToggleHeader(oUF_ZoeyRaid40_g8)
        -- end
    else
        print("No param given.")
    end

end
