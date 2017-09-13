local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local oUF = Addon.oUF

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

-- Register our UF test command
Module:RegisterSlashCommand('test', function(input)
    local type = Module:GetArgs(input, 1)

    -- Always start with them being deactive
    for _, unit in pairs(oUF.objects) do
        toggleUnitFrame(unit, false)
    end

    toggleHeaderFrame(ZoeyUI_Party, false)
    toggleHeaderFrame(ZoeyUI_PartyPets, false)
    toggleHeaderFrame(ZoeyUI_PartyTargets, false)
    toggleHeaderFrame(ZoeyUI_Raid, false)

    -- Then, if we want ot enable it, activate them
    if not testActive then
        if InCombatLockdown() then return print('ZoeyUI: Can\'t toggle test frames in combat.')end
        print('ZoeyUI: Test frames are active')

        for _, unit in pairs(oUF.objects) do
            toggleUnitFrame(unit, true)
        end

        if type==nil or type == 'group' then
            toggleHeaderFrame(ZoeyUI_Party, true)
            toggleHeaderFrame(ZoeyUI_PartyPets, true)
            toggleHeaderFrame(ZoeyUI_PartyTargets, true)
        elseif type == 'raid' then
            toggleHeaderFrame(ZoeyUI_Raid, true)
        end

    elseif testActive then
        print('ZoeyUI: Test frames are inactive')
    end

    testActive = not testActive
end)
