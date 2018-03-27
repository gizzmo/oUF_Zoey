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
            ['**'] = {
                enable = true,
            },
            player = {},
            target = {},
            focus = {},
            focustarget = {},
            pet = {},
            pettarget = {},
            targettarget = {},
            targettargettarget = {},

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
            party = {
                direction = 'UP',
                spacing = 50,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
            },
            partytarget = {
                direction = 'UP',
                spacing = 90,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
            },
            partypet = {
                direction = 'UP',
                spacing = 110,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
            },
            raid = {
                direction = 'RIGHT_UP',
                spacing = 6,
                groupBy = 'ROLE',
                visibility = '[group:raid]show;hide;',
            },
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
        object.db = self.db.profile.units[unit] -- easy reference
        self.units[unit] = object
    end

    return self.units[unit]
end

-- Single directions should be identical to x_RIGHT or x_UP
local directionToPoint = { -- opposite of first direction
    UP_LEFT = 'BOTTOM',
    UP_RIGHT = 'BOTTOM', UP = 'BOTTOM',
    DOWN_LEFT = 'TOP',
    DOWN_RIGHT = 'TOP',  DOWN = 'TOP',

    LEFT_UP = 'RIGHT',   LEFT = 'RIGHT',
    LEFT_DOWN = 'RIGHT',
    RIGHT_UP = 'LEFT',   RIGHT = 'LEFT',
    RIGHT_DOWN = 'LEFT',
}
local directionToColumnAnchorPoint = { -- opposite of second direction
    UP_LEFT = 'RIGHT',
    UP_RIGHT = 'LEFT',   UP = 'LEFT',
    DOWN_LEFT = 'RIGHT',
    DOWN_RIGHT = 'LEFT', DOWN = 'LEFT',

    LEFT_UP = 'BOTTOM',  LEFT = 'BOTTOM',
    LEFT_DOWN = 'TOP',
    RIGHT_UP = 'BOTTOM', RIGHT = 'BOTTOM',
    RIGHT_DOWN = 'TOP',
}
local directionToHorizontalSpacingMultiplier = {
    UP_LEFT = -1,
    UP_RIGHT = 1,   UP = 1,
    DOWN_LEFT = -1,
    DOWN_RIGHT = 1, DOWN = 1,

    LEFT_UP = -1,   LEFT = -1,
    LEFT_DOWN = -1,
    RIGHT_UP = 1,   RIGHT = 1,
    RIGHT_DOWN = 1,
}
local directionToVerticalSpacingMultiplier = {
    UP_LEFT = 1,
    UP_RIGHT = 1,    UP = 1,
    DOWN_LEFT = -1,
    DOWN_RIGHT = -1, DOWN = -1,

    LEFT_UP = 1,     LEFT = 1,
    LEFT_DOWN = -1,
    RIGHT_UP = 1,    RIGHT = 1,
    RIGHT_DOWN = -1,
}

local groupMethods = {}
-- Group update method. Updates and positions child the sudo-header.
function groupMethods:Update()
    for i, child in ipairs(self) do
        child:Update()
        child:ClearAllPoints()

        local db = child.db
        if i == 1 then -- Attaches to the sudo-header
            if db.direction == 'UP' then        child:SetPoint('BOTTOM', self)
            elseif db.direction == 'DOWN' then  child:SetPoint('TOP', self)
            elseif db.direction == 'RIGHT' then child:SetPoint('LEFT', self)
            elseif db.direction == 'LEFT' then  child:SetPoint('RIGHT', self)
            end
        else -- Attaches to the previous child
            if db.direction == 'UP' then        child:SetPoint('BOTTOM', self[i-1], 'TOP', 0, db.spacing)
            elseif db.direction == 'DOWN' then  child:SetPoint('TOP', self[i-1], 'BOTTOM', 0, -db.spacing)
            elseif db.direction == 'RIGHT' then child:SetPoint('LEFT', self[i-1], 'RIGHT', db.spacing, 0)
            elseif db.direction == 'LEFT' then  child:SetPoint('RIGHT', self[i-1], 'LEFT', -db.spacing, 0)
            end
        end
    end

    -- Resize group sudo-header to fit the size of all the child units
    local db = self.db
    if db.direction == 'UP' or db.direction == 'DOWN' then
        self:SetWidth(self[#self]:GetWidth())
        self:SetHeight(((self[#self]:GetHeight() + db.spacing) * #self) - db.spacing)
    elseif db.direction == 'LEFT' or db.direction == 'RIGHT' then
        self:SetWidth(((self[#self]:GetWidth() + db.spacing) * #self) - db.spacing)
        self:SetHeight(self[#self]:GetHeight())
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

        for k,v in pairs(groupMethods) do
            objects[k] = v
        end

        objects:Update() -- run the update to position child units

        self.groups[group] = objects
    end

    return self.groups[group] -- Return the sudo-header
end

local headerMethods = {}
function headerMethods:Update()
    local db = self.db

    local point = directionToPoint[db.direction]

    self:SetAttribute('point', point)

    if point == 'LEFT' or point == 'RIGHT' then
        self:SetAttribute('xOffset', (db.spacing or db.horizontalSpacing) * directionToHorizontalSpacingMultiplier[db.direction])
        self:SetAttribute('yOffset', 0)
        self:SetAttribute('columnSpacing', (db.spacing or db.verticalSpacing))
    else
        self:SetAttribute('xOffset', 0)
        self:SetAttribute('yOffset', (db.spacing or db.verticalSpacing) * directionToVerticalSpacingMultiplier[db.direction])
        self:SetAttribute('columnSpacing', (db.spacing or db.horizontalSpacing))
    end

    self:SetAttribute('columnAnchorPoint', directionToColumnAnchorPoint[db.direction])
    self:SetAttribute('maxColumns', 8)
    self:SetAttribute('unitsPerColumn', 5)

    -- Sorting
    if db.groupBy == 'CLASS' then
        self:SetAttribute("groupingOrder", "DEATHKNIGHT,DRUID,HUNTER,MAGE,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR,MONK")
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute("groupBy", 'CLASS')
    elseif db.groupBy == 'ROLE' then
        self:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute("groupBy", 'ASSIGNEDROLE')
    elseif db.groupBy == 'NAME' then
        self:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute("groupBy", nil)
    elseif db.groupBy == 'GROUP' then
        self:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
        self:SetAttribute('sortMethod', 'INDEX')
        self:SetAttribute("groupBy", 'GROUP')
    end

    self:SetAttribute('sortDir', db.sortDir or 'ASC')

    -- Update visibility
    if not self.visibility or self.visibility ~= self.db.visibility then
        RegisterStateDriver(self, 'visibility', db.visibility)
        self.visibility = db.visibility
    end

    for i = 1, self:GetNumChildren() do
        -- NOTE: If a frame is created with this header as its parent, a error
        -- could occure because that frame isnt the kinda child we're looking for.
        select(i, self:GetChildren()):Update()
    end
end

function Module:CreateHeader(header, ...)
    local header = header:lower()

    -- If it doesnt exist, create it!
    if not self.headers[header] then
        local object = oUF:SpawnHeader('ZoeyUI_'..unitToCamelCase(header), nil, nil,
            'showRaid', true, 'showParty', true, 'showSolo', true,
            'oUF-initialConfigFunction', ([[
                local header = self:GetParent()
                self:SetWidth(header:GetAttribute("initial-width"))
                self:SetHeight(header:GetAttribute("initial-height"))
                -- Overwrite what oUF thinks the unit is
                self:SetAttribute('oUF-guessUnit', '%s')
            ]]):format(header), ...)

        object.db = self.db.profile.units[header] -- easy reference

        for k,v in pairs(headerMethods) do
            object[k] = v
        end

        object:Update() -- run the update to configure header

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

    oUF:SetActiveStyle('Zoey')
    self:CreateHeader('Party',
        'initial-width', 135, -- TODO: These can be moved later when the database holds the frame sizes
        'initial-height', 80  --       Right now the style, and header initialConfigFunction holds the sizes
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', gap, 240)

    self:CreateHeader('PartyTarget',
        'initial-width', 135,
        'initial-height', 40
    ):SetPoint('BOTTOMLEFT', self.headers.party, 'BOTTOMRIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateHeader('PartyPet',
        'initial-width', 135,
        'initial-height', 20
    ):SetPoint('BOTTOMLEFT', self.headers.party, 0, -28)

    oUF:SetActiveStyle('ZoeySquare')
    self:CreateHeader('Raid',
        'initial-width', 65,
        'initial-height', 40
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)
end
