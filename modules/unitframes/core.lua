local ADDON_NAME, Addon = ...

local MODULE_NAME = 'Unitframes'
local Module = Addon:NewModule(MODULE_NAME)

local L = Addon.L
local oUF = Addon.oUF

Module.units, Module.groups, Module.headers = {},{},{}

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {
        colors = {
            border = { 113/255, 113/255, 113/255 },

            health_class = false,
            health_force_reaction = false,
            health_by_value = false,
            health = { 89/255, 89/255, 89/255 },

            health_backdrop_class = false,
            health_backdrop_custom = false,
            health_backdrop = { 204/255, 3/255, 3/255 },

            use_health_backdrop_dead = false,
            health_backdrop_dead = { 204/255, 3/255, 3/255 },

            tapped = { 0.6, 0.6, 0.6 },
            disconnected = { 0.6, 0.6, 0.6 },

            power_class = true,
            power_custom = false,

            power = {
                custom = { 89/255, 89/255, 89/255 },
                MANA = { 0.00, 0.00, 1.00 },
                RAGE = { 1.00, 0.00, 0.00 },
                FOCUS = { 1.00, 0.50, 0.25 },
                ENERGY = { 1.00, 1.00, 0.00 },
                COMBO_POINTS = {1, 0.96, 0.41},
                RUNES = { 0.50, 0.50, 0.50 },
                RUNIC_POWER = { 0.00, 0.82, 1.00 },
                SOUL_SHARDS = { 0.50, 0.32, 0.55 },
                LUNAR_POWER = { 0.30, 0.52, 0.90 },
                HOLY_POWER = { 0.95, 0.90, 0.60 },
                MAELSTROM = { 0.00, 0.50, 1.00 },
                INSANITY = { 0.40, 0, 0.80 },
                CHI = { 0.71, 1.0, 0.92 },
                ARCANE_CHARGES = { 0.1, 0.1, 0.98 },
                FURY = { 0.788, 0.259, 0.992 },
                PAIN = { 255/255, 156/255, 0 },
                STAGGER = {
                    {0.52, 1.0, 0.52},
                    {1.0, 0.98, 0.72},
                    {1.0, 0.42, 0.42}
                },
            },

            healthPrediction = {
                personal = {64/255, 204/255, 255/255, .7},
                others = {64/255, 255/255, 64/255, .7},
                absorbs = {220/255, 255/255, 230/255, .7},
                healAbsorbs = {220/255, 228/255, 255/255, .7},
                maxOverflow = 0.75,
            },

            debuffHighlight = {
                Magic = { 0, 0.8, 1},
                Curse = { 0.8, 0, 1},
                Poison = { 0, 0.8, 0},
                Disease = { 0.8, 0.6, 0},
            },

            reaction = {
                HATED = { 0.8,  0.3,  0.22 },
                UNFRIENDLY = { 0.75,  0.27,  0 },
                NEUTRAL = { 0.9,  0.7,  0 },
                GOOD = { 0,  0.6,  0.1 },
            },

            classification = {
                rare      = { 1, 1, 1},
                rareelite = { 41/255, 128/255, 204/255 },
                elite     = { 204/255, 177/255, 41/255 },
                boss      = { 136/255, 41/255, 204/255 },
                minus     = { 0,0,0 } --
            },

            cast = {
                normal   = {89/255, 89/255, 89/255},
                success  = {20/255, 208/255, 0/255},
                failed   = {255/255, 12/255, 0/255},
                safezone = {255/255, 25/255, 0/255, 0.5},
            },
        },
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
                groupsPerCol = 1,
            },
            partytarget = {
                direction = 'UP',
                spacing = 90,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
                numGroups = 1,
                groupsPerCol = 1,
            },
            partypet = {
                direction = 'UP',
                spacing = 110,
                groupBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
                numGroups = 1,
                groupsPerCol = 1,
            },
            raid = {
                direction = 'RIGHT_UP',
                spacing = 6,
                groupBy = 'ROLE',
                visibility = '[group:raid]show;hide;',
                numGroups = 8,
                groupsPerCol = 1,
                raidWideSorting = true,
                invertGroupGrowth = false, -- TODO: New name?
            },
        }

    }
}

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
    self:DisableBlizzard()
    self:UpdateColors()
    self:LoadUnits()
end

-- Update all database references
function Module:OnProfileRefresh()
    for name, unit in pairs(self.units) do
        unit.db = self.db.profile.units[name]
    end
    for name, group in pairs(self.groups) do
        group.db = self.db.profile.units[name]
        for i = 1, #group do
            group[i].db = group.db
        end
    end
    for name, holder in pairs(self.headers) do
        holder.db = self.db.profile.units[name]
        for i = 1, #holder do
            holder[i].db = holder.db
            for j = 1, #holder[i] do
                holder[i][j].db = holder.db
            end
        end
    end

    self:UpdateAll()
end

function Module:UpdateAll()
    self:UpdateColors()

    for _, unit in pairs(self.units) do unit:Update() end
    for _, group in pairs(self.groups) do group:Update() end
    for _, header in pairs(self.headers) do header:Update() end
end

function Module:UpdateColors()
    local db = self.db.profile.colors

    oUF.colors.tapped = db.tapped
    oUF.colors.disconnected = db.disconnected

    oUF.colors.health = db.health

    oUF.colors.power.custom = db.power.custom

    oUF.colors.power.MANA = db.power.MANA
    oUF.colors.power.RAGE = db.power.RAGE
    oUF.colors.power.FOCUS = db.power.FOCUS
    oUF.colors.power.ENERGY = db.power.ENERGY
    oUF.colors.power.COMBO_POINTS = db.power.COMBO_POINTS
    oUF.colors.power.RUNES = db.power.RUNES
    oUF.colors.power.RUNIC_POWER = db.power.RUNIC_POWER
    oUF.colors.power.SOUL_SHARDS = db.power.SOUL_SHARDS
    oUF.colors.power.LUNAR_POWER = db.power.LUNAR_POWER
    oUF.colors.power.HOLY_POWER = db.power.HOLY_POWER
    oUF.colors.power.MAELSTROM = db.power.MAELSTROM
    oUF.colors.power.INSANITY = db.power.INSANITY
    oUF.colors.power.CHI = db.power.CHI
    oUF.colors.power.ARCANE_CHARGES = db.power.ARCANE_CHARGES
    oUF.colors.power.FURY = db.power.FURY
    oUF.colors.power.PAIN = db.power.PAIN
    oUF.colors.power.STAGGER = db.power.STAGGER

    oUF.colors.debuff.Magic = db.debuffHighlight.Magic
    oUF.colors.debuff.Curse = db.debuffHighlight.Curse
    oUF.colors.debuff.Disease = db.debuffHighlight.Disease
    oUF.colors.debuff.Poison = db.debuffHighlight.Poison

    -- Reaction
    local bad = db.reaction.HATED
    local unfriendly = db.reaction.UNFRIENDLY
    local neutral = db.reaction.NEUTRAL
    local good = db.reaction.GOOD

    oUF.colors.reaction[1] = bad        -- Hated
    oUF.colors.reaction[2] = bad        -- Hostile
    oUF.colors.reaction[3] = unfriendly -- Unfriendly
    oUF.colors.reaction[4] = neutral    -- Neutral
    oUF.colors.reaction[5] = good      -- Friendly
    oUF.colors.reaction[6] = good      -- Honored
    oUF.colors.reaction[7] = good      -- Revered
    oUF.colors.reaction[8] = good      -- Exalted

    oUF.colors.classification = oUF.colors.classification or {}
    oUF.colors.classification.rare = db.classification.rare
    oUF.colors.classification.rareelite = db.classification.rareelite
    oUF.colors.classification.elite = db.classification.elite
    oUF.colors.classification.boss = db.classification.boss

    oUF.colors.cast = oUF.colors.cast or {}
    oUF.colors.cast.normal = db.cast.normal
    oUF.colors.cast.success = db.cast.success
    oUF.colors.cast.failed = db.cast.failed
    oUF.colors.cast.safezone = db.cast.safezone
    oUF.colors.cast.notInterruptible = db.cast.notInterruptible

    oUF.colors.border = db.border

    oUF.colors.healthPrediction = oUF.colors.healthPrediction or {}
    oUF.colors.healthPrediction.personal = db.healthPrediction.personal
    oUF.colors.healthPrediction.others = db.healthPrediction.others
    oUF.colors.healthPrediction.absorbs = db.healthPrediction.absorbs
    oUF.colors.healthPrediction.healAbsorbs = db.healthPrediction.healAbsorbs
    oUF.colors.healthPrediction.maxOverflow = db.healthPrediction.maxOverflow
end

function Module:DisableBlizzard()
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
end

function Module:CreateGroup(group)
    local group = group:lower()

    -- If it doesnt exist, create it!
    if not self.groups[group] then
        local holder = CreateFrame('Frame', 'ZoeyUI_'..unitToCamelCase(group), ZoeyUI_PetBattleFrameHider)
        holder.db = self.db.profile.units[group]

        for i = 1, 5 do
            local object = oUF:Spawn(group..i, 'ZoeyUI_'..unitToCamelCase(group..i))
            object:SetParent(holder)
            holder[i] = object
        end

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
    -- Disable SecureGroupHeader from updating on attribute changes.
    local oldIgnore = self:GetAttribute('_ignore')
    self:SetAttribute('_ignore', 'attributeChanges')

    local db = self.db

    local point = directionToAnchorPoint[db.direction]
    local _, xMult, yMult = getRelativeAnchorPoint(point)

    local horizontalSpacing = db.horizontalSpacing or db.spacing
    local verticalSpacing = db.verticalSpacing or db.spacing

    self:SetAttribute('point', point)

    self:SetAttribute('xOffset', horizontalSpacing * xMult)
    self:SetAttribute('yOffset', verticalSpacing * yMult)

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

    -- Update child units
    for i = 1, #self do
        local child = self[i]

        child:Update()

        -- Need to clear the points of the child for the SecureGroupHeader_Update
        -- to anchor, incase attributes change after first Update.
        child:ClearAllPoints()
    end

    -- Reenable Updating and set a attribute to force an update
    self:SetAttribute('_ignore', oldIgnore)
    self:SetAttribute('ForceUpdate')
end

local function createChildHeader(parent, overrideName, headerName)
    local header = parent.headerName or headerName
    local object = oUF:SpawnHeader(overrideName, nil, nil,
        'showRaid', true, 'showParty', true, 'showSolo', true,
        'oUF-initialConfigFunction', ([[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute('initial-width'))
            self:SetHeight(header:GetAttribute('initial-height'))
            self:SetAttribute('unitsuffix', header:GetAttribute('unitsuffix'))
            -- Overwrite what oUF thinks the unit is
            self:SetAttribute('oUF-guessUnit', '%s')
        ]]):format(header))

    object:SetParent(parent)
    object.headerName = header
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
    if db.raidWideSorting then
        if not self[1] then -- only need the first group with raidWideSorting
            self[1] = createChildHeader(self, 'ZoeyUI_'..unitToCamelCase(self.headerName)..'Group1')
        end
    else
        while db.numGroups > #self do
            self[#self + 1] = createChildHeader(self, 'ZoeyUI_'..unitToCamelCase(self.headerName)..'Group'..(#self + 1))
        end
    end

    -- Update visibility
    if not self.visibility or self.visibility ~= db.visibility then
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
    local relativePoint, xMult, yMult = getRelativeAnchorPoint(point)

    local columnAnchorPoint = directionToColumnAnchorPoint[db.direction]
    local relativeColumnAnchorPoint, colxMult, colyMult = getRelativeAnchorPoint(columnAnchorPoint)

    local horizontalSpacing = db.horizontalSpacing or db.spacing
    local verticalSpacing = db.verticalSpacing or db.spacing
    local numRows = ceil(db.numGroups / db.groupsPerCol)

    -- Guesstimate the size of one group
    local unitWidth = self[1]:GetAttribute('initial-width')   -- We can use these attributes until
    local unitHeight = self[1]:GetAttribute('initial-height') -- the size gets stored in the database

    local groupWidth = abs(xMult) * (unitWidth + horizontalSpacing) * 4 + unitWidth
    local groupHeight = abs(yMult) * (unitHeight + verticalSpacing) * 4 + unitHeight

    -- Only update the groups we're using
    for i = 1, db.raidWideSorting and 1 or db.numGroups do
        local childHeader = self[i]

        -- Disable SecureGroupHeader from updating on attribute changes.
        local oldIgnore = childHeader:GetAttribute('_ignore')
        childHeader:SetAttribute('_ignore', 'attributeChanges')

        -- Configure/Update child headers
        childHeader:Update()

        -- A child header doesnt know what group it is
        if i == 1 and db.raidWideSorting then
            childHeader:SetAttribute('groupFilter', '1,2,3,4,5,6,7,8')
        else
            childHeader:SetAttribute('groupFilter', tostring(i))
        end

        -- Setup column settings
        if point == 'LEFT' or point == 'RIGHT' then
            childHeader:SetAttribute('columnSpacing', verticalSpacing)
        else
            childHeader:SetAttribute('columnSpacing', horizontalSpacing)
        end

        childHeader:SetAttribute('columnAnchorPoint', directionToColumnAnchorPoint[db.direction])
        childHeader:SetAttribute('maxColumns', db.raidWideSorting and numRows or 1)
        childHeader:SetAttribute('unitsPerColumn', db.raidWideSorting and (db.groupsPerCol * 5) or 5)

        -- Reenable Updating and set a attribute to force an update
        childHeader:SetAttribute('_ignore', oldIgnore)
        childHeader:SetAttribute('ForceUpdate')

        -- Start over with anchors
        childHeader:ClearAllPoints()

        -- Anchoring has to starts somewhere
        if i == 1 then
            childHeader:SetPoint(point, self)
            childHeader:SetPoint(columnAnchorPoint, self)

        -- Start a new row
        elseif db.invertGroupGrowth and (i <= numRows)
        or not db.invertGroupGrowth and ((i - 1) % db.groupsPerCol == 0) then
            local anchorTo = self[i - (db.invertGroupGrowth and 1 or db.groupsPerCol)]
            childHeader:SetPoint(point, anchorTo) -- Needed to align, if the groups arnt the same size
            childHeader:SetPoint(columnAnchorPoint, anchorTo, relativeColumnAnchorPoint,
                horizontalSpacing * colxMult, verticalSpacing * colyMult)

        -- New column, if there are any.
        else
            local anchorTo = self[i - (db.invertGroupGrowth and numRows or 1)]

            -- Offset by the width of a full group, to keep a gap for missing players
            -- idea: make this an option?
            childHeader:SetPoint(point, anchorTo, point,
                xMult * (groupWidth + horizontalSpacing),
                yMult * (groupHeight + verticalSpacing))
        end
    end

    -- Rezize the holder to fit the size of the child headers

    -- Start with 1 column of groups: if groupsPerCol is 1 then just the group size
    local width = abs(xMult) * (groupWidth + horizontalSpacing) * (db.groupsPerCol - 1) + groupWidth
    local height = abs(yMult) * (groupHeight + verticalSpacing) * (db.groupsPerCol - 1) + groupHeight

    -- Then increase by the number of rows
    width = abs(colxMult) * (width + horizontalSpacing) * (numRows - 1) + width
    height = abs(colyMult) * (height + verticalSpacing) * (numRows - 1) + height

    self:SetWidth(width)
    self:SetHeight(height)
end

function Module:CreateHeader(header, ...)
    local header = header:lower()

    if not self.headers[header] then
        local holder = CreateFrame('Frame', 'ZoeyUI_'..unitToCamelCase(header), ZoeyUI_PetBattleFrameHider, 'SecureHandlerStateTemplate');
        holder.db = self.db.profile.units[header]
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
    local gap = 12

    oUF:SetActiveStyle('Zoey')
    self:CreateUnit('Player'):SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', -160, 245)
    self:CreateUnit('Target'):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOM', 160, 245)

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
        'unitsuffix', 'target'
    ):SetPoint('BOTTOMLEFT', self.headers.party, 'BOTTOMRIGHT', gap, 0)

    oUF:SetActiveStyle('ZoeyThin')
    self:CreateHeader('PartyPet',
        'initial-width', 135,
        'initial-height', 20,
        'unitsuffix', 'pet'
    ):SetPoint('BOTTOMLEFT', self.headers.party, 0, -28)

    oUF:SetActiveStyle('ZoeySquare')
    self:CreateHeader('Raid',
        'initial-width', 65,
        'initial-height', 40
    ):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)
end
