local ADDON_NAME, Addon = ...
local L = Addon.L

local MODULE_NAME = "Unitframes"
local Module = Addon:NewModule(MODULE_NAME)

Module.units, Module.headers = {},{}

------------------------------------------------------------------ oUF Colors --
oUF.colors.health = {89/255, 89/255, 89/255} -- dark grey
oUF.colors['cast'] =  {
    normal   = {89/255, 89/255, 89/255},      -- dark gray
    success  = {20/255, 208/255, 0/255},      -- green
    failed   = {255/255, 12/255, 0/255},      -- dark red
    safezone = {255/255, 25/255, 0/255, 0.5}, -- transparent red
}
oUF.colors['border'] = {
    normal    = {113/255, 113/255, 113/255}, -- Dark Grey
    rare      = {1, 1, 1},                   -- White
    elite     = {204/255, 177/255, 41/255},  -- Yellow
    rareelite = {41/255,  128/255, 204/255}, -- Blue
    boss      = {136/255, 41/255, 204/255}   -- Purple
}

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {

    }
}

--------------------------------------------------------------------- Options --
Module.options = {
    type = 'group',
    name = L['Unitframes'],
    args = {

    }
}

-- Register the modules with the Addon
Addon.options.args[MODULE_NAME] = Module.options

--------------------------------------------------------------------------------
function Module:CreateFrameName(string)
    local frameName = string:lower() -- start all lower case
        :gsub('^%l', string.upper)   -- set the first character upper case
        :gsub('t(arget)', 'T%1')
        :gsub('p(ets)', 'P%1')

    return ADDON_NAME..'_'..frameName
end

function Module:CreateUnit(unit)
    local unit = unit:lower()

    if not self.units[unit] then
        local object = oUF:Spawn(unit, self:CreateFrameName(unit))

        self.units[unit] = object
    end

    return self.units[unit]
end

function Module:CreateHeader(unit, ...)
    local unit = unit:lower()

    if not self.headers[unit] then
        local object = oUF:SpawnHeader(self:CreateFrameName(unit), nil, ...)

        self.headers[unit] = object
    end

    return self.headers[unit]
end


---------------------------------------------------------------- Core Methods --
function Module:OnInitialize()
    -- Hide the Blizzard Buffs
    BuffFrame:Hide()
    BuffFrame:UnregisterAllEvents()
    TemporaryEnchantFrame:Hide()

    -- Remove tanited items from the right click menu on units
    for _, menu in pairs( UnitPopupMenus ) do
        for i = #menu, 1, -1 do
            local name = menu[ i ]
            if name:match( '^LOCK_%u+_FRAME$' )
            or name:match( '^UNLOCK_%u+_FRAME$' )
            or name:match( '^MOVE_%u+_FRAME$' )
            or name:match( '^RESET_%u+_FRAME_POSITION' )
            or name:match( '^SET_FOCUS' )
            or name:match( '^DISMISS' )
            then
                table.remove( menu, i )
            end
        end
    end

    if not self.Anchor then
        local Anchor = CreateFrame('Frame', self:CreateFrameName('UnitFrameAnchor'), UIParent)
        Anchor:SetSize(320, 1) -- width is the gap between target and player frames
        Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 245)
        self.Anchor = Anchor
    end

    -- Register our UF test command
    self:RegisterSlashCommand('test', function()
        self.ToggleTestFrames()
    end)

    -- Regsitering our style functions
    oUF:RegisterStyle('Zoey', function(...) self:ConstructStyle(...) end)
    oUF:RegisterStyle('ZoeyThin', function(...) self:ConstructStyle(...) end)
    oUF:RegisterStyle('ZoeySquare', function(...) self:ConstructStyle(...) end)
end

function Module:OnEnable()
    local gap = 12

    oUF:SetActiveStyle('Zoey')
    self:CreateUnit('Player'):SetPoint('BOTTOMRIGHT', self.Anchor, 'BOTTOMLEFT', 0, 0)
    self:CreateUnit('Target'):SetPoint('BOTTOMLEFT', self.Anchor, 'BOTTOMRIGHT', 0, 0)
    self:CreateUnit('Focus'):SetPoint('RIGHT', self.units.player, 'LEFT', -gap*2, 0)
    self:CreateUnit('FocusTarget'):SetPoint('BOTTOM', self.units.focus, 'TOP', 0, gap)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateUnit('Pet'):SetPoint('TOPLEFT', self.units.player, 'BOTTOMLEFT', 0, -gap)
    self:CreateUnit('PetTarget'):SetPoint('TOP', self.units.pet, 'BOTTOM', 0, -gap)
    self:CreateUnit('TargetTarget'):SetPoint('TOPRIGHT', self.units.target, 'BOTTOMRIGHT', 0, -gap)
    self:CreateUnit('TargetTargetTarget'):SetPoint('TOPRIGHT', self.units.targettarget, 'BOTTOMRIGHT', 0, -gap)

    oUF:SetActiveStyle('Zoey')
    local Boss, Arena = {},{}
    for i = 1, 5 do
        Boss[i] = self:CreateUnit('Boss'..i)
        Arena[i] = self:CreateUnit('Arena'..i)

        if i == 1 then
            Boss[i]:SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap*3)
            Arena[i]:SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap*3)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
            Arena[i]:SetPoint('BOTTOM', Arena[i - 1], 'TOP', 0, gap)
        end
    end

    local hgap = 130
    oUF:SetActiveStyle('Zoey')
    self:CreateHeader('Party', 'party',
        'showParty', true,
        'yOffset', (hgap - 80),
        'point', 'BOTTOM',

        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',

        'initial-width', 135,
        'initial-height', 80,
        'oUF-initialConfigFunction', [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', gap, 240)

    self:CreateHeader('PartyTargets', 'party',
        'showParty', true,
        'yOffset', (hgap - 40),
        'point', 'BOTTOM',

        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',

        'initial-width', 135,
        'initial-height', 40,
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'target')
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
    ):SetPoint('BOTTOMLEFT', self.headers.party, 'BOTTOMRIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateHeader('PartyPets', 'party',
        'showParty', true,
        'yOffset', (hgap - 20),
        'point', 'BOTTOM',

        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',

        'initial-width', 135,
        'initial-height', 20,
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'pet')
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
    ):SetPoint('BOTTOMLEFT', self.headers.party, 0, -28)

    oUF:SetActiveStyle('ZoeySquare')
    self:CreateHeader('Raid', 'raid',
        'showRaid', true,
        'xOffset', gap/2,
        'point', 'LEFT',

        'maxColumns', 8,
        'unitsPerColumn', 5, -- columns are really hoizontal rows
        'columnSpacing', gap/2,
        'columnAnchorPoint', 'BOTTOM',

        'groupBy', 'ASSIGNEDROLE',
        'groupingOrder', 'TANK,HEALER,DAMAGER',

        'initial-width', 65,
        'initial-height', 40,
        'oUF-initialConfigFunction', [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)
end
