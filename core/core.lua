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
        general = {
            fontSize = 16,
            font = 'Dorpis',
            texture = 'Armory',
            borderColor = {113/255, 113/255, 113/255},
            textureColor = {89/255, 89/255, 89/255},
        },
    },
    global = {

    }
}

--------------------------------------------------------------------- Options --
Addon.options = {
    type = 'group',
    args = {},
}

Addon.options.args.general = {
    order = 10,
    type = 'group',
    name = L['General'],
    get = function(info) return Addon.db.profile.general[ info[#info] ] end,
    set = function(info, value) Addon.db.profile.general[ info[#info] ] = value end,
    args = {
        general = {
            order = 10,
            type = 'group',
            inline = true,
            name = L["General"],
            args = {
                --
            },
        },

        fonts = {
            order = 20,
            type = 'group',
            inline = true,
            name = L["Fonts"],
            args = {
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
            },
        },

        texture = {
            order = 30,
            type = 'group',
            inline = true,
            name = L["Textures"],
            args = {
                texture = {
                    order = 21,
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
        },

        colors = {
            order = 40,
            type = 'group',
            inline = true,
            name = L["Colors"],
            get = function(info) return unpack(Addon.db.profile.general[info[#info]]) end,
            set = function(info, ...) Addon.db.profile.general[info[#info]] = {...} end,
            args = {
                textureColor = {
                    order = 32,
                    name = L["Texture color"],
                    desc = L["The color used for statusbars."],
                    type = 'color', hasAlpha = false,
                },
                borderColor = {
                    order = 31,
                    name = L["Border color"],
                    desc = L["Main border color for the UI."],
                    type = 'color', hasAlpha = false,
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

--------------------------------------------------------------------------------
Addon.statusBars = {}
function Addon:RegisterStatusBar(statusBar)
    tinsert(self.statusBars, statusBar)
end

function Addon:UpdateStatusBars()
    for _, statusBar in pairs(self.statusBars) do
        if not statusBar then break end
        local texture = self.Media:Fetch('statusbar', self.db.profile.general.texture)
        if statusBar:GetObjectType() == "StatusBar" then
            statusBar:SetStatusBarTexture(texture)
        elseif statusBar:GetObjectType() == "Texture" then
            statusBar:SetTexture(texture)
        end
    end
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
