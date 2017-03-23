local ADDON_NAME, ns = ...

local function toggleUnitFrame(obj, show)
    if show then
        obj.old_unit = obj.unit
        obj.unit = 'player'

        obj.old_onUpdate = obj:GetScript('OnUpdate')
        obj:SetScript('OnUpdate', nil)

        UnregisterUnitWatch(obj)
        RegisterUnitWatch(obj, true)

        obj:Show()
    elseif obj.old_unit then
        obj.unit = obj.old_unit or obj.unit
        obj.old_unit = nil

        obj:SetScript('OnUpdate', obj.old_OnUpdate)
        obj.old_OnUpdate = nil

        UnregisterUnitWatch(obj)
        RegisterUnitWatch(obj)

        obj:UpdateAllElements('OnShow')
    end
end

local function toggleHeaderFrame(obj, show)
    if show then
        local numMembers = math.max(GetNumSubgroupMembers(LE_PARTY_CATEGORY_HOME) or 0, GetNumSubgroupMembers(LE_PARTY_CATEGORY_INSTANCE) or 0)
        obj:SetAttribute('startingIndex', (numMembers - 3))
        RegisterAttributeDriver(obj, 'state-visibility', 'show')

        for i = 1, obj:GetNumChildren() do
            local child = select(i, obj:GetChildren())
            toggleUnitFrame(child, true)
        end
    else
        obj:SetAttribute('startingIndex', nil)
        RegisterAttributeDriver(obj, 'state-visibility', obj.visibility)

        for i = 1, obj:GetNumChildren() do
            local child = select(i, obj:GetChildren())
            toggleUnitFrame(child, false)
        end
    end
end

local testActive = false
function ns:ToggleTestFrames(type)

    if not testActive then
        if InCombatLockdown() then return print('oUF_Zoey: Can\'t toggle test frames in combat.')end
        print('oUF_Zoey: Test frames are active')

        for _, unit in pairs(oUF.objects) do
            toggleUnitFrame(unit, true)
        end

        if type==nil or type == 'group' then
            toggleHeaderFrame(oUF_ZoeyParty, true)
            toggleHeaderFrame(oUF_ZoeyPartyPets, true)
            toggleHeaderFrame(oUF_ZoeyPartyTargets, true)
        elseif type == 'raid' then
            toggleHeaderFrame(oUF_ZoeyRaid, true)
        end

    elseif testActive then
        print('oUF_Zoey: Test frames are inactive')

        for _, unit in pairs(oUF.objects) do
            toggleUnitFrame(unit, false)
        end

        toggleHeaderFrame(oUF_ZoeyParty, false)
        toggleHeaderFrame(oUF_ZoeyPartyPets, false)
        toggleHeaderFrame(oUF_ZoeyPartyTargets, false)

        toggleHeaderFrame(oUF_ZoeyRaid, false)
    end

    testActive = not testActive

end









--
-- -- This will toggle all uses of UnitAura not just with this addon, unfortunatly.
-- local RealUnitAura = UnitAura
-- local function FakeUnitAura(unit, index, rank, filter)
--     -- if a aura really does exist, show that one.
--     local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = RealUnitAura(unit, index, rank, filter)
--     if name then
--         return name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
--     end
--
--     return 'Hunter\'s Mark', '', 'Interface\\Icons\\Ability_Hunter_SniperShot', 0, '', 0, 0, 'player'
-- end
--
-- local function toggleUnitAura(show)
--     if UnitAura == RealUnitAura then
--         UnitAura = FakeUnitAura
--     else
--         UnitAura = RealUnitAura
--     end
-- end
