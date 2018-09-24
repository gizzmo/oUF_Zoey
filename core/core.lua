local ADDON_NAME, Addon = ...

------------------------------------------------------------------ Core Addon --
ZoeyUI = LibStub('AceAddon-3.0'):NewAddon(Addon, ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0')
Addon.version = GetAddOnMetadata(ADDON_NAME, 'Version')

------------------------------------------------------------------------ Libs --
local Dialog = LibStub("AceConfigDialog-3.0")

---------------------------------------------------------------------- Locale --
-- If needed this can be extracted into its own file.
LibStub('AceLocale-3.0'):NewLocale(ADDON_NAME, 'enUS', true, true)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
Addon.L = L

----------------------------------------------------------------------- Media --
Addon.Media = LibStub('LibSharedMedia-3.0')
Addon.Media:Register('statusbar', 'Armory', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\Statusbar.tga")
Addon.Media:Register('font', 'Dorispp', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\DORISPP.TTF")
Addon.Media:Register('border', 'ZoeyUI Border', "Interface\\AddOns\\"..ADDON_NAME.."\\media\\border.tga")

-------------------------------------------------------------------- Database --
local defaultDB = {
    profile = {
        general = {
            fontSize = 16,
            font = 'Dorispp',
            texture = 'Armory',
            borderColor = {113/255, 113/255, 113/255},
            textureColor = {89/255, 89/255, 89/255},
        },
    },
    global = {

    }
}

---------------------------------------------------------------- Core Methods --
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(ADDON_NAME.."DB", defaultDB, true)
    self.db.RegisterCallback(self, 'OnProfileChanged', 'OnProfileRefresh')
    self.db.RegisterCallback(self, 'OnProfileCopied', 'OnProfileRefresh')
    self.db.RegisterCallback(self, 'OnProfileReset', 'OnProfileRefresh')
end

function Addon:OnEnable()
    -- enter/leave combat for :RunOnLeaveCombat
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function Addon:OnDisable()
end

function Addon:OnProfileRefresh(args)
    self:FireModuleMethod('OnProfileRefresh')
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
local ModulePrototype = {}
Addon:SetDefaultModulePrototype(ModulePrototype)
Addon:SetDefaultModuleLibraries('AceConsole-3.0')

Addon.ModuleSlashCommands = {}
function ModulePrototype:RegisterSlashCommand(command, func)
    if type(command) ~= 'string' then
       error(("Usage: RegisterSlashCommand(command, func): 'command' - string expected got '%s'."):format(type(command)), 2)
    end
    if type(func) ~= 'string' and type(func) ~= 'function' and type(func) ~= 'boolean' then
        error(("Usage: RegisterSlashCommand(command, func): 'func' - string, function or boolean expected got '%s'"):format(type(func)), 2)
    end
    if type(func) == 'string' and type(self[func]) ~= 'function' then
        error(("Usage: RegisterSlashCommand(command, func): 'func' - method '%s' not found."):format(func), 2)
    end

    if type(func) == 'boolean' and func then
        Addon.ModuleSlashCommands[command] = function(input)
            Addon:OpenOptions(self:GetName())
        end
    else
        Addon.ModuleSlashCommands[command] = Addon.ConvertMethodToFunction(self, func)
    end
end

-- Call a given method on all modules if those modules have the method
function Addon:FireModuleMethod(method, ...)
    if type(method) ~= 'string' then
        error(("Usage: FireModuleMethod(method[, arg, arg, ...]): 'method' - string expcted got '%s'."):format(type(method)), 2)
    end

    for name, module in self:IterateModules() do
        if type(module[method]) == 'function' then
           module[method](module, ...)
        end
    end
end

--------------------------------------------------------------- Slash Command --
Addon:RegisterChatCommand('rl', ReloadUI) -- Easy reload slashcmd
Addon:RegisterChatCommand('zoey', function(input)
    local arg, nextpos = Addon:GetArgs(input, 1)

    if not arg then
        Addon:OpenOptions()

    -- TODO: find better pattern matching
    elseif strmatch(strlower(arg), '^ve?r?s?i?o?n?$') then
        Addon:Print(format(L['You are using version %s'], Addon.version))
    else
        for command, func in pairs(Addon.ModuleSlashCommands) do
            if command == arg then
                return func(input:sub(nextpos))
            end
        end
    end
end)

------------------------------------------------------------------- Utilities --
-- A frame to attach to to make sure its hidden.
Addon.HiddenFrame = CreateFrame('Frame')
Addon.HiddenFrame.Show = Addon.HiddenFrame.Hide -- Remove the ability to show it
Addon.HiddenFrame:Hide()

-- Can be used to overwrite a function without making it nil, or where you need
-- to return a function that does nothing.
Addon.noop = function() --[[No Operation]] end

-- Leave a function as-is or if a string is passed in, convert it to a
-- namespace-method function call.
function Addon.ConvertMethodToFunction(namespace, func_name)
    if type(func_name) == "function" then
        return func_name
    end

    if type(namespace[func_name]) ~= 'function' then
        error(("Usage: ConvertMethodToFunction(namespace, func_name): 'func_name' - method '%s' not found on namespace."):format(func_name), 2)
    end

    return function(...)
        return namespace[func_name](namespace, ...)
    end
end

-- Wrap a function so that it cant be run while combat. If you want the function
-- to run after combat use, `AfterCombatWrapper`
function Addon:NoCombatWrapper(func, withError)
    if type(func) ~= 'function' then
        error(("Usage: NoCombatWrapper(func): 'func' - function expected got '%s'"):format(type(func)), 2)
    end

    return function(...)
        if not InCombatLockdown() then
            func(...)
        end
    end
end

-- Wrap the given function so that any call to it will be piped through
-- Addon:RunAfterCombat.
function Addon:AfterCombatWrapper(func)
    if type(func) ~= 'function' then
        error(("Usage: AfterCombatWrapper(func): 'func' - function expcted got '%s'."):format(type(func)), 2)
    end

    return function(...)
        Addon:RunAfterCombat(func, ...)
    end
end


--------------------------------------------------------------------------------
local action_queue = {}

-- Call a function if out of combat or schedule to run once combat ends.
function Addon:RunAfterCombat(func, ...)
    if type(func) ~= 'function' then
        error(("Usage: RunAfterCombat(func[, ...]): 'func' - function expcted got '%s'."):format(type(func)), 2)
    end

    -- Not in combat, call right away
    if not InCombatLockdown() then
        func(...)
        return
    end

    -- Buildup the action table
    local action = {...}
    action.func = func
    action.argsCount = select('#', ...)

    action_queue[#action_queue+1] = action
end

-- Exiting combat, run and clear the queue
function Addon:PLAYER_REGEN_ENABLED()
    for i, action in ipairs(action_queue) do
        action.func(unpack(action, 1, action.argsCount))
        action_queue[i] = nil
    end
end

------------------------------------------------------------------------ Fin! --
