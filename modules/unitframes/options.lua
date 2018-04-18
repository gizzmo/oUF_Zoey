local ADDON_NAME, Addon = ...
local L = Addon.L

local Module = Addon:GetModule('Unitframes')

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

------------------------------------------------------------- General Options --
local function get_general_options()
    return {
        type = 'group',
        name = L["General Options"],
        -- get = function(info) return Module.db.profile[ info[#info] ] end,
        -- set = function(info, value) Module.db.profile[ info[#info] ] = value end,
        args = {
            outOfRangeAlpha = {
                name = L["Out of range Alpha"],
                desc = L["The alpha to set units that are out of range to."],
                type = 'range',
                min = 0, max = 1, step = 0.01,
            },
            debuffHighlighting = {
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
                type = 'group',
                guiInline = true,
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
                type = 'group',
                guiInline = true,
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
end

----------------------------------------------------------- Handler Prototype --
local handlerPrototype = {}
function handlerPrototype:Get(info)
    return Module.db.profile.units[self.name][info[#info]]
end
function handlerPrototype:Set(info, value)
    Module.db.profile.units[self.name][info[#info]] = value
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
local unitOptionsTable = {}

local function create_unit_options(name, unit)
    local tbl = {
        type = 'group',
        childGroups = 'tab',
        name = getName,
        args = unitOptionsTable,
        handler = { name = name, object = unit },
    }

    for k, v in pairs(handlerPrototype) do
        tbl.handler[k] = v
    end

    return tbl
end


--------------------------------------------------------------- Group Options --
local groupOptionsTable = {
    NoNameYetGroup = {
        order = 1,
        type = 'group',
        name = L["Size and Position"],
        get = 'Get',
        set = 'Set',

        args = {
            direction = {
                order = 1,
                type = "select",
                name = L["Growth Direction"],
                values = singleGrowthDirectionValues,
            },
            spacing = {
                order = 2,
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
    }

    for k, v in pairs(handlerPrototype) do
        tbl.handler[k] = v
    end

    return tbl
end

-------------------------------------------------------------- Header Options --
local headerOptionsTable = {
    NoNameYetGroup = {
        order = 1,
        type = 'group',
        name = L["Size and Position"],
        get = 'Get',
        set = 'Set',

        args = {
            direction = {
                order = 1,
                type = "select",
                name = L["Growth Direction"],
                values = growthDirectionValues,
            },
            horizontalSpacing = {
                order = 2,
                type = "range",
                name = L["Horizontal Spacing"],
                min = 0, max = 400, step = 1,
            },
            verticalSpacing = {
                order = 3,
                type = "range",
                name = L["Vertical Spacing"],
                min = 0, max = 400, step = 1,
            },
        },
    },
}

local function create_header_options(name, header)
    local tbl = {
        type = 'group',
        childGroups = 'tab',
        name = getName,
        args = headerOptionsTable,
        handler = { name = name, object = header },
    }

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
        childGroups = 'tab',
    }

    local new_order
    do
        local current = 0
        function new_order()
            current = current + 1
            return current
        end
    end

    options.args.generalGroup = get_general_options()
    options.args.generalGroup.order = new_order()

    for name, group in pairs(Module.groups) do
        options.args[name] = create_group_options(name, group)
        options.args[name].order = new_order()
    end

    for name, header in pairs(Module.headers) do
        options.args[name] = create_header_options(name, header)
        options.args[name].order = new_order()
    end

    return options
end
