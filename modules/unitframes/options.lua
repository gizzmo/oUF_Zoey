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

    options.args.generalGroup = {
        order = new_order(),
        type = 'group',
        name = L["General Options"],
        -- get = function(info) return Module.db.profile[ info[#info] ] end,
        -- set = function(info, value) Module.db.profile[ info[#info] ] = value end,
        args = {
            outOfRangeAlpha = {
                order = new_order(),
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
                guiInline = true,
                name = L["Status Bars"],
                args = {
                    statusbar = {
                        type = "select", dialogControl = 'LSM30_Statusbar',
                        order = 3,
                        name = L["Texture"],
                        desc = L["Main statusbar texture."],
                        values = AceGUIWidgetLSMlists.statusbar,
                    },
                },
            },

            fontGroup = {
                order = new_order(),
                type = 'group',
                guiInline = true,
                name = L["Fonts"],
                args = {
                    font = {
                        type = "select", dialogControl = 'LSM30_Font',
                        order = 4,
                        name = L["Default Font"],
                        desc = L["The font that the unitframes will use."],
                        values = AceGUIWidgetLSMlists.font,
                    },
                    fontSize = {
                        order = 5,
                        name = FONT_SIZE,
                        desc = L["Set the font size for unitframes."],
                        type = "range",
                        min = 4, max = 212, step = 1,
                    },
                },
            },
        },
    }

    for name, group in pairs(Module.groups) do
        options.args[name] = {
            order = new_order(),
            type = 'group',
            childGroups = 'tab',
            name = L[group:GetName():sub(8)], -- Removes 'ZoeyUI_'

            get = function(info) return Module.db.profile.units[name][info[#info]] end,
            set = function(info, value) Module.db.profile.units[name][info[#info]] = value group:Update() end,

            args = {
                generalGroup = {
                    order = new_order(),
                    type = 'group',
                    name = L["Size and Position"],
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
                            min = 0, max = 100, step = 1,
                        },
                    },
                },
            },
        }
    end


    for name, header in pairs(Module.headers) do
        options.args[name] = {
            order = new_order(),
            type = 'group',
            childGroups = 'tab',
            name = L[header:GetName():sub(8)], -- Removes 'ZoeyUI_'

            get = function(info) return Module.db.profile.units[name][info[#info]] end,
            set = function(info, value) Module.db.profile.units[name][info[#info]] = value header:Update() end,

            args = {
                generalGroup = {
                    order = new_order(),
                    type = 'group',
                    name = L["Size and Position"],
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
                            min = 0, max = 100, step = 1,
                        },
                        verticalSpacing = {
                            order = new_order(),
                            type = "range",
                            name = L["Vertical Spacing"],
                            min = 0, max = 100, step = 1,
                        },
                    },
                },
            },
        }
    end

    return options
end
