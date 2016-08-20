-- Get the addon namespace
local addon, ns = ...

local gap = 12              -- gap between units
local ptgap = 234           -- gap between player and target
local frames_offset = 300   -- offset from bottom of UIParent

-- The frame that all unitframes are attached to.
local Anchor = CreateFrame('Frame', 'oUF_ZoeyUnitFrameAnchor', UIParent)
Anchor:SetSize(ptgap, 1)
Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, frames_offset)

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
function ns:SpawnUnitFrames()

    Spawn('Player'):SetPoint('BOTTOMRIGHT', Anchor, 'BOTTOMLEFT', 0, 0)

    Spawn('Pet'):SetPoint('RIGHT', u.player, 'LEFT', -gap, 0)
    Spawn('PetTarget'):SetPoint('BOTTOM', u.pet, 'TOP', 0, gap)

    Spawn('Target'):SetPoint('BOTTOMLEFT', Anchor, 'BOTTOMRIGHT', 0, 0)
    Spawn('TargetTarget'):SetPoint('LEFT', u.target, 'RIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    Spawn('Focus'):SetPoint('BOTTOM', u.pet, 'TOPLEFT', -15, 75)
    Spawn('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, gap)

    ----------------------------------------------------------------------------
    -- note offset = 130 - frame height
    oUF:SetActiveStyle('Zoey')
    SpawnHeader('Party', 'party',
        'showParty', true,
        'yOffset', 50,
        'point', 'BOTTOM',
        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',
        'oUF-initialConfigFunction', [[
            self:SetWidth( 135 )
            self:SetHeight( 80 )
        ]]
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', gap, 240)

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
    SpawnHeader('Raid', 'raid',
        'showRaid', true,
        'xOffset', gap/2,
        'point', 'LEFT',
        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',
        'maxColumns', 8,
        'unitsPerColumn', 5,
        'columnSpacing', gap/2,
        'columnAnchorPoint', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetWidth( 65 )
            self:SetHeight( 40 )
        ]]
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)

    ----------------------------------------------------------------------------
    oUF:SetActiveStyle('Zoey')
    local Boss, Arena = {},{}
    for i = 1, 5 do
        Boss[i] = Spawn('Boss'..i)
        Arena[i] = Spawn('Arena'..i)

        if i == 1 then
            Boss[i]:SetPoint('BOTTOM', u.focustarget, 'TOP', 0, 25)
            Arena[i]:SetPoint('BOTTOM', u.focustarget, 'TOP', 0, 25)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
            Arena[i]:SetPoint('BOTTOM', Arena[i - 1], 'TOP', 0, gap)
        end
    end
end
