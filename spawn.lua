-- Get the addon namespace
local addon, ns = ...

--//----------------------------
--// SPAWN UNITS
--//----------------------------
local u = {}
local function SpawnUnit(unit)
    local object = oUF:Spawn(unit, 'oUF_Zoey'..unit)
    u[unit:lower()] = object
    return object
end

local function SpawnHeader(name, visibility, ...)
    local object = oUF:SpawnHeader('oUF_Zoey'..name, nil, visibility, ...)
    u[name:lower()] = object
    return object
end

oUF:Factory(function(oUF)
    local frames_offset, ptgap, gap = ns.config.frames_offset, ns.config.ptgap, 12

    -- The frame that all unitframes are attached to.
    local Anchor = CreateFrame('Frame', 'oUF_ZoeyUnitFrameAnchor', UIParent)
    Anchor:SetSize(ptgap, 1)
    Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, frames_offset)

    --//----------------------------
    -- Player
    SpawnUnit('Player'):SetPoint('BOTTOMRIGHT', Anchor, 'BOTTOMLEFT', 0, 0)

    -- Player Pet
    SpawnUnit('Pet'      ):SetPoint('RIGHT', u.player, 'LEFT', -gap, 0)
    SpawnUnit('PetTarget'):SetPoint('BOTTOM', u.pet, 'TOP', 0, gap)

    -- Targets
    SpawnUnit('Target'      ):SetPoint('BOTTOMLEFT', Anchor, 'BOTTOMRIGHT', 0, 0)
    SpawnUnit('TargetTarget'):SetPoint('LEFT', u.target, 'RIGHT', gap, 0)

    -- Focus
    oUF:SetActiveStyle('ZoeyThin')
    SpawnUnit('Focus'      ):SetPoint('BOTTOMRIGHT', u.player, 'TOPLEFT', -100, 75)
    SpawnUnit('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, gap)

    --//----------------------------
    -- Party -- note: 130 - height = yoffset
    oUF:SetActiveStyle('Zoey')
    local party = SpawnHeader('Party', 'party',
        'showParty', true,
        'yOffset', 50,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetWidth( 135 )
            self:SetHeight( 80 )
        ]]
    )
    party:SetPoint('BOTTOM', Anchor, 0, 0)
    party:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)

    -- Party Targets
    SpawnHeader('PartyTargets', 'party',
        'showParty', true,
        'yOffset', 90,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'target')
            self:SetWidth( 135 )
            self:SetHeight( 40 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 'BOTTOMRIGHT', gap, 0)

    -- Party Pets
    oUF:SetActiveStyle('ZoeyThin')
    SpawnHeader('PartyPets', 'party',
        'showParty', true,
        'yOffset', 110,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'pet')
            self:SetWidth( 135 )
            self:SetHeight( 20 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 0, -28)

    --//----------------------------
    -- Raid Size 1 - 10
    oUF:SetActiveStyle('ZoeyThin')
    local Raid = {}
    for i = 1, 2 do
        Raid[i] = SpawnHeader('Raid10_g'..i,
            'custom [@raid11,exists] hide; [@raid1,exists] show; hide',

            'showRaid', true,
            'yOffset', gap,
            'groupFilter', tostring(i),
            'point', 'BOTTOM',
            'oUF-initialConfigFunction', [[
                self:SetWidth( 135 )
                self:SetHeight( 20 )
            ]]
        )

        if i == 1 then
            Raid[i]:SetPoint('BOTTOM', Anchor, 0, 0)
            Raid[i]:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)
        else
            Raid[i]:SetPoint('BOTTOM', Raid[i - 1], 'TOP', 0, gap)
        end
    end

    -- Raid Size 11 - 40
    oUF:SetActiveStyle('ZoeySquare')
    local Raid = {}
    for i = 1, 8 do
        Raid[i] = SpawnHeader('Raid25_g'..i,
            'custom [@raid11,exists] show; hide ',

            'showRaid', true,
            'xOffset', gap/2,
            'groupFilter', tostring(i),
            'point', 'LEFT',
            'oUF-initialConfigFunction', [[
                self:SetWidth( 53 )
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

    --//----------------------------
    -- Boss Frames
    oUF:SetActiveStyle('Zoey')
    local Boss = {}
    for i = 1, MAX_BOSS_FRAMES do
        Boss[i] = SpawnUnit('boss'..i)

        if i == 1 then
            Boss[i]:SetPoint('BOTTOMLEFT', u.target, 'TOPRIGHT', 100, 75)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
        end
    end
end)
