local ADDON_NAME, Addon = ...
local Module = Addon:NewModule('UnitframesTest', 'AceEvent-3.0', 'AceHook-3.0')

local Unitframes = Addon:GetModule('Unitframes')

local testActive = false

function Module:ForceShowUnit(object)
    object:Disable()

    if not object.isForced then
        object.oldUnit = object.unit
        object.oldOnUpdate = object:GetScript('OnUpdate')

        object.unit = 'player'
        object:SetScript('OnUpdate', nil)
    end

    object:Enable(true)
    object:Show()
    object:Update()

    object.isForced = true
end
function Module:UnForceShowUnit(object)
    -- if the object isnt forced, nothing for us to do.
    if not object.isForced then return end

    object:Disable()

    object.unit = object.oldUnit
    object:SetScript('OnUpdate', object.oldOnUpdate)

    object:Enable()
    object:Show()
    object:Update()

    object.oldUnit = nil
    object.oldOnUpdate = nil
    object.isForced = nil
end

-- This is a post-hook so other groups and units are created
local function holderUpdateHook(holder)
    Module.hooks[holder].Update(holder)

    local db = holder.db
    local maxUnits = db.raidWideSorting and min(db.numGroups * 5, MAX_RAID_MEMBERS) or 5

    -- loop over child headers
    for i=1, #holder do
        local header = holder[i]

        -- TODO: This may need to change if people are in the group.
        -- IDEA: Use RegisterEvent('GROUP_ROSTER_UPDATE') to keep track of
        --   the number of units in the group and change 'startingIndex' to make
        --   sure all real units show, and the rest are filled up with 'player'

        -- Setting startingIndex, encourages SecureGroupheaders to create the buttons
        header:SetAttribute('startingIndex', -maxUnits + 1)

        for i=1, #header do
            local object = header[i]
            Module:ForceShowUnit(object)

            -- Template child frames support
            if object.hasChildren then -- hasChildren and isChild come from oUF initObject
                for i, child in pairs({object:GetChildren()}) do
                    if child.isChild then Module:ForceShowUnit(child) end
                end
            end
        end

        -- Encourage SecureGroupheaders to update the header
        header:SetAttribute('ForceUpdate')
    end
end
function Module:ForceShowHolder(holder)
    -- if no holder or holder is already forced. Return early
    if not holder or holder.isForced then return end

    RegisterStateDriver(holder, 'visibility', 'show')

    -- Hook the holder's Update method, so if options change (number of groups)
    -- all new child units are shown and updated.
    Module:RawHook(holder, 'Update', holderUpdateHook)

    holder:Update()
    holder.isForced = true
end
function Module:UnForceShowHolder(holder)
    -- if no holder or holder isnt forced. return early
    if not holder or not holder.isForced then return end

    RegisterStateDriver(holder, 'visibility', holder.visibility)

    Module:Unhook(holder, 'Update')

    for i=1, #holder do
        local header = holder[i]

        header:SetAttribute('startingIndex', nil)
        for i=1, #header do
            local object = header[i]
            self:UnForceShowUnit(object)

            -- Template child frames support
            if object.hasChildren then -- hasChildren and isChild come from oUF initObject
                for i, child in pairs({object:GetChildren()}) do
                    if child.isChild then self:UnForceShowUnit(child) end
                end
            end
        end
    end

    holder:Update()
    holder.isForced = nil
end


function Module:EnableTest(type)
    if InCombatLockdown() then return self:Print('Can\'t toggle test frames while in combat.') end
    if testActive == true then return self:Print('Test frames already active.') end

    for _, unit in pairs(Unitframes.units) do
        self:ForceShowUnit(unit)
    end
    for _, groupHolder in pairs(Unitframes.groups) do
        for i=1, #groupHolder do
            self:ForceShowUnit(groupHolder[i])
        end
    end

    if type == nil or type == 'party' then
        self:ForceShowHolder(ZoeyUI_Party)
    elseif type == 'raid' then
        self:ForceShowHolder(ZoeyUI_Raid)
    end

    testActive = true
    self:Print('Test frames are now active.')

    -- Disable the test if we enter combat.
    Module:RegisterEvent('PLAYER_REGEN_DISABLED', 'DisableTest', true)
end

function Module:DisableTest(dueToCombat)
    if testActive == false then return self:Print('Test frames are not active.') end
    for _, unit in pairs(Unitframes.units) do
        self:UnForceShowUnit(unit)
    end
    for _, groupHolder in pairs(Unitframes.groups) do
        for i=1, #groupHolder do
            self:UnForceShowUnit(groupHolder[i])
        end
    end
    for _, headerHolder in pairs(Unitframes.headers) do
        self:UnForceShowHolder(headerHolder)
    end

    testActive = false

    if dueToCombat then
        self:Print('|cFFFF0000Entering Combat|r disabling test frames.')
    else
        self:Print('Test frames are now inactive.')
    end

    -- Frames are disabled, stop watching the event
    Module:UnregisterEvent('PLAYER_REGEN_DISABLED')
end

-- Register our UF test command
Module:RegisterSlashCommand('test', function(input)
    local type = Module:GetArgs(input, 1)

    if not testActive then
        Module:EnableTest(type)
    elseif testActive then
        Module:DisableTest()
    end
end)
