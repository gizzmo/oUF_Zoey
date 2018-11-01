local ADDON_NAME, Addon = ...
local L = Addon.L

-- Libs
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

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

--------------------------------------------------------------------------------

local function get_general_options()
    local options = {
        type = 'group',
        name = L["General"],
        args = {},
        childGroups = 'tree',

        get = function(info) return Addon.db.profile.general[ info[#info] ] end,
        set = function(info, value) Addon.db.profile.general[ info[#info] ] = value end,
    }

    options.args.description = {
        order = new_order(1),
        type = 'description',
        name = L['General options are options that effect the whole addon. '..
            'Some Modules will have simalar options, but those are unique to '..
            'just that module.'],
    }
    options.args.fonts = {
        order = new_order(),
        type = 'group',
        inline = true,
        name = L["Fonts"],
        args = {
            fontSize = {
                order = new_order(),
                name = L["Font Size"],
                desc = L["Set the font size for everything in the UI."],
                type = 'range',
                min = 4, max = 200, step = 1,
            },
            font = {
                order = new_order(),
                name = L["Default"],
                desc = L["This is the description."],
                type = 'select', dialogControl = 'LSM30_Font',
                values = AceGUIWidgetLSMlists.font,
            },
        },
    }
    options.args.texture = {
        order = new_order(),
        type = 'group',
        inline = true,
        name = L["Textures"],
        args = {
            texture = {
                order = new_order(),
                name = L["Texture"],
                desc = L["The texture that will be used mainly for statusbars."],
                type = "select", dialogControl = 'LSM30_Statusbar',
                values = AceGUIWidgetLSMlists.statusbar,
                set = function(info, value)
                    Addon.db.profile.general[ info[#info] ] = value;
                    Addon:UpdateStatusBars()
                end
            },
        },
    }
    options.args.colors = {
        order = new_order(),
        type = 'group',
        inline = true,
        name = L["Colors"],
        get = function(info) return unpack(Addon.db.profile.general[info[#info]]) end,
        set = function(info, ...) Addon.db.profile.general[info[#info]] = {...} end,
        args = {
            textureColor = {
                order = new_order(),
                name = L["Texture color"],
                desc = L["The color used for statusbars."],
                type = 'color', hasAlpha = false,
            },
            borderColor = {
                order = new_order(),
                name = L["Border color"],
                desc = L["Main border color for the UI."],
                type = 'color', hasAlpha = false,
            },
        },
    }

    return options
end

--------------------------------------------------------------------------------

function Addon:OpenOptions(...)
    local options = {
        name = L[ADDON_NAME],
        handler = Addon,
        type = 'group',
        args = {},
        childGroups = 'tab',
    }

    options.args.generalOptions = get_general_options()
    options.args.generalOptions.order = new_order(1)

    -- Modules
    -- IDEA: use `orderedModules` to order by when they were loaded.
    -- local modules = self.orderedModules
    -- for i = 1, #modules do
    --     local module = modules[i]
    for name, module in self:IterateModules() do
        if type(module.get_module_options) == 'function' then
            options.args[name] = module.get_module_options()
            options.args[name].order = new_order()
            module.get_module_options = nil
        end
    end

    -- Profiles
    options.args.profile = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    options.args.profile.order = new_order()
    -- LibStub('LibDualSpec-1.0'):EnhanceOptions(options.args.profile, self.db)

    -- Register
    AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    AceConfigDialog:SetDefaultSize(ADDON_NAME, 1024, 666)

    -- Redefine
    function Addon:OpenOptions(...)
        AceConfigDialog:Open(ADDON_NAME)

        if select('#', ...) > 0 then
            AceConfigDialog:SelectGroup(ADDON_NAME, ...)
        end
    end

    return Addon:OpenOptions(...)
end
