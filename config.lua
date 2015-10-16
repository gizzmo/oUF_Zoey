--// Get the addon namespace
local addon, ns = ...

--//----------------------------
--// CONFIG
--//----------------------------
local config = {
    statusbar = [[Interface\AddOns\oUF_Zoey\media\Armory]],
    font = [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]],

    border = {
        texture = [[Interface\AddOns\oUF_Zoey\media\ThinSquare]],
        size = 12
    },

    highlight = {
        texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
        color = {1, 1, 1}, -- White
        alpha = 0.3
    },

    units = {}
}

--// Handover
ns.config = config

--//-------------------------
--// COLORS
--//-------------------------

--// Health bar color
oUF.colors.health = {89/255, 89/255, 89/255} -- dark grey

--// Combo points colors
oUF.colors.comboPoints = {
    normal = {232/255, 214/255, 12/255}, -- yellow
    last   = {240/255, 60/255, 60/255}   -- red
}

--// Experience bar colors
oUF.colors.experience = {
    main   = {176/255, 72/255, 176/255}, -- purple
    rested = {80/255, 80/255, 222/255}   -- blue
}

--// Cast bar colors
oUF.colors.cast =  {
    normal   = {89/255, 89/255, 89/255},      -- dark gray
    success  = {20/255, 208/255, 0/255},      -- green
    failed   = {255/255, 12/255, 0/255},      -- dark red
    safezone = {255/255, 25/255, 0/255, 0.5}, -- transparent red
}

--// Border colors
oUF.colors.border = {
    normal    = {113/255, 113/255, 113/255}, -- Dark Grey
    rare      = {1, 1, 1},                   -- White
    elite     = {204/255, 177/255, 41/255},  -- Yellow
    rareelite = {255/255, 238/255, 153/255}, -- Yellow-ish/White-ish
    boss      = {136/255, 41/255, 204/255}   -- Purple

}

--// Register Some stuf with Shared Media
if LibStub then
    local LSM = LibStub("LibSharedMedia-3.0", true)

    if LSM then
        LSM:Register("border", "thinsquare", config.border.texture)
        LSM:Register("statusbar", "Armory", config.statusbar)
        LSM:Register("font", "DorisPP", config.font)
    end
end
