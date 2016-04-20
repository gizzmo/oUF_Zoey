--[[----------------------------------------------------------------------------
AddonStub.lua

This is a amalgamation of several addons
    PhanxAddonStub  https://github.com/Phanx/PhanxAddonStub
    Inomena         https://github.com/p3lim-wow/Inomena
    TomTom          http://wowinterface.com/downloads/info7032-TomTom.html
    Ace3            http://www.wowace.com/addons/ace3/

------------------------------------------------------------------------------]]

local addonName, addon = ...
local frame = CreateFrame("Frame") -- private frame for AddonStub only events

-- Set global name of addon
_G[addonName] = addon

-- helpfull shortcut
_G['SLASH_rl1'] = '/rl'
SlashCmdList['rl'] = ReloadUI


--------------------------------------------------------------------------------
-- Basic methods

function addon:GetName()
    return (addon.name or GetAddOnMetadata(addonName, "Title") or addonName), addonName
end


--------------------------------------------------------------------------------
-- Localization

addon.L = setmetatable({}, {
    -- When accessing a key that doesn't exist, set the value as the key
    -- This allows us not need to create a default locale, because just trying
    -- to access the string, sets it up the default locale
    __index = function(table, key)
        rawset(table, key, key)
        return key
    end,

    -- When setting a key, if the value is `true` use the key
    __newindex = function(table, key, value)
        rawset(table, key, value == true and key or value)
    end,
})

local gameLocale = GetLocale()
function addon:RegisterLocale(locale, table)
    if locale ~= 'enUS' and locale ~= gameLocale then
        return -- nop, we don't need these translations
    end

    for key, value in pairs(table) do
        if type(value) == "function" then
            self.L[key] = value()
        else
            self.L[key] = key
        end
    end
end


--------------------------------------------------------------------------------
-- Printing

addon.PRINT_PREFIX = "|cff00ddba" .. addon:GetName() .. ":|r"

-- if the string passed has any format style characters we assume we want to
-- use the format method
function addon:Print(str, ...)
    if select("#", ...) > 0 then
        if strmatch(str, "%%[dfqsx%d]") or strmatch(str, "%%%.%d") then
            str = format(str, ...)
        else
            str = strjoin(" ", str, tostringall(...))
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(self.PRINT_PREFIX .. " " ..str)
end


--------------------------------------------------------------------------------
-- Deferred execution (when in-combat)

local defer_queue = {}

local function runDeferred(thing)
    local thing_t = type(thing)
    if thing_t == 'string' and addon[thing] then
        addon[thing](ns)
    elseif thing_t == 'function' then
        thing(ns)
    end
end

-- This method will defer the execution of a method or function until the player
-- has exited combat. If they are already out of combat, it will execute the
-- function immediately.
function addon:Defer(...)
    for i = 1, select('#', ...) do
        local thing = select(i, ...)
        local thing_t = type(thing)
        if thing_t == 'string' or thing_t == 'function' then
            if InCombatLockdown() then
                defer_queue[#defer_queue + 1] = thing
            else
                runDeferred(thing)
            end
        else
            error('Invalid object: "Defer(function[, function])"')
        end
    end
end

frame:RegisterEvent('PLAYER_REGEN_ENABLED')

function frame:PLAYER_REGEN_ENABLED(event, ...)
    for idx, thing in ipairs(defer_queue) do
        runDeferred(thing)
    end
    table.wipe(defer_queue)
end


--------------------------------------------------------------------------------
-- Slash command registering
--[[
    addon:RegisterSlash('stub', function(input, editbox) end)
    OR
    addon:RegisterSlash('stub', 'slashCmdHandler')

--]]
function addon:RegisterSlash(...)
    local name = addonName..'Slash' .. math.floor(GetTime())

    local numArgs = select('#', ...)
    local func = select(numArgs, ...)

    for index = 1, numArgs - 1 do
        local command = select(index, ...)
        _G['SLASH_' .. name .. index] = '/'..command:lower()
    end

    if type(func) == 'string' then
        SlashCmdList[name] = function(input, editBox)
            self[func](self, input, editBox)
        end
    else
        SlashCmdList[name] = func
    end
end


--------------------------------------------------------------------------------
-- Event handling

local handlers = {}
local unitEvents = {}

-- Call both funcs on the frame and handler funcs
frame:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, event, ...)
    end
    return addon:TriggerEvent(event, ...)
end)

-- Find all the funcs for this event and call them
-- If the returned value is `UNREGISTER` unregister that func
function addon:TriggerEvent(event, ...)
    if not handlers[event] then return end
    for func, handler in pairs(handlers[event]) do
        if handler == true then
            if func(...) == "UNREGISTER" then -- note: change to boolean?
                self:UnregisterEvent(event, func)
            end
        elseif func(handler, ...) == "UNREGISTER" then
            self:UnregisterEvent(event, func, handler)
        end
    end
end

--[[ Possible combinations of parameters followed by whats returned

    getEventHandler(self, 'ADDON_LOADED')
    self['ADDON_LOADED']
    self

    getEventHandler(self, 'ADDON_LOADED', 'onLoad')
    self['onLoad']
    self

    getEventHandler(self, 'ADDON_LOADED', 'onLoad', ns.table)
    ns.table['onLoad']
    ns.table

    getEventHandler(self, 'ADDON_LOADED', anonymouseFunc)
    anonymouseFunc
    nil

    getEventHandler(self, 'ADDON_LOADED', ns.table)
    ns.table['ADDON_LOADED']
    ns.table

if the possible function returned doesnt exist, return nil
--]]
local function getEventHandler(self, event, func, handler)
    if type(func) == "string" then
        if type(handler) == "table" then
            func = handler[func]
        else
            func = self[func]
            handler = self
        end
    elseif type(func) == 'table' then
        handler = func
        func = handler[event]
    elseif type(func) ~= "function" then
        func = self[event]
        handler = self
    else
        handler = nil
    end
    return type(func) == "function" and func or nil, handler
end

function addon:RegisterEvent(event, func, handler)
    assert(not unitEvents[event], event .. " already registered as a unit event!")
    local func, handler = getEventHandler(self, event, func, handler)
    if func then
        handlers[event] = handlers[event] or {}
        handlers[event][func] = handler or true
        frame:RegisterEvent(event)
        return true
    end
end

function addon:RegisterUnitEvent(event, unit1, unit2, func, handler)
    assert(unitEvents[event] or not handlers[event], event .. " already registered as a non-unit event!")
    local func, handler = getEventHandler(self, event, func, handler)
    if func then
        unitEvents[event] = true
        handlers[event] = handlers[event] or {}
        handlers[event][func] = handler or true
        frame:RegisterUnitEvent(event, unit1, unit2)
        return true
    end
end

function addon:UnregisterEvent(event, func, handler)
    if handlers[event] then
        local func = getEventHandler(self, event, func, handler)
        if func then
            handlers[event][func] = nil
        end
        if not next(handlers[event]) then
            unitEvents[event] = nil -- TODO: check that this works as intended
            handlers[event] = nil
            frame:UnregisterEvent(event)
        end
    end
end

function addon:UnregisterAllEvents()
    wipe(handlers)
    frame:UnregisterAllEvents()
end

function addon:IsEventRegistered(event)
    return frame:IsEventRegistered(event)
end


--------------------------------------------------------------------------------
-- Database initialization

local db_defaults = {}
local function initDB(db, defaults)
    if type(db) ~= "table" then db = {} end
    if type(defaults) ~= "table" then return db end
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            db[k] = initDB(db[k], v)
        elseif type(v) ~= type(db[k]) then
            db[k] = v
        end
    end
    return db
end

--[[ Example

    local db_defaults = {
        do_thing = true
    }

    self.db = addon:InitializeDB(MyAddonDatabase, db_defaults)

--]]
function addon:InitializeDB(db, defaults)
    _G[db] = initDB(_G[db], defaults)

    db_defaults[db] = defaults

    return _G[db]
end


--------------------------------------------------------------------------------
-- Ignition sequence

frame:RegisterEvent("ADDON_LOADED")

function frame:ADDON_LOADED(event, name)
    if name ~= addonName then return end

    self:UnregisterEvent("ADDON_LOADED")
    self.ADDON_LOADED = nil

    if addon.OnLoad then
        addon:OnLoad()
        addon.OnLoad = nil
    end

    if IsLoggedIn() then
        self:PLAYER_LOGIN()
    else
        self:RegisterEvent("PLAYER_LOGIN")
    end
end

function frame:PLAYER_LOGIN(event)
    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil

    if addon.OnLogin then
        addon:OnLogin()
        addon.OnLogin = nil
    end

    self:RegisterEvent("PLAYER_LOGOUT")
end

function frame:PLAYER_LOGOUT(event)
    if addon.OnLogout then
        addon:OnLogout()
        -- no point in cleaning up here since we're logging out
    end

    -- if a database was initialized, clean it before we logout
    if not next(db_defaults) then
        local function cleanDB(db, defaults)
            if type(db) ~= "table" then return {} end
            if type(defaults) ~= "table" then return db end
            for k, v in pairs(db) do
                if type(v) == "table" then
                    db[k] = cleanDB(v, defaults[k])
                elseif v == defaults[k] then
                    db[k] = nil
                end
            end
            if not next(db) then
                return nil
            end
            return db
        end

        for db, defaults in pairs(frame.db_defaults) do
            _G[db] = cleanDB(_G[db], defaults)
        end
    end
end
