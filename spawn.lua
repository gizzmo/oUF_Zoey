-- Get the addon namespace
local addon, ns = ...

local gap = 12              -- gap between units
local ptgap = 320           -- gap between player and target
local frames_offset = 245   -- offset from bottom of UIParent

-- The frame that all unitframes are attached to.
local Anchor = CreateFrame('Frame', 'oUF_ZoeyUnitFrameAnchor', UIParent)
Anchor:SetSize(ptgap, 1)
Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, frames_offset)

--------------------------------------------------------------------------------

local function generateName(string)
    return 'oUF_Zoey'..string:lower()
        :gsub('^%l', string.upper)
        :gsub('p(ets)', 'P%1') -- for PartyPets
        :gsub('t(arget)', 'T%1')
end

local u = {}
local function Spawn(unit)
    local unit = unit:lower()
    local object = oUF:Spawn(unit, generateName(unit))

    u[unit] = object
    return object
end

local function SpawnHeader(unit, ...)
    local unit = unit:lower()
    local object = oUF:SpawnHeader(generateName(unit), nil, ...)

    u[unit] = object
    return object
end

--------------------------------------------------------------------------------
function ns:SpawnUnitFrames()

    oUF:SetActiveStyle('Zoey')
    Spawn('Player'):SetPoint('BOTTOMRIGHT', Anchor, 'BOTTOMLEFT', 0, 0)
    Spawn('Target'):SetPoint('BOTTOMLEFT', Anchor, 'BOTTOMRIGHT', 0, 0)
    Spawn('Focus'):SetPoint('RIGHT', u.player, 'LEFT', -gap*2, 0)
    Spawn('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, gap)

    oUF:SetActiveStyle('ZoeyThin')
    Spawn('Pet'):SetPoint('TOPLEFT', u.player, 'BOTTOMLEFT', 0, -gap)
    Spawn('PetTarget'):SetPoint('TOP', u.pet, 'BOTTOM', 0, -gap)
    Spawn('TargetTarget'):SetPoint('TOPRIGHT', u.target, 'BOTTOMRIGHT', 0, -gap)
    Spawn('TargetTargetTarget'):SetPoint('TOPRIGHT', u.targettarget, 'BOTTOMRIGHT', 0, -gap)

    ----------------------------------------------------------------------------
    local hgap = 130
    oUF:SetActiveStyle('Zoey')
    SpawnHeader('Party', 'party',
        'showParty', true,
        'yOffset', (hgap - 80),
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
        'yOffset', (hgap - 40),
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
        'yOffset', (hgap - 20),
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
            Boss[i]:SetPoint('BOTTOM', u.focustarget, 'TOP', 0, gap*3)
            Arena[i]:SetPoint('BOTTOM', u.focustarget, 'TOP', 0, gap*3)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
            Arena[i]:SetPoint('BOTTOM', Arena[i - 1], 'TOP', 0, gap)
        end
    end
end
