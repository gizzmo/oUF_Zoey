-- Get the addon namespace
local addon, ns = ...

--//----------------------------
--// DEFAULT CONFIGURATION
--//----------------------------
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

--//-------------------------
--// COLORS
--//-------------------------

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

--//-----------------------------------------------------------------
--// Register Some stuf with Shared Media
--//-----------------------------------------------------------------
local Media = LibStub('LibSharedMedia-3.0', true)
Media:Register('statusbar', 'Armory', [[Interface\AddOns\oUF_Zoey\media\Statusbar.tga]])
Media:Register('font', 'DorisPP', [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]])

--//-----------------------------------------------------------------
--// Load config variables
--//-----------------------------------------------------------------
local Loader = CreateFrame('Frame')
Loader:SetScript('OnEvent', function(self, event, ...)
    return self[event] and self[event](self, event, ...)
end)

-- Fires when an addon and its saved variables are loaded
Loader:RegisterEvent('ADDON_LOADED')
function Loader:ADDON_LOADED(event, addon)
    if addon ~= 'oUF_Zoey' then return end

    -- Event has fired. Run only once
    self:UnregisterEvent(event)
    self.ADDON_LOADED = nil

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
end

-- Fires immediately before the player is logged out of the game
Loader:RegisterEvent('PLAYER_LOGOUT')
function Loader:PLAYER_LOGOUT(event)

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
end
