local ADDON_NAME, Addon = ...

local MODULE_NAME = 'Unitframes'
local Module = Addon:NewModule(MODULE_NAME)

local L = Addon.L
local oUF = Addon.oUF

Module.units, Module.groups, Module.headers = {},{},{}

local unitToPascalCase = Addon.UnitToPascalCase

-- Converts a anchor side variable into varibles used for SetPoint.
-- A side variable starts with the side its to be on, then which side it should
-- align to. This means RIGHT_BOTTOM is on the right side, aligned to the bottom.

-- returns: point, relativePoint, xMultiplier, yMultiplier
local function getSideAnchorPoints(side)
    if     side == 'TOP_LEFT'     then return 'BOTTOMLEFT',  'TOPLEFT',     0, 1
    elseif side == 'TOP'          then return 'BOTTOM',      'TOP',         0, 1
    elseif side == 'TOP_RIGHT'    then return 'BOTTOMRIGHT', 'TOPRIGHT',    0, 1

    elseif side == 'BOTTOM_LEFT'  then return 'TOPLEFT',     'BOTTOMLEFT',  0, -1
    elseif side == 'BOTTOM'       then return 'TOP',         'BOTTOM',      0, -1
    elseif side == 'BOTTOM_RIGHT' then return 'TOPRIGHT',    'BOTTOMRIGHT', 0, -1

    elseif side == 'LEFT_TOP'     then return 'TOPRIGHT',    'TOPLEFT',     -1, 0
    elseif side == 'LEFT'         then return 'RIGHT',       'LEFT',        -1, 0
    elseif side == 'LEFT_BOTTOM'  then return 'BOTTOMRIGHT', 'BOTTOMLEFT',  -1, 0

    elseif side == 'RIGHT_TOP'    then return 'TOPLEFT',     'TOPRIGHT',    1, 0
    elseif side == 'RIGHT'        then return 'LEFT',        'RIGHT',       1, 0
    elseif side == 'RIGHT_BOTTOM' then return 'BOTTOMLEFT',  'BOTTOMRIGHT', 1, 0
    end
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


-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {
        font = 'Dorispp',
        statusbar = 'Armory',
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

                width = 135,
                height = 40,

                health = {
                    reverseFill = false,
                    orientation = 'HORIZONTAL'
                },
                power = {
                    enabled = true,
                    height = 10
                },
                portrait = {
                    enabled = false,
                },
                resurrectIndicator = {
                    enabled = true,
                    size = -1,
                    anchorPoint = 'CENTER',
                    xOffset = 0,
                    yOffset = 0,
                },
                summonIndicator = {
                    enabled = true,
                    size = -1,
                    anchorPoint = 'CENTER',
                    xOffset = 0,
                    yOffset = 0,
                },
            },
            player = {
                width = 227,
                restingIndicator = {
                    enabled = true,
                    size = 20,
                    anchorPoint = 'BOTTOMLEFT',
                    xOffset = 10,
                    yOffset = 2,
                },
                combatIndicator = {
                    enabled = true,
                    size = 20,
                    anchorPoint = 'BOTTOMRIGHT',
                    xOffset = -10,
                    yOffset = 2,
                },
            },
            target = {
                width = 227,
            },
            focus = {},
            focustarget = {},
            pet = {
                height = 20,
                power = {
                    enabled = false
                }
            },
            pettarget = {
                height = 20,
                power = {
                    enabled = false
                }
            },
            targettarget = {
                height = 20,
                power = {
                    enabled = false
                }
            },
            targettargettarget = {
                height = 20,
                power = {
                    enabled = false
                }
            },

            -- groups
            boss = {
                direction = 'UP',
                spacing = 12,
            },

            -- headers
            party = {
                height = 80,

                portrait = {
                    enabled = true,
                    size = 40,
                },
                readyCheckIndicator = {
                    enabled = true,
                    size = -1,
                    anchorPoint = 'CENTER',
                    xOffset = 0,
                    yOffset = 0,
                },

                direction = 'UP',
                spacing = 50,
                sortBy = 'ROLE',
                visibility = '[group:party,nogroup:raid]show;hide;',
                numGroups = 1,
                groupsPerCol = 1,
                showPlayer = false,
            },
            partytarget = {
                side = 'RIGHT_BOTTOM',
                spacing = 12,
            },
            partypet = {
                height = 20,
                power = {
                    enabled = false,
                },

                side = 'BOTTOM',
                spacing = 8,
            },

            raid = {
                width = 65,

                health = {
                    orientation = 'VERTICAL'
                },
                power = {
                    height = 5
                },
                readyCheckIndicator = {
                    enabled = true,
                    size = -1,
                    anchorPoint = 'CENTER',
                    xOffset = 0,
                    yOffset = 0,
                },

                direction = 'RIGHT_UP',
                spacing = 6,
                sortBy = 'ROLE',
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

    -- Register our style function
    oUF:RegisterStyle('Zoey', self.InitObject)
    oUF:RegisterStyle('ZoeyThin', self.InitObject)
    oUF:RegisterStyle('ZoeySquare', self.InitObject)

    -- Every object gets a update method to update its style
    oUF:RegisterMetaFunction('Update', self.UpdateObject)

    -- Element Creation and Configuration helpers
    oUF:RegisterMetaFunction('HasElement', self.HasElement)
    oUF:RegisterMetaFunction('CreateElement', self.CreateElement)
    oUF:RegisterMetaFunction('ConfigureElement', self.ConfigureElement)
    oUF:RegisterMetaFunction('ConfigureAllElements', self.ConfigureAllElements)

    -- Immediately update the object after updating it.
    oUF:RegisterInitCallback(self.UpdateObject)
end

function Module:OnEnable()
    self:DisableBlizzard()
    self:UpdateColors()
    self:LoadUnits()
end

-- Update all database references
function Module:OnProfileRefresh()
    -- Update all objects which oUF has initialized.
    for i, object in pairs(oUF.objects) do
        object.db = self.db.profile.units[object.objectName]
    end

    -- Group Holder
    for name, group in pairs(self.groups) do
        group.db = self.db.profile.units[name]
    end

    -- Header Holder
    for name, holder in pairs(self.headers) do
        holder.db = self.db.profile.units[name]
        for group = 1, #holder do
            holder[group].db = holder.db
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

    -- TODO add threat color
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

--------------------------------------------------------------------------------
function Module.CreateStatusBar(parent, noBG)
    local sb = CreateFrame('StatusBar', nil, parent)
    sb:SetStatusBarTexture(Addon.Media:Fetch('statusbar', Module.db.profile.statusbar))

    if not noBG then
        sb.bg = sb:CreateTexture(nil, 'BACKGROUND')
        sb.bg:SetTexture(Addon.Media:Fetch('statusbar', Module.db.profile.statusbar))
        sb.bg:SetAllPoints(true)
        sb.bg.multiplier = 0.4
    end

    return sb
end

function Module.CreateFontString(parent, size, justify)
    local fs = parent:CreateFontString(nil, 'ARTWORK')
    fs:SetFont(Addon.Media:Fetch('font', Module.db.profile.font), size or 16)
    fs:SetJustifyH(justify or 'LEFT')
    fs:SetWordWrap(false)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0,0,0,1)

    return fs
end


--[[------------------------------------------------------------------ Elements --
    Some functions to make creating and updating elements easier.

    By keeping a list of elements that have ben created on an object,
    we can easly loop over that list and update each one. This will reduce
    duplicate code.
]]
local existingElements, orderedElements = {},{}

-- Check if a element already exists on the given object.
function Module.HasElement(object, name, silent)
    local elements = existingElements[object]

    if not elements and not silent then
        error(L['No elements created on object \'%s\'']:format(object:GetName()), 2)
    end

    return elements[name] and true or false
end

-- Create an element on the given frame.
function Module.CreateElement(object, name, ...)
    -- Insure that the entry for the object exists.
    if not existingElements[object] then
        existingElements[object] = {}
        orderedElements[object] = {}
    end

    if Module.HasElement(object, name, true) then
        error(L['Can not add element \'%s\' to \'%s\' as it already exists.']:format(name, object:Getname()), 2)
    end

    Module['Create'..name](object, ...)

    existingElements[object][name] = true
    tinsert(orderedElements[object], name)
end

-- Configure an element.
function Module.ConfigureElement(object, name, ...)
    if not Module.HasElement(object, name, true) then
        error(L['No element named \'%s\' on object \'%s\'']:format(name, object:GetName()), 2)
    end

    local updateFunc = Module['Configure'..name]
    if updateFunc then updateFunc(object, ...) end
end

function Module.ConfigureAllElements(object, silent)
    for _, name in ipairs(orderedElements[object]) do
        Module.ConfigureElement(object, name)
    end
end

--------------------------------------------------------------------------------
-- This is the function that oUF calls after it initializes an object.
function Module.InitObject(object, unit, isSingle)
    -- Clean unit names like 'boss1'
    unit = unit:gsub('%d', '')

    -- We can trust that the 'unit' passed will be the correct database key.
    -- Following execution, if it came from oUF:Spawn its the first parameter;
    -- If it came from oUF:SpawnHeader its the 'oUF-guessUnit', which we force
    -- the value of in 'oUF-initialConfigFunction'
    object.db = Module.db.profile.units[unit]
    object.isSingle = isSingle
    object.objectName = unit

    -- Set the Frame's initial size
    if isSingle then -- Header units' size are set in oUF-initialConfigFunction
        object:SetSize(object.db.width, object.db.height)
    end

    -- Child frames comes from xml templates and need their initial anchoring
    -- and size set, but those are protected actions, and cant be done in combat.
    if object.isChild then
        Addon:RunAfterCombat(function()
            local point, relativePoint, xMult, yMult = getSideAnchorPoints(object.db.side)
            object:SetPoint(point, object:GetParent(), relativePoint, object.db.spacing * xMult, object.db.spacing * yMult)
            object:SetSize(object.db.width, object.db.height)
        end)
    end

    -- Temp: The UnitPetTemplate uses a different style then the parent object
    if object.isChild and unit:match('.+pet') then object.style = 'ZoeyThin' end

    -- Make the frame interactiveable
    object:RegisterForClicks('AnyUp') -- TODO: make this an option?
    object:SetScript('OnEnter', UnitFrame_OnEnter)
    object:SetScript('OnLeave', UnitFrame_OnLeave)

    -- Overlay Frame -- used to attach icons/text to
    object.Overlay = CreateFrame('Frame', nil, object)
    object.Overlay:SetAllPoints(object)
    object.Overlay:SetFrameLevel(10) -- TODO: does it have to be that high?

    -- Finish building the Style
    Module:ConstructStyle(object, unit, isSingle)
end

-- Every oUF object has an 'Update' method, which is this function.
function Module.UpdateObject(object)
    -- Update the frame Size -- This should be fine, since its combat protected
    object:SetSize(object.db.width, object.db.height)

    Module:UpdateStyle(object)

    -- Update all oUF elements, something with them may have changed.
    object:UpdateAllElements('ForceUpdate')
end

-------------------------------------------------------------------- Creating --
-- Methods only for single units. We may want to do other things
-- that's tied to just this specific unit, and not all oUF objects
-- (like changing enabled state of this unit on update)
local unitMethods = {}
function unitMethods:Update()
    Module.UpdateObject(self)
end

function Module:CreateUnit(unit)
    local unit = unit:lower()

    -- If it doesnt exist, create it!
    if not self.units[unit] then
        local object = oUF:Spawn(unit, 'ZoeyUI_'..unitToPascalCase(unit))

        for k, v in pairs(unitMethods) do
            object[k] = v
        end

        self.units[unit] = object
    end

    return self.units[unit]
end

local groupMethods = {}
function groupMethods:Update()
    local db = self.db

    local point = directionToAnchorPoint[db.direction]
    local relativePoint, xMult, yMult = getRelativeAnchorPoint(point)

    for i = 1, #self do
        local child = self[i]

        -- Update the unit
        child:Update()

        -- and re-anchor them
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

function Module:CreateGroup(group, numUnits)
    local group = group:lower()

    -- If it doesnt exist, create it!
    if not self.groups[group] then
        local holder = CreateFrame('Frame', 'ZoeyUI_'..unitToPascalCase(group), ZoeyUI_PetBattleFrameHider)
        holder.db = self.db.profile.units[group]

        for i = 1, tonumber(numUnits) or 5 do
            local object = oUF:Spawn(group..i, 'ZoeyUI_'..unitToPascalCase(group..i))
            object:SetParent(holder)
            holder[i] = object
        end

        for k, v in pairs(groupMethods) do
            holder[k] = v
        end

        --[[ TODO: Fix bug
            `self.UpdateObject` is called twice, once just after oUF initializes
            the object and again after when we call the 'Update' method, which
            is needed to configure things.

            It's not a major issue, it only happens durning initial loading,
            but it bothers me none-the-less.

        ]]

        holder:Update()

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
    if db.sortBy == 'CLASS' then
        self:SetAttribute('groupBy', 'CLASS')
        self:SetAttribute('groupingOrder', 'WARRIOR,PALADIN,HUNTER,ROGUE,PRIEST,DEATHKNIGHT,SHAMAN,MAGE,WARLOCK,MONK,DRUID,DEMONHUNTER')
        self:SetAttribute('sortMethod', 'NAME')
    elseif db.sortBy == 'CLASS_ALPH' then
        self:SetAttribute('groupBy', 'CLASS')
        self:SetAttribute('groupingOrder', 'DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,ROGUE,SHAMAN,WARLOCK,WARRIOR')
        self:SetAttribute('sortMethod', 'NAME')
    elseif db.sortBy == 'ROLE' then
        self:SetAttribute('groupBy', 'ASSIGNEDROLE')
        self:SetAttribute('groupingOrder', 'TANK,HEALER,DAMAGER,NONE')
        self:SetAttribute('sortMethod', 'NAME')
    elseif db.sortBy == 'NAME' then
        self:SetAttribute('groupBy', nil)
        self:SetAttribute('groupingOrder', nil)
        self:SetAttribute('sortMethod', 'NAME')
    elseif db.sortBy == 'GROUP' then
        self:SetAttribute('groupBy', 'GROUP')
        self:SetAttribute('groupingOrder', '1,2,3,4,5,6,7,8')
        self:SetAttribute('sortMethod', 'INDEX')
    end

    self:SetAttribute('sortDir', db.sortDir or 'ASC')
    self:SetAttribute("showPlayer", db.showPlayer)

    for i = 1, #self do
        local child = self[i]

        -- Call the update metamethod
        child:Update()

        -- Need to clear the points of the child for the SecureGroupHeader_Update
        -- to anchor, incase attributes change after first Update.
        child:ClearAllPoints()

        -- Grand children come from templates.
        if child.hasChildren then -- hasChildren and isChild come from oUF initObject
            for i, grandChild in pairs({child:GetChildren()}) do
                if grandChild.isChild then
                    -- A child frame comes from xml templates and its anchoring is configurable
                    local point, relativePoint, xMult, yMult = getSideAnchorPoints(grandChild.db.side)

                    -- Call the update metamethod
                    grandChild:Update()

                    -- and re-anchor them
                    grandChild:ClearAllPoints()
                    grandChild:SetPoint(point, child, relativePoint, grandChild.db.spacing * xMult, grandChild.db.spacing * yMult)
                end
            end
        end
    end

    -- Reenable Updating and set a attribute to force an update
    self:SetAttribute('_ignore', oldIgnore)
    self:SetAttribute('ForceUpdate')
end

local function createChildHeader(parent, childName, headerName, template, headerTemplate)
    local header = parent.headerName or headerName

    -- template is use by SecureGroupHeaders when creating new units, and
    -- headerTemplate is use by oUF when creating the header frame.
    local template = parent.template or template
    local headerTemplate = parent.headerTemplate or headerTemplate

    local db = parent.db

    local object = oUF:SpawnHeader('ZoeyUI_'..unitToPascalCase(header)..childName, headerTemplate, nil,
        -- These are all set so the header will show in all situations.
        -- Visibility will be controlled with RegisterStateDriver()
        'showRaid', true, 'showParty', true, 'showSolo', true,

        -- oUF-initialConfigFunction is called when a new object is created by
        -- 'SecureGroupHeader', and we will use use it to override what oUF
        -- guesses the unit is, becase the above settings, it'll always be 'raid'

        -- We also have to set unit's default size. We do this here because if
        -- a frame happens to be created in combat by 'SecureGroupHeaders'
        -- there wont be any errors, because it's a secure environment.

        -- We don't set child frames because their not THAT important. Plus they
        -- also need anchoring set. Both of which will be taken care of
        -- in InitObject, after combat ends.

        -- Note: There is no `SetSize` mirror for restricted frames
        'oUF-initialConfigFunction', ([[
            local unit = '%s'
            local suffix = self:GetAttribute('unitsuffix')
            if suffix then
                unit = unit .. suffix
            else
                self:SetWidth(%d) self:SetHeight(%d)
            end
            self:SetAttribute('oUF-guessUnit', unit)
        ]]):format(header, db.width, db.height),
        template and 'template', template
    )

    object:SetParent(parent)
    object.headerName = header
    object.db = db

    for k, v in pairs(headerMethods) do
        object[k] = v
    end

    return object
end

local holderMethods = {}
function holderMethods:Update()
    local db = self.db

    -- How many child headers do we need
    local numChildHeaders = db.raidWideSorting and 1 or db.numGroups

    -- Create any child headers that are needed.
    while numChildHeaders > #self do
        self[#self + 1] = createChildHeader(self, 'Group'..(#self + 1))
    end

    -- Update visibility. Only update if changed, and not forced
    if not self.visibility or self.visibility ~= db.visibility then
        self.visibility = db.visibility

        RegisterStateDriver(self, 'visibility', self.isForced and 'show' or self.visibility)
    end

    -- Hide child headers that aren't used.
    for i = numChildHeaders + 1, #self do
        local childHeader = self[i]

        childHeader:Hide()
        childHeader:ClearAllPoints()
    end

    local point = directionToAnchorPoint[db.direction]
    local relativePoint, xMult, yMult = getRelativeAnchorPoint(point)

    local columnAnchorPoint = directionToColumnAnchorPoint[db.direction]
    local relativeColumnAnchorPoint, colxMult, colyMult = getRelativeAnchorPoint(columnAnchorPoint)

    local horizontalSpacing = db.horizontalSpacing or db.spacing
    local verticalSpacing = db.verticalSpacing or db.spacing
    local numRows = ceil(db.numGroups / db.groupsPerCol)

    -- Guesstimate the size of one group
    local unitWidth, unitHeight = db.width, db.height

    local groupWidth = abs(xMult) * (unitWidth + horizontalSpacing) * 4 + unitWidth
    local groupHeight = abs(yMult) * (unitHeight + verticalSpacing) * 4 + unitHeight

    -- Only update the groups we're using
    for i = 1, numChildHeaders do
        local childHeader = self[i]

        -- Disable SecureGroupHeader from updating on attribute changes.
        local oldIgnore = childHeader:GetAttribute('_ignore')
        childHeader:SetAttribute('_ignore', 'attributeChanges')

        -- Update child headers
        childHeader:Update()

        -- A child header doesnt know what group it is
        if i == 1 and db.raidWideSorting then
            childHeader:SetAttribute('groupFilter', strsub('1,2,3,4,5,6,7,8', 1, db.numGroups * 2 - 1))
        else
            childHeader:SetAttribute('groupFilter', tostring(i))
        end

        -- Setup column settings
        if point == 'LEFT' or point == 'RIGHT' then
            childHeader:SetAttribute('columnSpacing', verticalSpacing)
        else
            childHeader:SetAttribute('columnSpacing', horizontalSpacing)
        end

        childHeader:SetAttribute('columnAnchorPoint', columnAnchorPoint)
        childHeader:SetAttribute('maxColumns', db.raidWideSorting and numRows or 1)
        childHeader:SetAttribute('unitsPerColumn', db.raidWideSorting and (db.groupsPerCol * 5) or 5)

        -- Reenable Updating and set a attribute to force an update
        childHeader:SetAttribute('_ignore', oldIgnore)
        childHeader:SetAttribute('ForceUpdate')
        childHeader:Show()

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
    local width = abs(xMult) * (groupWidth + horizontalSpacing) * (min(db.numGroups, db.groupsPerCol) - 1) + groupWidth
    local height = abs(yMult) * (groupHeight + verticalSpacing) * (min(db.numGroups, db.groupsPerCol) - 1) + groupHeight

    -- Then increase by the number of rows
    width = abs(colxMult) * (width + horizontalSpacing) * (numRows - 1) + width
    height = abs(colyMult) * (height + verticalSpacing) * (numRows - 1) + height

    self:SetWidth(width)
    self:SetHeight(height)
end

function Module:CreateHeader(header, template, headerTemplate)
    local header = header:lower()

    if not self.headers[header] then
        local holder = CreateFrame('Frame', 'ZoeyUI_'..unitToPascalCase(header), ZoeyUI_PetBattleFrameHider, 'SecureHandlerStateTemplate');
        holder.db = self.db.profile.units[header]
        holder.headerName = header
        holder.template = template
        holder.headerTemplate = headerTemplate

        for k, v in pairs(holderMethods) do
            holder[k] = v
        end

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

    self:CreateHeader('Party', 'ZoeyUI_UnitTargetTemplate, ZoeyUI_UnitPetTemplate')
        :SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', gap, 240)

    oUF:SetActiveStyle('ZoeySquare')
    self:CreateHeader('Raid'):SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 240)
end

----------------------------------------------------------- Combat Protection --
-- We shouldn't run these methods durning combat. Could cause errors.
-- Changing points, anchors, sizes on protected frames.
Module.UpdateObject = Addon:AfterCombatWrapper(Module.UpdateObject)
groupMethods.Update = Addon:AfterCombatWrapper(groupMethods.Update)
headerMethods.Update = Addon:AfterCombatWrapper(headerMethods.Update)
holderMethods.Update = Addon:AfterCombatWrapper(holderMethods.Update)
