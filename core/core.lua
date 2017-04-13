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
-- Addon.Media = LibStub('LibSharedMedia') -- TODO
-- Addon.Media:Register('statusbar', 'Armory', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\Statusbar.tga")
-- Addon.Media:Register('font', 'Dorpis', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\DORISPP.TTF")
Addon.media = {}
Addon.media.statusbar = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\Statusbar.tga"
Addon.media.font = "Interface\\AddOns\\"..ADDON_NAME.."\\media\\DORISPP.TTF"

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {

    },
    global = {

    }
}

--------------------------------------------------------------------- Options --
Addon.options = {
    type = 'group',
    args = {
        general = {
            type = 'group',
            name = L['General Settings'],
            order = 1,
            args = {
                -- addon-wide settings here
            },
        },
    },
}

---------------------------------------------------------------- Core Methods --
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(ADDON_NAME.."DB", defaultDB, true)
    LibStub('AceConfigRegistry-3.0'):RegisterOptionsTable(ADDON_NAME, self.options)
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
