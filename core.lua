-- Get the addon namespace
local addonName, ns = ...

-- Set global name
_G[addonName] = ns

-- Default configuration
local defaultDB = {

    statusbar = 'Armory',
    font = 'DorisPP',

    ptgap = 150,         -- gap between player and target
    frames_offset = 270, -- offset from bottom of UIParent

    PVP = false, -- enable PVP mode, currently only affects aura filtering
}

-- Setup oUF Colors
local colors = oUF.colors
colors['health'] = {89/255, 89/255, 89/255} -- dark grey
colors['cast'] =  {
    normal   = {89/255, 89/255, 89/255},      -- dark gray
    success  = {20/255, 208/255, 0/255},      -- green
    failed   = {255/255, 12/255, 0/255},      -- dark red
    safezone = {255/255, 25/255, 0/255, 0.5}, -- transparent red
}

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

-- Easier reloadui
_G['SLASH_rl1'] = '/rl'
SlashCmdList['rl'] = ReloadUI

--------------------------------------------------------------------------------
function ns:OnLoad()
    self.db = ns:InitializeDB(addonName..'DB', defaultDB)

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

    -- The raid frames are actaully addons, disable them.
    DisableAddOn("Blizzard_CompactRaidFrames")
    DisableAddOn("Blizzard_CUFProfiles")

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
-- Fin
