local ADDON_NAME, Addon = ...

------------------------------------------------------------------ Core Addon --
ZoeyUI = LibStub('AceAddon-3.0'):NewAddon(Addon, ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0')
Addon.version = GetAddOnMetadata(ADDON_NAME, 'Version')

---------------------------------------------------------------------- Locale --
-- If needed this can be extracted into its own file.
LibStub('AceLocale-3.0'):NewLocale(ADDON_NAME, 'enUS', true, true)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
Addon.L = L

----------------------------------------------------------------------- Media --
Addon.Media = LibStub('LibSharedMedia-3.0')
Addon.Media:Register('statusbar', 'Armory', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\Statusbar.tga")
Addon.Media:Register('font', 'Dorpis', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\DORISPP.TTF")
Addon.Media:Register('border', 'ZoeyUI Border', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\border.tga")

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {
        statusbar = 'Armory',
        font = 'Dorpis',
    },
    global = {

    }
}

--------------------------------------------------------------------- Options --
Addon.options = {
    type = 'group',
    args = {
        ZoeyUI_Header = {
            order = 1,
            type = 'header',
            name = L["Zoey UI!!!"],
            width = 'full',
        },

        ReloadUI = {
            order = 2,
            type = 'execute',
            name = L["ReloadUI"],
            desc = L["Reloads the UI."],
            func = function() ReloadUI() end,
        },

        general = {
            order = 10,
            type = 'group',
            name = L['General'],
            get = function(info) return Addon.db.profile[ info[#info] ] end,
            set = function(info, value) Addon.db.profile[ info[#info] ] = value end,
            args = {
                fontHeader = {
                    order = 10,
                    type = "header",
                    name = L["Fonts"],
                },
                fontSize = {
                    order = 11,
                    name = L["Font Size"],
                    desc = L["Set the font size for everything in the UI."],
                    type = 'range',
                    min = 4, max = 200, step = 1,
                },
                font = {
                    order = 12,
                    name = L["Default"],
                    desc = L["This is the description."],
                    type = 'select', dialogControl = 'LSM30_Font',
                    values = AceGUIWidgetLSMlists.font,
                },
                textureHeader = {
                    order = 20,
                    type = 'header',
                    name = L["Textures"],
                },
                statusbar = {
                    order = 21,
                    name = L["Statusbar"],
                    desc = L["The texture that will be used mainly for statusbars."],
                    type = "select", dialogControl = 'LSM30_Statusbar',
                    values = AceGUIWidgetLSMlists.statusbar,
                },
            },
        },
    },
}




---------------------------------------------------------------- Core Methods --
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(ADDON_NAME.."DB", defaultDB, true)
    LibStub('AceConfigRegistry-3.0'):RegisterOptionsTable(ADDON_NAME, self.options)

    self.options.args.profile = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)
    self.options.args.profile.order = -1 -- always at the end.
end

function Addon:OnEnable()
end

function Addon:OnDisable()
end

--------------------------------------------------------------------- Modules --
Addon.modulePrototype = {}
Addon:SetDefaultModulePrototype(Addon.modulePrototype)
Addon:SetDefaultModuleLibraries('AceConsole-3.0')

Addon.ModuleSlashCommands = {}
function Addon.modulePrototype:RegisterSlashCommand(command, func)
    if type(func) == 'string' then
        Addon.ModuleSlashCommands[command] = function(input)
            self[func](self, input)
        end
    else
        Addon.ModuleSlashCommands[command] = func
    end
end

--------------------------------------------------------------- Slash Command --
Addon:RegisterChatCommand('rl', ReloadUI) -- Easy reload slashcmd

local Dialog = LibStub('AceConfigDialog-3.0')
Addon:RegisterChatCommand('zoey', function(input)
    local arg = Addon:GetArgs(input, 1)

    if not arg then
        Dialog:Open(ADDON_NAME)
        -- TODO: find better pattern matching
    elseif strmatch(strlower(arg), '^ve?r?s?i?o?n?$') then
        Addon:Print(format(L['You are using version %s'], Addon.version))
    else
        for command, func in pairs(Addon.ModuleSlashCommands) do
            if command == arg then
                return func(input:sub(arg:len()+2))
            end
        end
    end
end)
