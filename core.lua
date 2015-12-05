-- Get the addon namespace
local addon, ns = ...

--//----------------------------
--// SPAWN UNITS
--//----------------------------
local u = {}
local function SpawnUnit(unit)
    local object = oUF:Spawn(unit, 'oUF_Zoey'..unit)
    u[unit:lower()] = object
    return object
end

local function SpawnHeader(name, visibility, ...)
    local object = oUF:SpawnHeader('oUF_Zoey'..name, nil, visibility, ...)
    u[name:lower()] = object
    return object
end

oUF:Factory(function(self)

    local frames_offset, ptgap, gap = ns.config.frames_offset, ns.config.ptgap, 12

    -- The frame that all unitframes are attached to.
    local Anchor = CreateFrame('Frame', 'oUF_ZoeyUnitFrameAnchor', UIParent)
    Anchor:SetSize(ptgap, 1)
    Anchor:SetPoint('CENTER', UIParent, 'BOTTOM', 0, frames_offset)

    --//----------------------------
    -- Player
    SpawnUnit('Player'):SetPoint('RIGHT', Anchor, 'LEFT', 0, 0)

    -- Player Pet
    SpawnUnit('Pet'      ):SetPoint('RIGHT', u.player, 'LEFT', -gap, 0)
    SpawnUnit('PetTarget'):SetPoint('BOTTOM', u.pet, 'TOP', 0, gap)

    -- Targets
    SpawnUnit('Target'      ):SetPoint('LEFT', Anchor, 'RIGHT', 0, 0)
    SpawnUnit('TargetTarget'):SetPoint('LEFT', u.target, 'RIGHT', gap, 0)

    -- Focus
    self:SetActiveStyle('ZoeyThin')
    SpawnUnit('Focus'      ):SetPoint('BOTTOMRIGHT', u.player, 'TOPLEFT', -100, 75)
    SpawnUnit('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, gap)

    --//----------------------------
    -- Party -- note: 130 - height = yoffset
    self:SetActiveStyle('Zoey')
    local party = SpawnHeader('Party', 'party',
        'showParty', true,
        'yOffset', 50,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetWidth( 135 )
            self:SetHeight( 80 )
        ]]
    )
    party:SetPoint('BOTTOM', Anchor, 'CENTER', 0, -20)
    party:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)

    -- Party Targets
    SpawnHeader('PartyTargets', 'party',
        'showParty', true,
        'yOffset', 90,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'target')
            self:SetWidth( 135 )
            self:SetHeight( 40 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 'BOTTOMRIGHT', gap, 0)

    -- Party Pets
    self:SetActiveStyle('ZoeyThin')
    SpawnHeader('PartyPets', 'party',
        'showParty', true,
        'yOffset', 110,
        'point', 'BOTTOM',
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'pet')
            self:SetWidth( 135 )
            self:SetHeight( 20 )
        ]]
    ):SetPoint('BOTTOMLEFT', u.party, 0, -28)

    --//----------------------------
    -- Raid Size 1 - 10
    self:SetActiveStyle('ZoeyThin')
    local Raid = {}
    for i = 1, 2 do
        Raid[i] = SpawnHeader('Raid10_g'..i,
            'custom [@raid11,exists] hide; [@raid1,exists] show; hide',

            'showRaid', true,
            'yOffset', gap,
            'groupFilter', tostring(i),
            'point', 'BOTTOM',
            'oUF-initialConfigFunction', [[
                self:SetWidth( 135 )
                self:SetHeight( 20 )
            ]]
        )

        if i == 1 then
            Raid[i]:SetPoint('BOTTOM', Anchor, 'CENTER', 0, -20)
            Raid[i]:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)
        else
            Raid[i]:SetPoint('BOTTOM', Raid[i - 1], 'TOP', 0, gap)
        end
    end

    -- Raid Size 11 - 40
    self:SetActiveStyle('ZoeySquare')
    local Raid = {}
    for i = 1, 8 do
        Raid[i] = SpawnHeader('Raid25_g'..i,
            'custom [@raid11,exists] show; hide ',

            'showRaid', true,
            'xOffset', gap/2,
            'groupFilter', tostring(i),
            'point', 'LEFT',
            'oUF-initialConfigFunction', [[
                self:SetWidth( 53 )
                self:SetHeight( 33 )
            ]]
        )

        if i == 1 then
            Raid[i]:SetPoint('BOTTOM', Anchor, 'CENTER', 0, -20)
            Raid[i]:SetPoint('LEFT', UIParent, 'LEFT', gap, 0)
        else
            Raid[i]:SetPoint('BOTTOMLEFT', Raid[i - 1], 'TOPLEFT', 0, gap)
        end
    end

    --//----------------------------
    -- Boss Frames
    self:SetActiveStyle('Zoey')
    local Boss = {}
    for i = 1, MAX_BOSS_FRAMES do
        Boss[i] = SpawnUnit('boss'..i)

        if i == 1 then
            Boss[i]:SetPoint('BOTTOMLEFT', u.target, 'TOPRIGHT', 100, 75)
        else
            Boss[i]:SetPoint('BOTTOM', Boss[i - 1], 'TOP', 0, gap)
        end
    end
end)

--//----------------------------
--// Extra Stuff for the UI
--//----------------------------
oUF:Factory(function(self)

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

--//----------------------------
-- THE END
