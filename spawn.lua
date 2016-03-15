-- Get the addon namespace
local addon, ns = ...

local u = {}
local function Spawn(unit)
    local object = oUF:Spawn(unit, 'oUF_Zoey'..unit)
    u[unit:lower()] = object
    return object
end

local function SpawnHeader(name, ...)
    local object = oUF:SpawnHeader('oUF_Zoey'..name, nil, ...)
    u[name:lower()] = object
    return object
end

function ns:SpawnUnitFrames()
    local gap = 12

    -- The frame that all unitframes are attached to.
    local Anchor = CreateFrame('Frame', 'oUF_ZoeyUnitFrameAnchor', UIParent)
    Anchor:SetSize(ns.db.profile.ptgap, 1)
    Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, ns.db.profile.frames_offset)

    ----------------------------------------------------------------------------
    Spawn('Player'):SetPoint('BOTTOMRIGHT', Anchor, 'BOTTOMLEFT', 0, 0)

    Spawn('Pet'):SetPoint('RIGHT', u.player, 'LEFT', -gap, 0)
    Spawn('PetTarget'):SetPoint('BOTTOM', u.pet, 'TOP', 0, gap)

    Spawn('Target'):SetPoint('BOTTOMLEFT', Anchor, 'BOTTOMRIGHT', 0, 0)
    Spawn('TargetTarget'):SetPoint('LEFT', u.target, 'RIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    Spawn('Focus'):SetPoint('BOTTOMRIGHT', u.player, 'TOPLEFT', -100, 75)
    Spawn('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, gap)

    ----------------------------------------------------------------------------
    -- note offset = 130 - frame height
    oUF:SetActiveStyle('Zoey')
    local Party = SpawnHeader('Party', 'party',
        'showParty', true,
        'yOffset', 50,
        'point', 'BOTTOM',
        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',
        'oUF-initialConfigFunction', [[
            self:SetWidth( 135 )
            self:SetHeight( 80 )
        ]]
    )
    Party:SetPoint('BOTTOM', Anchor, 0, 0)
    Party:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)

    SpawnHeader('PartyTargets', 'party',
        'showParty', true,
        'yOffset', 90,
        'point', 'BOTTOM',
        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'target')
            self:SetWidth( 135 )
            self:SetHeight( 40 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 'BOTTOMRIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    SpawnHeader('PartyPets', 'party',
        'showParty', true,
        'yOffset', 110,
        'point', 'BOTTOM',
        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'pet')
            self:SetWidth( 135 )
            self:SetHeight( 20 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 0, -28)

    ----------------------------------------------------------------------------
    oUF:SetActiveStyle('ZoeySquare')
    local Raid = {}
    for i = 1, 8 do
        Raid[i] = SpawnHeader('Raid_g'..i, 'raid',
            'showRaid', true,
            'xOffset', gap/2,
            'point', 'LEFT',
            'groupFilter', tostring(i),
            'oUF-initialConfigFunction', [[
                self:SetWidth( 70 )
                self:SetHeight( 33 )
            ]]
        )

        if i == 1 then
            Raid[i]:SetPoint('BOTTOM', Anchor, 0, 0)
            Raid[i]:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)
        else
            Raid[i]:SetPoint('BOTTOMLEFT', Raid[i - 1], 'TOPLEFT', 0, gap)
        end
    end

    ----------------------------------------------------------------------------
    oUF:SetActiveStyle('Zoey')
    local Boss = {}
    for i = 1, MAX_BOSS_FRAMES do
        Boss[i] = Spawn('Boss'..i)

        if i == 1 then
            Boss[i]:SetPoint('BOTTOMLEFT', u.target, 'TOPRIGHT', 100, 75)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
        end
    end
end
