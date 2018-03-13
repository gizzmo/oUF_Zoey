local ADDON_NAME, Addon = ...

local MODULE_NAME = "Unitframes"
local Module = Addon:NewModule(MODULE_NAME)

local L = Addon.L
local oUF = Addon.oUF

Module.units, Module.groups, Module.headers = {},{},{}

------------------------------------------------------------------ oUF Colors --
oUF.colors.health = {89/255, 89/255, 89/255} -- dark grey
oUF.colors['cast'] = {
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
        units = {
            -- groups
            boss = {
                direction = 'UP',
                spacing = 12,
            },
            arena = {
                direction = 'UP',
                spacing = 12,
            },

            -- headers
            party = {},
            partytargets = {},
            partypets = {},
        }

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
function Module:OnInitialize()
    self.db = Addon.db:RegisterNamespace(MODULE_NAME, defaultDB)

    -- Registering our style functions
    oUF:RegisterStyle('Zoey', function(...) self:ConstructStyle(...) end)
    oUF:RegisterStyle('ZoeyThin', function(...) self:ConstructStyle(...) end)
    oUF:RegisterStyle('ZoeySquare', function(...) self:ConstructStyle(...) end)

    -- Every object gets a update method to update its style
    oUF:RegisterMetaFunction('Update', function(...) self:UpdateStyle(...) end)

    -- After creating a object, also run the Update Method
    oUF:RegisterInitCallback(function(object) object:Update() end)
end

function Module:OnEnable()
    -- Hide the Blizzard Buffs
    BuffFrame:Hide()
    BuffFrame:UnregisterAllEvents()
    TemporaryEnchantFrame:Hide()

    -- Hide Raidframes
    CompactRaidFrameManager:Hide()
    CompactRaidFrameManager:UnregisterAllEvents()
    CompactRaidFrameContainer:UnregisterAllEvents()

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

    self:LoadUnits()
end

-------------------------------------------------------------------- Updating --
function Module:UpdateAll()
    for _, unit in pairs(self.units) do unit:Update() end
    for _, group in pairs(self.groups) do group:Update() end
    for _, header in pairs(self.headers) do header:Update() end
end

-------------------------------------------------------------------- Creating --
local function unitToCamelCase(string)
    return string:lower() -- start all lower case
        :gsub('^%l', string.upper)   -- set the first character upper case
        :gsub('t(arget)', 'T%1')
        :gsub('p(ets)', 'P%1')
end

function Module:CreateUnit(unit)
    local unit = unit:lower()

    -- If it doesnt exist, create it!
    if not self.units[unit] then
        local object = oUF:Spawn(unit, 'ZoeyUI_'..unitToCamelCase(unit))

        self.units[unit] = object
    end

    return self.units[unit]
end

-- Group update method. Updates and positions child the sudo-header.
local function groupUpdateFunction(group)
    for i, child in ipairs(group) do
        child:Update()
        child:ClearAllPoints()

        local db = child.db
        if i == 1 then -- Attaches to the sudo-header
            if db.direction == 'UP' then        child:SetPoint('BOTTOM', group)
            elseif db.direction == 'DOWN' then  child:SetPoint('TOP', group)
            elseif db.direction == 'RIGHT' then child:SetPoint('LEFT', group)
            elseif db.direction == 'LEFT' then  child:SetPoint('RIGHT', group)
            end
        else -- Attaches to the previous child
            if db.direction == 'UP' then        child:SetPoint('BOTTOM', group[i-1], 'TOP', 0, db.spacing)
            elseif db.direction == 'DOWN' then  child:SetPoint('TOP', group[i-1], 'BOTTOM', 0, -db.spacing)
            elseif db.direction == 'RIGHT' then child:SetPoint('LEFT', group[i-1], 'RIGHT', db.spacing, 0)
            elseif db.direction == 'LEFT' then  child:SetPoint('RIGHT', group[i-1], 'LEFT', -db.spacing, 0)
            end
        end
    end

    -- Resize group sudo-header to fit the size of all the child units
    local db = group.db
    if db.direction == 'UP' or db.direction == 'DOWN' then
        group:SetWidth(group[#group]:GetWidth())
        group:SetHeight(((group[#group]:GetHeight() + db.spacing) * #group) - db.spacing)
    elseif db.direction == 'LEFT' or db.direction == 'RIGHT' then
        group:SetWidth(((group[#group]:GetWidth() + db.spacing) * #group) - db.spacing)
        group:SetHeight(group[#group]:GetHeight())
    end

    -- TODO: should we add a column system?
    -- TODO: needs combat protection.
end

function Module:CreateGroup(group)
    local group = group:lower()

    -- If it doesnt exist, create it!
    if not self.groups[group] then
        local objects = CreateFrame('Frame', 'ZoeyUI_'..group:gsub('^%l', string.upper), UIParent)

        for i=1,5 do
            local object = oUF:Spawn(group..i, 'ZoeyUI_'..unitToCamelCase(group..i))
            object.db = self.db.profile.units[group] -- easy reference
            objects[i] = object
        end

        objects.db = self.db.profile.units[group] -- easy reference

        objects.Update = groupUpdateFunction
        objects:Update() -- run the update to position child units

        self.groups[group] = objects
    end

    return self.groups[group] -- Return the sudo-header
end

local function headerUpdateFunction(object)
    -- TODO: need function to update this header's attributes

    for i = 1, object:GetNumChildren() do
        -- NOTE: If a frame is created with this header as its parent, a error
        -- could occure because that frame isnt the kinda child we're looking for.
        select(i, object:GetChildren()):Update()
    end
end

function Module:CreateHeader(header, ...)
    local header = header:lower()

    -- If it doesnt exist, create it!
    if not self.headers[header] then
        local object = oUF:SpawnHeader('ZoeyUI_'..unitToCamelCase(header), nil, ...)

        object.db = self.db.profile.units[header] -- easy reference

        object.Update = headerUpdateFunction

        self.headers[header] = object
    end

    return self.headers[header]
end


function Module:LoadUnits()
    if not self.Anchor then
        local Anchor = CreateFrame('Frame', 'ZoeyUI_UnitFrameAnchor', UIParent)
        Anchor:SetSize(320, 1) -- width is the gap between target and player frames
        Anchor:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 245)
        self.Anchor = Anchor
    end

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
    self:CreateGroup('Boss'):SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap*3)
    self:CreateGroup('Arena'):SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap*3)

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
