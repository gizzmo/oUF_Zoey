-- Get the addon namespace
local addonName, ns = ...

-- Set global name of addon
_G[addonName] = ns

--------------------------------------------------------------------------------
--  Default configuration
--------------------------------------------------------------------------------
local configDefault = {
    statusbar = 'Armory',
    font = 'DorisPP',

    ptgap = 180,
    frames_offset = 300,

    border = {
        texture = [[Interface\AddOns\oUF_Zoey\media\Border.tga]],
        size = 12
    },

    highlight = {
        texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
        color = {1, 1, 1}, -- White
        alpha = 0.3
    },

}

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

-- Health bar color
oUF.colors.health = {89/255, 89/255, 89/255} -- dark grey

-- Combo points colors
oUF.colors.comboPoints = {
    normal = {232/255, 214/255, 12/255}, -- yellow
    last   = {240/255, 60/255, 60/255}   -- red
}

-- Experience bar colors
oUF.colors.experience = {
    main   = {176/255, 72/255, 176/255}, -- purple
    rested = {80/255, 80/255, 222/255}   -- blue
}

-- Cast bar colors
oUF.colors.cast =  {
    normal   = {89/255, 89/255, 89/255},      -- dark gray
    success  = {20/255, 208/255, 0/255},      -- green
    failed   = {255/255, 12/255, 0/255},      -- dark red
    safezone = {255/255, 25/255, 0/255, 0.5}, -- transparent red
}

-- Border colors
oUF.colors.border = {
    normal    = {113/255, 113/255, 113/255}, -- Dark Grey
    rare      = {1, 1, 1},                   -- White
    elite     = {204/255, 177/255, 41/255},  -- Yellow
    rareelite = {41/255,  128/255, 204/255}, -- Blue
    boss      = {136/255, 41/255, 204/255}   -- Purple

}

-- setup some global namespace variables
ns.statusbars = {}

--------------------------------------------------------------------------------
--  Print/Printf support
--------------------------------------------------------------------------------
local printHeader = "|cFF33FF99%s|r: "

function ns:Printf(msg, ...)
    msg = printHeader .. msg
    local success, txt = pcall(string.format, msg, addonName, ...)
    if success then
        print(txt)
    else
        error(string.gsub(txt, "'%?'", string.format("'%s'", "Printf")), 3)
    end
end


--------------------------------------------------------------------------------
-- Event registration and dispatch
--------------------------------------------------------------------------------
ns.eventFrame = CreateFrame('Frame', addonName .. 'EventFrame', UIParent)
local eventMap = {}

function ns:RegisterEvent(event, handler)
    assert(eventMap[event] == nil, 'Attempt to re-register event: ' .. tostring(event))
    eventMap[event] = handler and handler or event
    ns.eventFrame:RegisterEvent(event)
end

function ns:UnregisterEvent(event)
    assert(type(event) == 'string', 'Invalid argument to \'UnregisterEvent\'')
    eventMap[event] = nil
    ns.eventFrame:UnregisterEvent(event)
end

ns.eventFrame:SetScript("OnEvent", function(frame, event, ...)
    local handler = eventMap[event]
    local handler_t = type(handler)
    if handler_t == "function" then
        handler(event, ...)
    elseif handler_t == "string" and ns[handler] then
        ns[handler](ns, event, ...)
    end
end)


--------------------------------------------------------------------------------
-- Support for deferred execution (when in-combat)
--------------------------------------------------------------------------------
local deferframe = CreateFrame("Frame")
deferframe.queue = {}

local function runDeferred(thing)
    local thing_t = type(thing)
    if thing_t == "string" and ns[thing] then
        ns[thing](ns)
    elseif thing_t == "function" then
        thing(ns)
    end
end

-- This method will defer the execution of a method or function until the
-- player has exited combat. If they are already out of combat, it will
-- execute the function immediately.
function ns:Defer(...)
    for i = 1, select("#", ...) do
        local thing = select(i, ...)
        local thing_t = type(thing)
        if thing_t == "string" or thing_t == "function" then
            if InCombatLockdown() then
                deferframe.queue[#deferframe.queue + 1] = select(i, ...)
            else
                runDeferred(thing)
            end
        else
            error("Invalid object passed to 'Defer'")
        end
    end
end

deferframe:RegisterEvent("PLAYER_REGEN_ENABLED")
deferframe:SetScript("OnEvent", function(self, event, ...)
    for idx, thing in ipairs(deferframe.queue) do
        runDeferred(thing)
    end
    table.wipe(deferframe.queue)
end)


--------------------------------------------------------------------------------
-- Time to initialize the addon by loading the config
--------------------------------------------------------------------------------
ns:RegisterEvent('ADDON_LOADED', function(event, ...)
    if ... ~= addonName then return end
    ns:UnregisterEvent(event)

    -- Merge saved settigns with defaults
    local function initDB(db, defaults)
        if type(db) ~= 'table' then db = {} end
        if type(defaults) ~= 'table' then return db end
        for k, v in pairs(defaults) do
            if type(v) == 'table' then
                db[k] = initDB(db[k], v)
            elseif type(v) ~= type(db[k]) then
                db[k] = v
            end
        end
        return db
    end

    oUF_ZoeyConfig = initDB(oUF_ZoeyConfig, configDefault)
    ns.config = oUF_ZoeyConfig

    -- Register our spawn function with oUF
    oUF:Factory(ns.SpawnFrames)
end)

-- Fires immediately before the player is logged out of the game
ns:RegisterEvent('PLAYER_LOGOUT', function(event)
    -- Remove defaults from config.
    local function cleanDB(db, defaults)
        if type(db) ~= 'table' then return {} end
        if type(defaults) ~= 'table' then return db end
        for k, v in pairs(db) do
            if type(v) == 'table' then
                if not next(cleanDB(v, defaults[k])) then
                    -- Remove empty subtables
                    db[k] = nil
                end
            elseif v == defaults[k] then
                -- Remove default values
                db[k] = nil
            end
        end
        return db
    end

    oUF_ZoeyConfig = cleanDB(oUF_ZoeyConfig, configDefault)
end)

--------------------------------------------------------------------------------
-- Setup extra stuff for the UI
--------------------------------------------------------------------------------
ns:RegisterEvent('PLAYER_LOGIN', function(event, ...)
    -- Hide the Blizzard Buffs
    BuffFrame:Hide()
    BuffFrame:UnregisterAllEvents()
    TemporaryEnchantFrame:Hide()
    ConsolidatedBuffs:Hide()

    -- Hide the Compact Raid Frame Manager and Container
    CompactRaidFrameManager:UnregisterAllEvents()
    CompactRaidFrameManager.Show = CompactRaidFrameManager.Hide
    CompactRaidFrameManager:Hide()

    CompactRaidFrameContainer:UnregisterAllEvents()
    CompactRaidFrameContainer.Show = CompactRaidFrameContainer.Hide
    CompactRaidFrameContainer:Hide()

    -- Skin the Mirror Timers
    local Media = LibStub("LibSharedMedia-3.0")
    local font = Media:Fetch("font", ns.config.font)
    local texture = Media:Fetch("statusbar", ns.config.statusbar)

    for i = 1, 3 do
        local barname = 'MirrorTimer'..i
        local bar = _G[barname]

        -- Hide old border
        _G[barname..'Border']:Hide()

        -- Place where we want
        bar:SetParent(UIParent)
        bar:SetSize(285, 28)

        if i > 1 then
            local p1, p2, p3, p4, p5 = bar:GetPoint()
            bar:SetPoint(p1, p2, p3, p4, p5 - 15)
        end

        -- Add our style
        bar.bar = _G[ barname..'StatusBar' ]
        bar.bar:SetPoint('TOPLEFT', bar, 1, -1)
        bar.bar:SetPoint('BOTTOMRIGHT', bar, -1, 1)
        bar.bar:SetStatusBarTexture(texture)
        bar.bar:SetAlpha(0.8)

        bar.bg = bar:GetRegions()
        bar.bg:ClearAllPoints()
        bar.bg:SetAllPoints(bar)
        bar.bg:SetTexture(texture)
        bar.bg:SetVertexColor(0.2, 0.2, 0.2, 1)

        bar.text = _G[barname..'Text']
        bar.text:ClearAllPoints()
        bar.text:SetPoint('LEFT', bar, 6, -1)
        bar.text:SetFont(font, 16)

        ns.CreateBorder(bar)

        tinsert(ns.statusbars, bar.bar)
        tinsert(ns.statusbars, bar.bg)
    end

    -- Disable Blizzard options that are rendered useless by having this unit frame addon
    for _, button in pairs({
        'CombatPanelTargetOfTarget',
        'CombatPanelEnemyCastBarsOnPortrait',
        'DisplayPanelShowAggroPercentage',
        'FrameCategoriesButton9',  -- Status Text
        'FrameCategoriesButton10', -- Unit Frames
        'FrameCategoriesButton11', -- Raid Profiles
        'FrameCategoriesButton12', -- Buffs and Debuffs
    }) do
        _G['InterfaceOptions'..button]:SetAlpha(0.35)
        _G['InterfaceOptions'..button]:Disable()
        _G['InterfaceOptions'..button]:EnableMouse(false)
    end

    -- Remove Items from the Rightclick Menu
    for _, menu in pairs( UnitPopupMenus ) do
        for i = #menu, 1, -1 do
            local name = menu[ i ]
            if name:match( '^LOCK_%u+_FRAME$' )
            or name:match( '^UNLOCK_%u+_FRAME$' )
            or name:match( '^MOVE_%u+_FRAME$' )
            or name:match( '^RESET_%u+_FRAME_POSITION' )
            or name:match( '^SET_FOCUS' )
            or name:match( '^DISMISS' )
            then
                table.remove( menu, i )
            end
        end
    end

end)


--------------------------------------------------------------------------------
-- Register Some stuf with Shared Media
--------------------------------------------------------------------------------
local Media = LibStub('LibSharedMedia-3.0', true)
Media:Register('statusbar', 'Armory', [[Interface\AddOns\oUF_Zoey\media\Statusbar.tga]])
Media:Register('font', 'DorisPP', [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]])


--------------------------------------------------------------------------------
-- Fin
