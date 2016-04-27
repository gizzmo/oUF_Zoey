-- Get the addon namespace
local addonName, ns = ...

-- Set global name
_G[addonName] = ns

--------------------------------------------------------------------------------
-- Default configuration
--------------------------------------------------------------------------------
local defaultDB = {

    statusbar = 'Armory',
    font = 'DorisPP',

    ptgap = 150,         -- gap between player and target
    frames_offset = 270, -- offset from bottom of UIParent

    PVP = false, -- enable PVP mode, currently only affects aura filtering
}

--------------------------------------------------------------------------------
-- Setup oUF Colors
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

--------------------------------------------------------------------------------
-- Ignition sequence
--------------------------------------------------------------------------------
function ns:OnLoad()
    self.db = ns:InitializeDB(addonName..'DB', defaultDB)

    -- Register our media with SharedMedia
    local Media = LibStub('LibSharedMedia-3.0')
    Media:Register('statusbar', 'Armory', [[Interface\AddOns\oUF_Zoey\media\Statusbar.tga]])
    Media:Register('font', 'DorisPP', [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]])

    -- Slash command handler
    _G['SLASH_'..addonName..'1'] = '/zoey'
    SlashCmdList[addonName] = function(input)
        -- Open the options window
        if input == '' or input == 'config' then
            InterfaceOptionsFrame_Show()
            InterfaceOptionsFrame_OpenToCategory('oUF Zoey')
        end
    end

    _G['SLASH_rl1'] = '/rl'
    SlashCmdList['rl'] = ReloadUI

    -- Shift to temporarily show all buffs
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    if not UnitAffectingCombat("player") then
        self:RegisterEvent("MODIFIER_STATE_CHANGED")
    end

    ns.UpdateAuraList()
end

function ns:OnLogin()
    ns:DisableBlizzard()
    ns:SkinMirrorTimer()
    ns:SpawnUnitFrames()
end

--------------------------------------------------------------------------------
function ns:DisableBlizzard()
    -- Hide the Blizzard Buffs
    BuffFrame:Hide()
    BuffFrame:UnregisterAllEvents()
    TemporaryEnchantFrame:Hide()
    ConsolidatedBuffs:Hide()

    -- The raid frames are actaully addons, disable them.
    DisableAddOn("Blizzard_CompactRaidFrames")
    DisableAddOn("Blizzard_CUFProfiles")

    -- Disable Blizzard options that are rendered useless by having this unit frame addon
    for _, button in pairs({
        'CombatPanelTargetOfTarget',
        'CombatPanelEnemyCastBarsOnPortrait',
        'DisplayPanelShowAggroPercentage',
        'FrameCategoriesButton9',  -- Status Text
        'FrameCategoriesButton10', -- Unit Frames
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
end

function ns:SkinMirrorTimer()
    local Media = LibStub('LibSharedMedia-3.0')
    local font = Media:Fetch('font', ns.db.font)
    local texture = Media:Fetch('statusbar', ns.db.statusbar)

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
        tinsert(ns.fontstrings, bar.text)
    end
end

--------------------------------------------------------------------------------
ns.fontstrings = {}
function ns.SetAllFonts()
    local font = LibStub('LibSharedMedia-3.0'):Fetch('font', ns.db.font)

    for i = 1, #ns.fontstrings do
        local fs = ns.fontstrings[i]
        local _, size = fs:GetFont()
        fs:SetFont(font, size or 16)
    end
end

ns.statusbars = {}
function ns.SetAllStatusBarTextures()
    local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.db.statusbar)

    for i = 1, #ns.statusbars do
        local sb = ns.statusbars[i]

        --// Is it a statusbar or a texture
        if sb.SetStatusBarTexture then
            local r, g, b, a = sb:GetStatusBarColor()
            sb:SetStatusBarTexture(texture)
            sb:SetStatusBarColor(r, g, b, a)

        else
            local r, g, b, a = sb:GetVertexColor()
            sb:SetTexture(texture)
            sb:SetVertexColor(r, g, b, a)
        end
    end
end

--------------------------------------------------------------------------------
function ns:PLAYER_REGEN_DISABLED()
    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    self:MODIFIER_STATE_CHANGED("LSHIFT", 0)
end

function ns:PLAYER_REGEN_ENABLED()
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:MODIFIER_STATE_CHANGED("LSHIFT", IsShiftKeyDown() and 1 or 0)
end

function ns:MODIFIER_STATE_CHANGED(key, state)
    -- self:Print('MODIFIER_STATE_CHANGED Key: %s; State: %s', key,state)
    if key ~= "LSHIFT" and key ~= "RSHIFT" then
        return
    end
    local a, b, c
    if state == 1 then
        a, b, c = "CustomFilter", "__CustomFilter", ns.CustomAuraFilters.default
    else
        a, b = "__CustomFilter", "CustomFilter"
    end
    for i = 1, #oUF.objects do
        local object = oUF.objects[i]
        local buffs = object.Auras or object.Buffs
        if buffs and buffs[a] then
            buffs[b] = buffs[a]
            buffs[a] = c
            buffs:ForceUpdate()
        end
        local debuffs = object.Debuffs
        if debuffs and debuffs[a] then
            debuffs[b] = debuffs[a]
            debuffs[a] = c
            debuffs:ForceUpdate()
        end
    end
end

--------------------------------------------------------------------------------
-- Fin
