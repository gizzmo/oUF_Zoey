local ADDON_NAME, Addon = ...
local L = Addon.L

local Module = Addon:GetModule('Unitframes')

local _, playerClass = UnitClass('player')

--------------------------------------------------------------------------------
local growthDirectionValues = {
    UP_LEFT = format(L['%s and then %s'],    L['Up'], L['Left']),
    UP_RIGHT = format(L['%s and then %s'],   L['Up'], L['Right']),
    DOWN_LEFT = format(L['%s and then %s'],  L['Down'], L['Left']),
    DOWN_RIGHT = format(L['%s and then %s'], L['Down'], L['Right']),
    LEFT_UP = format(L['%s and then %s'],    L['Left'], L['Up']),
    LEFT_DOWN = format(L['%s and then %s'],  L['Left'], L['Down']),
    RIGHT_UP = format(L['%s and then %s'],   L['Right'], L['Up']),
    RIGHT_DOWN = format(L['%s and then %s'], L['Right'], L['Down']),
}
local singleGrowthDirectionValues = {
    UP = L['Up'],
    DOWN = L['Down'],
    LEFT = L['Left'],
    RIGHT = L['Right'],
}
local sideAnchorValues = {
    TOP_LEFT    = format(L['%s and then %s'], L['Top'], L['Left']),
    TOP         = format(L['%s and then %s'], L['Top'], L['Middle']),
    TOP_RIGHT   = format(L['%s and then %s'], L['Top'], L['Right']),
    BOTTOM_LEFT = format(L['%s and then %s'], L['Bottom'], L['Left']),
    BOTTOM      = format(L['%s and then %s'], L['Bottom'], L['Middle']),
    BOTTOM_RIGHT= format(L['%s and then %s'], L['Bottom'], L['Right']),
    LEFT_TOP    = format(L['%s and then %s'], L['Left'], L['Top']),
    LEFT        = format(L['%s and then %s'], L['Left'], L['Middle']),
    LEFT_BOTTOM = format(L['%s and then %s'], L['Left'], L['Bottom']),
    RIGHT_TOP   = format(L['%s and then %s'], L['Right'], L['Top']),
    RIGHT       = format(L['%s and then %s'], L['Right'], L['Middle']),
    RIGHT_BOTTOM= format(L['%s and then %s'], L['Right'], L['Bottom']),
}

--------------------------------------------------------------------------------
-- To make tables ordered by how they are constructed
local new_order
do
    local current = 0
    function new_order(reset)
        current = reset and (tonumber(reset) or 1) or current + 1
        return current
    end
end

------------------------------------------------------------- General Options --
local function get_general_options()
    local options =  {
        type = 'group',
        name = L["General Options"],
        -- get = function(info) return Module.db.profile[ info[#info] ] end,
        -- set = function(info, value) Module.db.profile[ info[#info] ] = value end,
        args = {
            outOfRangeAlpha = {
                order = new_order(1),
                name = L["Out of range Alpha"],
                desc = L["The alpha to set units that are out of range to."],
                type = 'range',
                min = 0, max = 1, step = 0.01,
            },
            debuffHighlighting = {
                order = new_order(),
                name = L["Debuff Highlighting"],
                desc = L["Color the unit healthbar if there is a debuff that can be dispelled by you."],
                type = 'select',
                values = {
                    ['NONE'] = NONE,
                    ['GLOW'] = L["Glow"],
                    ['FILL'] = L["Fill"]
                },
            },
            barGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L["Status Bars"],
                args = {
                    statusbar = {
                        type = "select", dialogControl = 'LSM30_Statusbar',
                        name = L["Texture"],
                        desc = L["Main statusbar texture."],
                        values = AceGUIWidgetLSMlists.statusbar,
                    },
                },
            },
            fontGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L["Fonts"],
                args = {
                    font = {
                        type = "select", dialogControl = 'LSM30_Font',
                        name = L["Default Font"],
                        desc = L["The font that the unitframes will use."],
                        values = AceGUIWidgetLSMlists.font,
                    },
                    fontSize = {
                        name = FONT_SIZE,
                        desc = L["Set the font size for unitframes."],
                        type = "range",
                        min = 4, max = 212, step = 1,
                    },
                },
            },
        },
    }

    options.args.colorsGroup = {
        order = new_order(),
        type = 'group',
        name = L["Colors"],

        -- Smart functions to deal with both colos and other types
        get = function(info)
            local db = Module.db.profile.colors
            local key = info[#info]

            local data = db[ key ]

            if not data then -- check one deeper that matches the group key
                local parent = (info[#info-1]):sub(0, -6)
                data = db[parent][ key ]
            end

            if info.type == 'color' then
                return data[1], data[2], data[3], data[4]
            elseif info.type == 'toggle' or info.type == 'range' then
                return data
            else
                error('Unknown type used for colors get method.')
            end
        end,
        set = function(info, ...)
            local db = Module.db.profile.colors
            local key = info[#info]
            local parent = (info[#info-1]):sub(0, -6)

            if info.type == 'color' then
                local data = db[key]

                if not data then
                    data = db[parent][key]
                end
                data[1], data[2], data[3], data[4] = ...

            elseif info.type == 'toggle' or info.type == 'range' then
                if db[key] ~= nil then
                    db[key] = ...
                else
                    db[parent][key] = ...
                end
            else
                error('Unknown type used for colors set method.')
            end
            Module:UpdateAll()
        end,

        args = {
            healthGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L['Health'],
                args = {
                    -- IDEA: use select radio
                    health_class = {
                        order = new_order(),
                        type = 'toggle',
                        name = L["Class Health"],
                        desc = L["Color health by player class or reaction."],
                    },
                    health_force_reaction = {
                        order = new_order(),
                        type = 'toggle',
                        name = L['Force Reaction Color'],
                        desc = L['Forces reaction color instead of class color on player units.'],
                        disabled = function(info) return not Module.db.profile.colors.health_class end
                    },
                    health_by_value = {
                        order = new_order(),
                        type = 'toggle',
                        name = L["Health By Value"],
                        desc = L['Color with a smooth gradient based on the units health percentage.'],
                    },
                    health = {
                        order = new_order(),
                        type = 'color',
                        name = L['Health'],
                        desc = L['Use this custom color if none of the above options are enabled.'],
                    },

                    spacer1 = {
                        order = new_order(),
                        type = 'description',
                        name = ' ',
                    },
                    health_backdrop_class = {
                        order = new_order(),
                        type = 'toggle',
                        name = L["Class Backdrop"],
                        desc = L["If the unit is controlled by a player, color by their class."],
                    },
                    health_backdrop_custom = {
                        order = new_order(),
                        type = 'toggle',
                        name = L["Custom Backdrop"],
                        desc = L["Use the custom health backdrop color instead of a multiplier."],
                    },
                    health_backdrop = {
                        order = new_order(),
                        type = 'color',
                        name = L["Backdrop Color"],
                        disabled = function(info) return not Module.db.profile.colors.health_backdrop_custom end
                    },

                    use_health_backdrop_dead = {
                        order = new_order(),
                        type = "toggle",
                        name = L["Use Dead Backdrop"],
                        desc = L['Use a custom backdrop color for units that are dead or ghosts.'],
                    },
                    health_backdrop_dead = {
                        order = new_order(),
                        type = 'color',
                        name = L['Custom Dead Backdrop'],
                        disabled = function(info) return not Module.db.profile.colors.use_health_backdrop_dead end
                    },

                    spacer2 = {
                        order = new_order(),
                        type = 'description',
                        name = ' ',
                    },
                    tapped = {
                        order = new_order(),
                        type = 'color',
                        name = L['Tapped'],
                        desc = L['The color of the frame when the unit been tapped by the other faction.'],
                    },
                    disconnected = {
                        order = new_order(),
                        type = 'color',
                        name = L['Disconnected'],
                        desc = L['The color the bar when a unit is disconnected.'],
                    },
                },
            },
            powerGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L['Power'],
                args = {
                    power_class = {
                        order = new_order(),
                        type = 'toggle',
                        name = L["Class Power"],
                        desc = L["If the unit is controlled by a player, color by their class."],
                    },
                    power_custom = {
                        order = new_order(),
                        type = 'toggle',
                        name = L['Custom Power'],
                        desc = L['Color power bar with a custom color.'],
                    },
                    custom = {
                        order = new_order(),
                        type = 'color',
                        name = L['Power'],
                        disabled = function(info) return not Module.db.profile.colors.power_custom end
                    },

                    -- Basic Power Types
                    key = {
                        order = new_order(),
                        type = 'header',
                        name = L['Basic Power Types'],
                    },

                    MANA = { order = new_order(), type = 'color', name = MANA },
                    RAGE = { order = new_order(), type = 'color', name = RAGE },
                    FOCUS = { order = new_order(), type = 'color', name = FOCUS },
                    ENERGY = { order = new_order(), type = 'color', name = ENERGY },
                    -- TODO add into own section to allow for "max combo points color"
                    COMBO_POINTS = { order = new_order(), type = 'color', name = COMBO_POINTS },
                    RUNIC_POWER = { order = new_order(), type = 'color', name = RUNIC_POWER },
                    LUNAR_POWER = { order = new_order(), type = 'color', name = LUNAR_POWER },
                    MAELSTROM = { order = new_order(), type = 'color', name = MAELSTROM },
                    INSANITY = { order = new_order(), type = 'color', name = INSANITY },
                    FURY = { order = new_order(), type = 'color', name = FURY },
                    PAIN = { order = new_order(), type = 'color', name = PAIN },

                    -- Class Resource
                    RUNES = {
                        order = new_order(), type = 'color', name = RUNES,
                        hidden = function(info) return playerClass ~= 'DEATHKNIGHT' end,
                    },
                    SOUL_SHARDS = {
                        order = new_order(), type = 'color', name = SOUL_SHARDS,
                        hidden = function(info) return playerClass ~= 'WARLOCK' end,
                    },
                    HOLY_POWER = {
                        order = new_order(), type = 'color', name = HOLY_POWER,
                        hidden = function(info) return playerClass ~= 'PALADIN' end,
                    },
                    CHI = { -- TODO: multiple colors for each one
                    order = new_order(), type = 'color', name = CHI,
                        hidden = function(info) return playerClass ~= 'MONK' end,
                    },
                    ARCANE_CHARGES = {
                        order = new_order(), type = 'color', name = ARCANE_CHARGES,
                        hidden = function(info) return playerClass ~= 'MAGE' end,
                    },
                },
            },

            staggerGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L['Stagger'],

                hidden = function(info) return playerClass ~= 'MONK' end,

                get = function(info)
                    local db = Module.db.profile.colors.power.STAGGER
                    return unpack(db[ info.arg ])
                end,
                set = function(info, ...)
                    local db = Module.db.profile.colors.power.STAGGER
                    local data = db[ info.arg ]
                    data[1], data[2], data[3], data[4] = ...
                    Module:UpdateAll()
                end,

                args = {
                    light = {
                        order = new_order(),
                        type = 'color',
                        name = L['Light'],
                        arg = 1, -- AceConfig doesnt like keys not being strings
                                 -- So we use the arg option for the key of the
                                 -- STAGGER table
                    },
                    moderate = {
                        order = new_order(),
                        type = 'color',
                        name = L['Moderate'],
                        arg = 2,
                    },
                    heavy = {
                        order = new_order(),
                        type = 'color',
                        name = L['Heavy'],
                        arg = 3,
                    },
                },
            },
            healthPredictionGroup = {
                order = new_order(),
                name = L["Health Prediction"],
                type = 'group',
                inline = true,

                args = {
                    personal = {
                        order = new_order(),
                        name = L["Personal"],
                        type = 'color',
                        hasAlpha = true,
                    },
                    others = {
                        order = new_order(),
                        name = L["Others"],
                        type = 'color',
                        hasAlpha = true,
                    },
                    absorbs = {
                        order = new_order(),
                        name = L["Absorbs"],
                        type = 'color',
                        hasAlpha = true,
                    },
                    healAbsorbs = {
                        order = new_order(),
                        name = L["Heal Absorbs"],
                        type = 'color',
                        hasAlpha = true,
                    },
                    maxOverflow = {
                        order = new_order(),
                        type = "range",
                        name = L["Max Overflow"],
                        desc = L["Max amount of overflow allowed to extend past the end of the health bar."],
                        isPercent = true,
                        min = 0, max = 1, step = 0.01,
                    },
                },
            },
            debuffHighlightGroup = {
                order = new_order(),
                name = L["Debuff Highlighting"],
                type = 'group',
                inline = true,

                args = {
                    Magic = {
                        order = new_order(),
                        name = ENCOUNTER_JOURNAL_SECTION_FLAG7,--Magic Effect
                        type = 'color',
                        hasAlpha = true,
                    },
                    Curse = {
                        order = new_order(),
                        name = ENCOUNTER_JOURNAL_SECTION_FLAG8,--Curse Effect
                        type = 'color',
                        hasAlpha = true,
                    },
                    Poison = {
                        order = new_order(),
                        name = ENCOUNTER_JOURNAL_SECTION_FLAG9,--Poison Effect
                        type = 'color',
                        hasAlpha = true,
                    },
                    Disease = {
                        order = new_order(),
                        name = ENCOUNTER_JOURNAL_SECTION_FLAG10,--Disease Effect
                        type = 'color',
                        hasAlpha = true,
                    },
                },
            },
            reactionGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L["Reactions"],
                args = {
                    HATED = {
                        order = new_order(),
                        name = L["Bad"],
                        type = 'color',
                    },
                    UNFRIENDLY = {
                        order = new_order(),
                        name = L["Unfriendly"],
                        type = 'color',
                    },
                    NEUTRAL = {
                        order = new_order(),
                        name = L["Neutral"],
                        type = 'color',
                    },
                    GOOD = {
                        order = new_order(),
                        name = L['Great'],
                        type = 'color'
                    },
                },
            },
            classificationGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L['Classifications'],

                args = {
                    rare = {
                        order = new_order(),
                        type = 'color',
                        name = L['Rare'],
                    },
                    rareelite = {
                        order = new_order(),
                        type = 'color',
                        name = L['Rare-Elite'],
                    },
                    elite = {
                        order = new_order(),
                        type = 'color',
                        name = L['Elite'],
                    },
                    boss = {
                        order = new_order(),
                        type = 'color',
                        name = L['Boss'],
                    },
                },
            },
            castGroup = {
                order = new_order(),
                type = 'group',
                inline = true,
                name = L['Cast Bars'],

                args = {
                    normal = {
                        order = new_order(),
                        type = 'color',
                        name = L['Normal'],
                    },
                    success = {
                        order = new_order(),
                        type = 'color',
                        name = L['Success'],
                        desc = L['Color the castbar when its successfully cast.']
                    },
                    failed = {
                        order = new_order(),
                        type = 'color',
                        name = L['Failed'],
                        desc = L['Color the castbar the cast failed.']
                    },
                    safezone = {
                        order = new_order(),
                        type = 'color',
                        name = L['Safezone'],
                        desc = L['Color representing latency on the cast.'],
                        hasAlpha = true,
                    },
                }
            },
        },
    }

    return options
end

----------------------------------------------------------- Handler Prototype --
local handlerPrototype = {}
function handlerPrototype:Get(info)
    return self.object.db[info[#info]]
end
function handlerPrototype:Set(info, value)
    self.object.db[info[#info]] = value
    self.object:Update()
end
function handlerPrototype:GetName()
    return self.object:GetName():sub(8) -- Removes 'ZoeyUI_'
end

-- Cant use string access to access the handler form the table.
local function getName(info)
    return info.handler:GetName()
end

---------------------------------------------------------------- Unit Options --
local unitOptionsTable = {
    generalGroup = {
        order = new_order(10),
        type = 'group',
        inline = true,
        name = L['General'],

        args = {
            enable = {
                order = new_order(),
                type = 'toggle',
                name = L['Enable'],
                width = 'full',
                disabled = true, -- disabled because its not implemented.
            },
            width = {
                order = new_order(),
                name = L["Width"],
                type = 'range',
                min = 50, max = 1000, step = 1,
            },
            height = {
                order = new_order(),
                name = L["Height"],
                type = 'range',
                min = 10, max = 500, step = 1,
            },
        },
    },
}

local function create_unit_options(name, unit)
    local tbl = {
        type = 'group',
        childGroups = 'tab',
        name = getName,
        args = unitOptionsTable,
        handler = { name = name, object = unit },
        get = 'Get', set = 'Set',
    }

    for k, v in pairs(handlerPrototype) do
        tbl.handler[k] = v
    end

    return tbl
end


--------------------------------------------------------------- Group Options --
local groupOptionsTable = {
    growthAndSpacingGroup = {
        order = new_order(20),
        type = 'group',
        inline = true,
        name = L["Growth and Spacing"],
        args = {
            direction = {
                order = new_order(),
                type = "select",
                name = L["Growth Direction"],
                values = singleGrowthDirectionValues,
            },
            spacing = {
                order = new_order(),
                type = "range",
                name = L["Spacing"],
                min = 0, max = 400, step = 1,
            },
        },
    },
}

local function create_group_options(name, group)
    local tbl = {
        type = 'group',
        childGroups = 'tab',
        name = getName,
        args = groupOptionsTable,
        handler = { name = name, object = group },
        get = 'Get', set = 'Set',
    }

    -- merg in unit specific options
    for k, v in pairs(unitOptionsTable) do
        tbl.args[k] = v
    end

    for k, v in pairs(handlerPrototype) do
        tbl.handler[k] = v
    end

    return tbl
end

-------------------------------------------------------------- Header Options --
local headerOptionsTable = {
    growthAndSpacingGroup = {
        order = new_order(20),
        type = 'group',
        inline = true,
        name = L["Growth and Spacing"],
        args = {
            direction = {
                order = new_order(),
                type = "select",
                name = L["Growth Direction"],
                values = growthDirectionValues,
            },
            horizontalSpacing = {
                order = new_order(),
                type = "range",
                name = L["Horizontal Spacing"],
                min = 0, max = 400, step = 1,
                get = function(info)
                    local db = info.handler.object.db
                    return db.horizontalSpacing or db.spacing
                end
            },
            verticalSpacing = {
                order = new_order(),
                type = "range",
                name = L["Vertical Spacing"],
                min = 0, max = 400, step = 1,
                get = function(info)
                    local db = info.handler.object.db
                    return db.verticalSpacing or db.spacing
                end
            },
        },
    },
    sortingGroup = {
        order = new_order(),
        type = 'group',
        inline = true,
        name = L["Grouping and Sorting"],
        args = {
            raidWideSorting = {
                order = new_order(),
                type = 'toggle',
                name = L["Raid-Wide Sorting"],
                desc = L["Enabling this will make you not be able to distinguish between groups."],
            },
            numGroups = {
                order = new_order(),
                type = 'range',
                name = L["Number of Groups"],
                min = 1, max = 8, step = 1,
            },
            groupsPerCol = {
                order = new_order(),
                type = 'range',
                name = L["Groups per column"],
                desc = L["The number of groups before creating a new row."],
                min = 1, max = 8, step = 1,
                disabled = function(info)
                    return info.handler.object.db.numGroups == 1
                end
            },
            invertGroupGrowth = {
                order = new_order(),
                type = 'toggle',
                name = L['Invert group growth'],
                desc = L['Change how groups grow.'],
                disabled = function(info)
                    return info.handler.object.db.groupsPerCol == 1
                    or info.handler.object.db.raidWideSorting
                end
            },
            sortBy = {
                order = new_order(),
                name = L["Sort By"],
                desc = L["Set the order that the group will sort."],
                type = 'select',
                width = 1.15,
                values = {
                    CLASS = L["Class: classID"],
                    CLASS_ALPH = L["Class: Alphabetically"],
                    ROLE = L["Role: Tank, Healer, Damage"],
                    NAME = L["Name"],
                    GROUP = L["Group"],
                },
            },
        },
    },
    visibilityGroup = {
        order = new_order(),
        type = 'group',
        inline = true,
        name = L["Visibility"],
        args = {
            visibility = {
                order = new_order(),
                type = 'input',
                name = L["Visibility"],
                width = 'full',
                -- TODO: validation?
            },
            visibilityHelp = {
                order = new_order(),
                type = 'description',
                name = L["The above macro must be true in order for the group to be shown."],
                -- TODO: Add better explaination and examples
                fontSize = 'medium'
            },
        },
    },
}

-- Child frames
headerOptionsTable.targetChildGroup = {
    order = new_order(),
    type = 'group',
    inline = true,
    name = L['Target Child'],
    args = {
        sideAndSpacingGroup = {
            order = new_order(),
            type = 'group',
            name = L['Side Anchoring and Spacing'],
            args = {
                side = {
                    order = new_order(),
                    type = "select",
                    name = L["Side Anchor"],
                    desc = L['Attaching to which side, and then aligning.'],
                    values = sideAnchorValues,
                },
                spacing = {
                    order = new_order(),
                    type = "range",
                    name = L["Spacing"],
                    min = 0, max = 100, step = 1,
                },
            },
        },
    },
    -- Because child units' db are not attached to the handler/header,
    -- we have to use the option keys to find the db entry.
    get = function(info)
        local childUnit = info[2]..info[3]:sub(0, -11)
        return Module.db.profile.units[childUnit][info[#info]]
    end,
    set = function(info, value)
        local childUnit =  info[2]..info[3]:sub(0, -11)
        Module.db.profile.units[childUnit][info[#info]] = value

        -- This will trickle its way down to the child
        info.handler.object:Update()
    end,
    hidden = function(info)
        local childName = info[3]:sub(0, -11)
        local template = info.handler.object.template
        local hasTemplate = template and template:lower():match(childName)
        return not hasTemplate
    end,
}

-- header child object needs base unit options
for k, v in pairs(unitOptionsTable) do
    headerOptionsTable.targetChildGroup.args[k] = v
end

headerOptionsTable.petChildGroup = {
    order = new_order(),
    type = 'group',
    inline = true,
    name = L['Pet Child'],
    args = headerOptionsTable.targetChildGroup.args,
    get = headerOptionsTable.targetChildGroup.get,
    set = headerOptionsTable.targetChildGroup.set,
    hidden = headerOptionsTable.targetChildGroup.hidden,
}

local function create_header_options(name, header)
    local tbl = {
        type = 'group',
        childGroups = 'tab',
        name = getName,
        args = headerOptionsTable,
        handler = { name = name, object = header },
        get = 'Get', set = 'Set',
    }

    -- merg in unit specific options
    for k, v in pairs(unitOptionsTable) do
        tbl.args[k] = v
    end

    for k, v in pairs(handlerPrototype) do
        tbl.handler[k] = v
    end

    return tbl
end

--------------------------------------------------------------------- Options --
function Module.get_module_options()
    local options = {
        type = 'group',
        name = L['Unitframes'],
        args = {},
        childGroups = 'tree',
    }

    options.args.generalGroup = get_general_options()
    options.args.generalGroup.order = new_order(1)

    for name, unit in pairs(Module.units) do
        options.args[name] = create_unit_options(name, unit)
        options.args[name].order = 2
    end

    for name, group in pairs(Module.groups) do
        options.args[name] = create_group_options(name, group)
        options.args[name].order = 3
    end

    for name, header in pairs(Module.headers) do
        options.args[name] = create_header_options(name, header)
        options.args[name].order = 4
    end

    return options
end
