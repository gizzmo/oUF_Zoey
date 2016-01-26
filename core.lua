-- Get the addon namespace
local addonName, ns = ...

-- Set global name of addon
_G[addonName] = ns

-- Initialize Ace3 onto the namespace
LibStub('AceAddon-3.0'):NewAddon(ns, addonName, 'AceConsole-3.0', 'AceEvent-3.0')

--------------------------------------------------------------------------------
-- Default configuration
--------------------------------------------------------------------------------
local defaultDB = {
    profile = {

        statusbar = 'Armory',
        font = 'DorisPP',

        ptgap = 150,         -- gap between player and target
        frames_offset = 270, -- offset from bottom of UIParent

    }
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
-- Called when the addon is loaded
function ns:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName..'DB', defaultDB, true)
    self:RegisterChatCommand('zoey', 'SlashCommandHandler')

    -- Register our media with SharedMedia
    local Media = LibStub('LibSharedMedia-3.0')
    Media:Register('statusbar', 'Armory', [[Interface\AddOns\oUF_Zoey\media\Statusbar.tga]])
    Media:Register('font', 'DorisPP', [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]])
end

-- Called when the addon is enabled
function ns:OnEnable()
    ns:DisableBlizzard()
    ns:SkinMirrorTimer()
    ns:SpawnUnitFrames()
end

function ns:DisableBlizzard()
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
end

function ns:SkinMirrorTimer()
    local Media = LibStub('LibSharedMedia-3.0')
    local font = Media:Fetch('font', ns.db.profile.font)
    local texture = Media:Fetch('statusbar', ns.db.profile.statusbar)

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

function ns:SlashCommandHandler(message)
    local command = self:GetArgs(message, 2)

    -- Option the options window
    if not command or command == 'config' then
        self:Print('Temoprory disabled.')
    end
end


--------------------------------------------------------------------------------
-- Fin
