local ADDON_NAME, Addon = ...

local MODULE_NAME = 'Unitframes'
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
                numGroups = 1,
            },
            partytarget = {
                direction = 'UP',
                spacing = 90,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
                numGroups = 1,
            },
            partypet = {
                direction = 'UP',
                spacing = 110,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
                numGroups = 1,
            },
            raid = {
                direction = 'RIGHT_UP',
                spacing = 6,
                groupBy = 'ROLE',
                visibility = '[group:raid]show;hide;',
                numGroups = 8,
                raidWideSorting = true,
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
    for _, menu in pairs(UnitPopupMenus) do
        for i = #menu, 1, -1 do
            local name = menu[i]
            if name:match('^LOCK_%u+_FRAME$')
            or name:match('^UNLOCK_%u+_FRAME$')
            or name:match('^MOVE_%u+_FRAME$')
            or name:match('^RESET_%u+_FRAME_POSITION')
            or name:match('^SET_FOCUS')
            or name:match('^DISMISS')
            then
                table.remove(menu, i)
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
        :gsub('^%l', string.upper) -- set the first character upper case
        :gsub('t(arget)', 'T%1')
        :gsub('p(et)', 'P%1')
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
local directionToAnchorPoint = { -- opposite of first direction
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

-- relativePoint, xMultiplier, yMultiplier = getRelativeAnchorPoint(point)
-- Given a point return the opposite point and which axes the point depends on.
local function getRelativeAnchorPoint(point)
    point = point:upper();
    if point == 'TOP' then return 'BOTTOM', 0, -1
    elseif point == 'BOTTOM' then return 'TOP', 0, 1
    elseif point == 'LEFT' then return 'RIGHT', 1, 0
    elseif point == 'RIGHT' then return 'LEFT', -1, 0
    end
end

local groupMethods = {}
-- Group update method. Updates and positions child the sudo-header.
function groupMethods:Update()
    local db = self.db

    local point = directionToAnchorPoint[db.direction]
    local relativePoint, xMult, yMult = getRelativeAnchorPoint(point)

    for i = 1, #self do
        local child = self[i]

        child:Update()
        child:ClearAllPoints()

        if i == 1 then
            child:SetPoint(point, self, point, 0, 0)
        else
            child:SetPoint(point, self[i - 1], relativePoint, db.spacing * xMult, db.spacing * yMult)
        end
    end

    -- Resize group sudo-header to fit the size of all the child units
    local unitWidth, unitHeight = self[1]:GetSize()
    self:SetWidth(abs(xMult) * (unitWidth + db.spacing) * (#self - 1) + unitWidth)
    self:SetHeight(abs(yMult) * (unitHeight + db.spacing) * (#self - 1) + unitHeight)

    -- TODO: should we add a column system?
end

function Module:CreateGroup(group)
    local group = group:lower()

    -- If it doesnt exist, create it!
    if not self.groups[group] then
        local holder = CreateFrame('Frame', 'ZoeyUI_'..group:gsub('^%l', string.upper), oUF_PetBattleFrameHider)

        for i = 1, 5 do
            local object = oUF:Spawn(group..i, 'ZoeyUI_'..unitToCamelCase(group..i))
            object:SetParent(holder)
            object.db = self.db.profile.units[group] -- easy reference
            holder[i] = object
        end

        holder.db = self.db.profile.units[group] -- easy reference

        for k, v in pairs(groupMethods) do
            holder[k] = v
        end

        holder:Update() -- run the update to position child units

        self.groups[group] = holder
    end

    return self.groups[group] -- Return the sudo-header
end

local headerMethods = {}
function headerMethods:Update()
    -- SecureGroupHeader_Update gets called with each attribute change.
    -- Thats to much. We dont want that. So lets disable that.
    local oldIgnore = self:GetAttribute("_ignore")
    self:SetAttribute("_ignore", "attributeChanges")

    local db = self.db

    local point = directionToAnchorPoint[db.direction]
    local _, xMult, yMult = getRelativeAnchorPoint(point)

    local horizontalSpacing = db.horizontalSpacing or db.spacing
    local verticalSpacing = db.verticalSpacing or db.spacing

    self:SetAttribute('point', point)

    self:SetAttribute('xOffset', horizontalSpacing * xMult)
    self:SetAttribute('yOffset', verticalSpacing * yMult)

    -- First direction is horizontal so, columns are grow verticaly
    if point == 'LEFT' or point == 'RIGHT' then
        self:SetAttribute('columnSpacing', verticalSpacing)
    else
        self:SetAttribute('columnSpacing', horizontalSpacing)
    end

    self:SetAttribute('columnAnchorPoint', directionToColumnAnchorPoint[db.direction])
    self:SetAttribute('maxColumns', db.raidWideSorting and db.numGroups or 1)
    self:SetAttribute('unitsPerColumn', 5)

    -- Sorting
    if db.groupBy == 'CLASS' then
        self:SetAttribute('groupingOrder', 'DEATHKNIGHT,DRUID,HUNTER,MAGE,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR,MONK')
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute('groupBy', 'CLASS')
    elseif db.groupBy == 'ROLE' then
        self:SetAttribute('groupingOrder', 'TANK,HEALER,DAMAGER,NONE')
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute('groupBy', 'ASSIGNEDROLE')
    elseif db.groupBy == 'NAME' then
        self:SetAttribute('groupingOrder', '1,2,3,4,5,6,7,8')
        self:SetAttribute('sortMethod', 'NAME')
        self:SetAttribute('groupBy', nil)
    elseif db.groupBy == 'GROUP' then
        self:SetAttribute('groupingOrder', '1,2,3,4,5,6,7,8')
        self:SetAttribute('sortMethod', 'INDEX')
        self:SetAttribute('groupBy', 'GROUP')
    end

    self:SetAttribute('sortDir', db.sortDir or 'ASC')

    -- Renable SecureGroupheader updating
    self:SetAttribute("_ignore", oldIgnore)

    -- Update child units
    for i = 1, #self do
        local child = self[i]

        child:Update()

        -- Need to clear the points of the child for the SecureGroupHeader_Update
        -- to anchor, incase attributes change after first Update.
        child:ClearAllPoints()
    end
end

local function createChildHeader(parent, overrideName, headerName)
    local header = parent.headerName or headerName
    local object = oUF:SpawnHeader(overrideName, nil, nil,
        'showRaid', true, 'showParty', true, 'showSolo', true,
        'oUF-initialConfigFunction', ([[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute('initial-width'))
            self:SetHeight(header:GetAttribute('initial-height'))
            self:SetAttribute('unitsuffix', header:GetAttribute('oUF-unitsuffix'))
            -- Overwrite what oUF thinks the unit is
            self:SetAttribute('oUF-guessUnit', '%s')
        ]]):format(header))

    object:SetParent(parent)
    object.headerName = group
    object.db = parent.db

    if parent.childAttribues then
        for att, val in pairs(parent.childAttribues) do
            object:SetAttribute(att, val)
        end
    end

    for k, v in pairs(headerMethods) do
        object[k] = v
    end

    return object
end

local holderMethods = {}
function holderMethods:Update()
    local db = self.db

    -- Create any child headers if needed
    if db.raidWideSorting and not self[1] then -- only need the first group with raidWideSorting
        self[1] = createChildHeader(self, 'ZoeyUI_'..unitToCamelCase(self.headerName)..'Group1')
    else
        while self.db.numGroups > #self do
            self[#self + 1] = createChildHeader(self, 'ZoeyUI_'..unitToCamelCase(self.headerName)..'Group'..(#self + 1))
        end
    end

    -- Update visibility
    if not self.visibility or self.visibility ~= self.db.visibility then
        RegisterStateDriver(self, 'visibility', db.visibility)
        self.visibility = db.visibility
    end

    -- Update child header visibility
    for i = 1, #self do
        local childHeader = self[i]

        -- if numGroups changed or raidWideSorting was enabled,
        -- hide child headers that aren't used.
        if i > db.numGroups or db.raidWideSorting and i > 1 then
            childHeader:Hide()
        else
            childHeader:Show()
        end
    end

    local point = directionToAnchorPoint[db.direction]
    local _, xMult, yMult = getRelativeAnchorPoint(point)

    local columnAnchorPoint = directionToColumnAnchorPoint[db.direction]
    local relativeColumnAnchorPoint, colxMult, colyMult = getRelativeAnchorPoint(columnAnchorPoint)

    local horizontalSpacing = db.horizontalSpacing or db.spacing
    local verticalSpacing = db.verticalSpacing or db.spacing

    -- Only update the groups we're using
    for i = 1, db.raidWideSorting and 1 or db.numGroups do
        local childHeader = self[i]

        -- Configure/Update child headers
        childHeader:Update()

        -- A child header doesnt know what group it is
        if i == 1 and db.raidWideSorting then
            childHeader:SetAttribute('groupFilter', '1,2,3,4,5,6,7,8')
        else
            childHeader:SetAttribute('groupFilter', tostring(i))
        end

        -- Start over with anchors
        childHeader:ClearAllPoints()

        -- Anchor child headers together
        if i == 1 then
            childHeader:SetPoint(point, self)
            childHeader:SetPoint(columnAnchorPoint, self)
        else
            childHeader:SetPoint(point, self[i - 1]) -- Needed to align
            childHeader:SetPoint(columnAnchorPoint, self[i - 1], relativeColumnAnchorPoint,
                horizontalSpacing * colxMult, verticalSpacing * colyMult)
        end
    end

    -- Resize holder to fit the size of all the child headers
    local unitWidth = self[1]:GetAttribute('initial-width')   -- We can use these attributes until
    local unitHeight = self[1]:GetAttribute('initial-height') -- the size gets stored in the database

    local groupWidth = (abs(xMult) * (unitWidth + horizontalSpacing) * 4 + unitWidth)
    local groupHeight = (abs(yMult) * (unitHeight + verticalSpacing) * 4 + unitHeight)

    self:SetWidth(abs(colxMult) * (groupWidth + horizontalSpacing) * (db.numGroups - 1) + groupWidth)
    self:SetHeight(abs(colyMult) * (groupHeight + verticalSpacing) * (db.numGroups - 1) + groupHeight)
end

function Module:CreateHeader(header, ...)
    local header = header:lower()

    if not self.headers[header] then
        local db = self.db.profile.units[header]

        local holder = CreateFrame('Frame', 'ZoeyUI_'..unitToCamelCase(header), oUF_PetBattleFrameHider, 'SecureHandlerStateTemplate');
        holder.db = db
        holder.headerName = header

        -- Save extra attributes for children
        holder.childAttribues = {}
        for i = 1, select('#', ...), 2 do
            local att, val = select(i, ...)
            holder.childAttribues[att] = val
        end

        for k, v in pairs(holderMethods) do
            holder[k] = v
        end

        -- Update to configure child headers and anchor
        holder:Update()

        self.headers[header] = holder
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
    self:CreateUnit('Focus'):SetPoint('RIGHT', self.units.player, 'LEFT', -gap * 2, 0)
    self:CreateUnit('FocusTarget'):SetPoint('BOTTOM', self.units.focus, 'TOP', 0, gap)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateUnit('Pet'):SetPoint('TOPLEFT', self.units.player, 'BOTTOMLEFT', 0, -gap)
    self:CreateUnit('PetTarget'):SetPoint('TOP', self.units.pet, 'BOTTOM', 0, -gap)
    self:CreateUnit('TargetTarget'):SetPoint('TOPRIGHT', self.units.target, 'BOTTOMRIGHT', 0, -gap)
    self:CreateUnit('TargetTargetTarget'):SetPoint('TOPRIGHT', self.units.targettarget, 'BOTTOMRIGHT', 0, -gap)

    oUF:SetActiveStyle('Zoey')
    self:CreateGroup('Boss'):SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap * 3)
    self:CreateGroup('Arena'):SetPoint('BOTTOM', self.units.focustarget, 'TOP', 0, gap * 3)

    oUF:SetActiveStyle('Zoey')
    self:CreateHeader('Party',
        'initial-width', 135, -- TODO: These can be moved later when the database holds the frame sizes
        'initial-height', 80  --       Right now the style, and header initialConfigFunction holds the sizes
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', gap, 240)

    self:CreateHeader('PartyTarget',
        'initial-width', 135,
        'initial-height', 40,
        'oUF-unitsuffix', 'target'
    ):SetPoint('BOTTOMLEFT', self.headers.party, 'BOTTOMRIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateHeader('PartyPet',
        'initial-width', 135,
        'initial-height', 20,
        'oUF-unitsuffix', 'pet'
    ):SetPoint('BOTTOMLEFT', self.headers.party, 0, -28)

    oUF:SetActiveStyle('ZoeySquare')
    self:CreateHeader('Raid',
        'initial-width', 65,
        'initial-height', 40
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)
end
