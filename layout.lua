-- Get the addon namespace
local addon, ns = ...

local colors = oUF.colors

local _, playerClass = UnitClass('player')
local playerUnits = { player = true, pet = true, vehicle = true }

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
ns.mousefocus = nil
local function OnEnter(self)
    UnitFrame_OnEnter(self)

    ns.mousefocus = self
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end

local function OnLeave(self)
    UnitFrame_OnLeave(self)

    ns.mousefocus = nil
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end

local function CreateFontString(parent, size, justify)
    local font = LibStub('LibSharedMedia-3.0'):Fetch('font', ns.config.font)

    local fs = parent:CreateFontString(nil, 'ARTWORK')
    fs:SetFont(font, size or 16)
    fs:SetJustifyH(justify or 'LEFT')
    fs:SetWordWrap(false)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0,0,0,1)

    return fs
end

local function CreateStatusBar(parent, name, noBG)
    local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.config.statusbar)

    local sb = CreateFrame('StatusBar', (name and '$parent'..name or nil), parent)
    sb:SetStatusBarTexture(texture)

    if not noBG then
        sb.bg = sb:CreateTexture(nil, 'BACKGROUND')
        sb.bg:SetTexture(texture)
        sb.bg:SetAllPoints(true)
        sb.bg.multiplier = 0.4
    end

    return sb
end

local function UpdateUnitBorderColor(self)
    if not self.Border or not self.unit then return end

    local c = UnitClassification(self.unit)
    if c == 'worldboss' then c = 'boss' end
    local t = colors.border[c]

    if not t then
        t = colors.border.normal
    end

    self.Border:SetColor(unpack(t))
end


-- Mouseover and Target Highlighting
local function HighlightShouldShow(self)
    -- Frame is curently mouse focused
    if ns.mousefocus == self then
        return true
    end

    -- Frame is not the current target
    if not UnitIsUnit(self.unit, 'target') then
        return false
    end

    -- We dont want to show target highlighting for these frames
    if self.unit == 'player' or strsub(self.unit, 1, 6) == 'target' then
        return false
    end

    return true
end

local function HighlightUpdate(self)
    if HighlightShouldShow(self) then
        self.Highlight:Show()
    else
        self.Highlight:Hide()
    end
end


-- Power coloring: Perfer class color, fall-back to power
local function PostUpdatePower(Power, unit, min, max)
    local r,g,b,t

    if UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        t = colors.class[class]
    else
        local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

        t = colors.power[ptoken]
        if(not t) then
            if(Power.GetAlternativeColor) then
                r, g, b = Power:GetAlternativeColor(unit, ptype, ptoken, altR, altG, altB)
            elseif(altR) then
                r, g, b = altR, altG, altB
            else
                t = colors.power[ptype]
            end
        end
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if b then
        Power:SetStatusBarColor(r, g, b)
        Power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)
    end
end


-- Castbar Functions
local function PostCastStart(Castbar, unit, name, castid)
    local r,g,b = unpack(colors.cast.normal)

    Castbar:SetAlpha(1.0)
    Castbar.Spark:Show()

    Castbar:SetStatusBarColor(r,g,b)
    Castbar.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)

    if Castbar.notInterruptible then
        Castbar:PostCastNotInterruptible(unit)
    else
        Castbar:PostCastInterruptible(unit)
    end
end

local function PostCastStop(Castbar, unit, name, castid)
    Castbar:SetValue(Castbar.max)
    Castbar:Show()
end

local function PostChannelStop(Castbar, unit, name)
    Castbar:SetValue(0)
    Castbar:Show()
end

local function PostCastFailed(Castbar, unit, name, castid)
    local r,g,b = unpack(colors.cast.failed)

    Castbar:SetValue(Castbar.max)
    Castbar:Show()

    Castbar:SetStatusBarColor(r,g,b)
    Castbar.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)
end

local function PostCastInterruptible(Castbar, unit)
    if unit == 'target' then
        Castbar.Frame.Border:SetColor()
    end
end

local function PostCastNotInterruptible(Castbar, unit)
    if unit == 'target' then
        Castbar.Frame.Border:SetColor(1,1,1)
    end
end

-- We overwrite the `OnUpdate` function so we can fade out after.
local function CastbarOnUpdate(Castbar, elapsed)
    if Castbar.casting or Castbar.channeling then
        local duration = Castbar.casting and Castbar.duration + elapsed or Castbar.duration - elapsed
        local remaining = (duration * -1 + Castbar.max) -- incase i want to use it :p
        if (Castbar.casting and duration >= Castbar.max) or (Castbar.channeling and duration <= 0) then
            Castbar.casting = nil
            Castbar.channeling = nil
            return
        end

        local latency = select(4, GetNetStats())

        if Castbar.SafeZone then
            local width = Castbar:GetWidth() * (latency / 1e3) / Castbar.max
            if width < 1 then width = 1 end
            if width > Castbar:GetWidth() then width = Castbar:GetWidth() end
            Castbar.SafeZone:SetWidth(width)
        end

        if Castbar.Lag then
            Castbar.Lag:SetFormattedText('%d ms', latency)
        end

        if Castbar.Time then
            if Castbar.delay ~= 0 then
                Castbar.Time:SetFormattedText('|cffff0000-%.1f|r %.1f | %.1f', Castbar.delay, duration, Castbar.max)
            else
                Castbar.Time:SetFormattedText('%.1f | %.1f', duration, Castbar.max)
            end
        end

        Castbar.duration = duration
        Castbar:SetValue(duration)
        if Castbar.Spark then
            Castbar.Spark:SetPoint('CENTER', Castbar, 'LEFT', (duration / Castbar.max) * Castbar:GetWidth(), 0)
        end
    else
        Castbar.Spark:Hide()
        local alpha = Castbar:GetAlpha() - 0.08
        if alpha > 0 then
            Castbar:SetAlpha(alpha)
        else
            Castbar:Hide()
        end

    end
end


-- Aura Function
local function PostCreateAuraIcon(iconFrame, button)
    button.cd:SetReverse(true)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count:ClearAllPoints()
    button.count:SetPoint('CENTER', button, 'BOTTOMRIGHT', -1, 0)
    button.count:SetDrawLayer('OVERLAY', 2)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetPoint('TOPLEFT', -1, 1)
    button.bg:SetPoint('BOTTOMRIGHT', 1, -1)
    button.bg:SetColorTexture(0, 0, 0, 1)
end

local function PostUpdateAuraIcon(iconFrame, unit, button, index, offset)
    local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, button.filter)

    if playerUnits[caster] then
        button.icon:SetDesaturated(false)
    else
        button.icon:SetDesaturated(true)
    end

    if unit == 'player' then
        button:SetScript('OnMouseUp', function(self, mouseButton)
            if mouseButton ~= 'RightButton'
            or InCombatLockdown()
            then return end

            CancelUnitBuff(unit, index)
        end)
    end
end


-- Corner Indicators
local CreateCornerIndicator
do
    local CORNER_BACKDROP = {
        bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8,
        edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    }

    function CreateCornerIndicator(parent)
        local square = CreateFrame('Frame', nil, parent)
        square:SetBackdrop(CORNER_BACKDROP)
        square:SetBackdropBorderColor(0, 0, 0, 1)
        square:SetSize(6,6)
        return square
    end
end

local function LFDOverride(self)
    local LFDRole = self.LFDRole
    local Role = UnitGroupRolesAssigned(self.unit)
    if Role == 'TANK' then
        LFDRole:SetBackdropColor(1, 1, 1, 1)
        LFDRole:Show()
    elseif Role == 'HEALER' then
        LFDRole:SetBackdropColor(0, 1, 0, 1)
        LFDRole:Show()
    else
        LFDRole:Hide()
    end
end


-- ClassIcons Functions
local ClassIconsUpdateTexture
do
    local classPowerType = {
        MONK    = 'CHI',
        PALADIN = 'HOLY_POWER',
        PRIEST  = 'SHADOW_ORBS',
        WARLOCK = 'SOUL_SHARDS',
        ROGUE   = 'COMBO_POINTS',
        DRUID   = 'COMBO_POINTS',
        MAGE    = 'ARCANE_CHARGES'
    }

    function ClassIconsUpdateTexture(element)
        local color = oUF.colors.power[classPowerType[playerClass]]
        for i = 1, #element do
            local icon = element[i]

            icon:SetVertexColor(color[1], color[2], color[3])
            icon.bg:SetVertexColor(color[1]*0.4, color[2]*0.4, color[3]*0.4)
        end
    end
end

local function ClassIconsPostUpdate(self, cur, max, hasMaxChanged, powerType, event)
    -- Show or hide the entire frame on enable/disable
    if event == 'ClassPowerDisable' then return self:Hide()
    elseif event == 'ClassPowerEnable' then self:Show() end

    -- Figure out the width
    local width = ((self:GetWidth() - (max-1)) / max)

    for i = 1, max do
        self[i]:SetWidth(width)
        self[i].bg:Show()
    end

    -- hide unused bgs
    for i = max + 1, 6 do
        self[i].bg:Hide()
    end
end


-- HealPrediction
local function CreateHealPrediction(self, vertical)
    local myBar = CreateStatusBar(self.Health, nil, true)
    myBar:SetStatusBarColor(64/255, 204/255, 255/255, .7)

    local otherBar = CreateStatusBar(self.Health, nil, true)
    otherBar:SetStatusBarColor(64/255, 255/255, 64/255, .7)

    local absorbBar = CreateStatusBar(self.Health, nil, true)
    absorbBar:SetStatusBarColor(220/255, 255/255, 230/255, .7)

    local healAbsorbBar = CreateStatusBar(self.Health, nil, true)
    healAbsorbBar:SetStatusBarColor(220/255, 228/255, 255/255, .7)

    -- Loop over the bars and set the points
    local bars = {myBar,otherBar,absorbBar,healAbsorbBar}
    for i=1, #bars do

        if vertical then
            bars[i]:SetHeight(self:GetHeight())
            bars[i]:SetOrientation('VERTICAL')
            bars[i]:SetPoint('LEFT')
            bars[i]:SetPoint('RIGHT')
            bars[i]:SetPoint('BOTTOM', self.Health:GetStatusBarTexture(), 'TOP')
        else
            bars[i]:SetWidth(self:GetWidth())
            bars[i]:SetPoint('TOP')
            bars[i]:SetPoint('BOTTOM')
            bars[i]:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
        end
    end

    -- Register with oUF
    self.HealPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        maxOverflow = 1.00,
        frequentUpdates = true,
    }
end


--------------------------------------------------------------------------------
-- Things every style will have
--------------------------------------------------------------------------------
local function InitStyle(self, unit, isSingle)
    -- Make the frame interactiveable
    self:RegisterForClicks('AnyUp')
    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)

    -- Background
    self.bg = self:CreateTexture(nil, 'BACKGROUND')
    self.bg:SetAllPoints(self)
    self.bg:SetColorTexture(0, 0, 0, 1)

    -- Border: changes color depending on the unit's classification (rare,elite)
    ns.CreateBorder(self)
    self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
    table.insert(self.__elements, UpdateUnitBorderColor)

    -- Overlay Frame -- used to attach icons/text to
    self.Overlay = CreateFrame('Frame', '$parentOverlay', self)
    self.Overlay:SetAllPoints(self)
    self.Overlay:SetFrameLevel(10) -- todo: does it have to be that high?

    -- Highlight
    self.Highlight = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.Highlight:SetAllPoints(self)
    self.Highlight:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
    self.Highlight:SetBlendMode('ADD')
    self.Highlight:SetVertexColor(1,1,1)
    self.Highlight:SetAlpha(0.3)
    self.Highlight:Hide()

    self:HookScript('OnEnter', HighlightUpdate)
    self:HookScript('OnLeave', HighlightUpdate)
    self:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate)
    table.insert(self.__elements, HighlightUpdate)

    -- Frame Range Fading
    self[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.5
    }

    -- All frames will have a health status bar
    self.Health = CreateStatusBar(self, 'HealthBar')
    self.Health:SetPoint('TOP', 0, -1)
    self.Health:SetPoint('LEFT', 1, 0)
    self.Health:SetPoint('RIGHT', -1, 0)
    self.Health:SetPoint('BOTTOM', 0, 1)
    self.Health.frequentUpdates = true
    self.Health.colorTapping = true
    self.Health.colorDisconnected = true
    self.Health.colorHealth = true

    -- DispelHighlight
    self.DispelHighlight = self.Overlay:CreateTexture(nil, 'Overlay')
    self.DispelHighlight:SetAllPoints(self.Health)
    self.DispelHighlight:SetTexture([[Interface\AddOns\oUF_Zoey\media\Dispel.tga]])
    self.DispelHighlight:SetBlendMode('ADD')
    self.DispelHighlight:SetAlpha(0.7)

end

-- Main Core style
oUF:RegisterStyle('Zoey', function(self, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 40
    local FRAME_WIDTH = 135
    local POWER_HEIGHT = 10 -- (FRAME_HEIGHT * 0.2)

    if unit == 'player' or unit == 'target' then
        FRAME_WIDTH = 227
    end

    if isSingle then
        self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    -- Initliaze the style
    InitStyle(self, unit, isSingle)
    CreateHealPrediction(self)

    ----------------------------------------------------------------------------
    -- Build the other status bars
    ----------------------------------------------------------------------------
    self.Power = CreateStatusBar(self, 'PowerBar')
    self.Power:SetHeight(POWER_HEIGHT)
    self.Power:SetPoint('LEFT', 1, 0)
    self.Power:SetPoint('RIGHT', -1, 0)
    self.Power:SetPoint('BOTTOM', 0, 1)
    self.Power.frequentUpdates = true
    self.Power.PostUpdate = PostUpdatePower

    self.Health:SetPoint('BOTTOM', self.Power, 'TOP', 0, 1)

    if unit == 'party' then
        local PORTRAIT_HEIGHT = FRAME_HEIGHT
        self.Portrait = CreateFrame('PlayerModel', '$parentPortrait', self)
        self.Portrait:SetHeight(PORTRAIT_HEIGHT - 1.5)
        self.Portrait:SetPoint('TOP', 0, -1)
        self.Portrait:SetPoint('LEFT', 1, 0)
        self.Portrait:SetPoint('RIGHT', -2, 0)
        self.Portrait:SetAlpha(0.4)

        self.Health:SetPoint('TOP', self.Portrait, 'BOTTOM', 0, -1.5)

        -- Keep this var up to date
        FRAME_HEIGHT = FRAME_HEIGHT + PORTRAIT_HEIGHT

        --
        if isSingle then self:SetHeight(FRAME_HEIGHT) end
    end

    ----------------------------------------------------------------------------
    -- Class Specific
    ----------------------------------------------------------------------------
    -- Class Icons -- NOTE: only monk is tested, tho all others should work
    if unit == 'player' and (playerClass == 'MONK') then
        self.ClassIcons = CreateFrame('Frame', '$parentClassIcons', self)
        self.ClassIcons:SetHeight(8)
        self.ClassIcons:SetWidth(FRAME_WIDTH * 0.95)
        self.ClassIcons:SetPoint('TOP', self, 'BOTTOM', 0, -3)
        self.ClassIcons:SetFrameLevel(self:GetFrameLevel() -1)
        ns.CreateBorder(self.ClassIcons)

        self.ClassIcons.bg = self.ClassIcons:CreateTexture(nil,'BACKGROUND')
        self.ClassIcons.bg:SetAllPoints(self.ClassIcons)
        self.ClassIcons.bg:SetColorTexture(0,0,0,1)

        self.ClassIcons.PostUpdate = ClassIconsPostUpdate
        self.ClassIcons.UpdateTexture = ClassIconsUpdateTexture

        local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.config.statusbar)

        for i = 1, 6 do
            local icon = self.ClassIcons:CreateTexture(nil, 'ARTWORK', nil, 2)
            icon:SetTexture(texture)

            icon:SetPoint('TOP')
            icon:SetPoint('BOTTOM')
            icon:SetPoint('LEFT')

            if i ~= 1 then
                icon:SetPoint('LEFT', self.ClassIcons[i-1], 'RIGHT', 1, 0)
            end

            icon.bg = self.ClassIcons:CreateTexture(nil, 'BACKGROUND', nil, 1)
            icon.bg:SetTexture(texture)
            icon.bg:SetAllPoints(icon)

            self.ClassIcons[i] = icon
        end
    end

    -- Monk Stagger Bar
    if unit == 'player' and playerClass == 'MONK' then
        self.Stagger = CreateStatusBar(self, 'StaggerBar')
        self.Stagger:SetFrameLevel(self:GetFrameLevel()-1)

        -- Build a frame around the stagger bar
        self.Stagger.Frame = CreateFrame('Frame', '$parentStaggerFrame', self.Stagger)
        self.Stagger.Frame:SetFrameLevel(self.Stagger:GetFrameLevel()-1)
        self.Stagger.Frame.bg = self.Stagger:CreateTexture(nil, 'BACKGROUND')
        self.Stagger.Frame.bg:SetAllPoints(self.Stagger.Frame)
        self.Stagger.Frame.bg:SetColorTexture(0, 0, 0, 1)
        ns.CreateBorder(self.Stagger.Frame)

        -- Size and place the Stagger Frame
        self.Stagger.Frame:SetHeight(8)
        self.Stagger.Frame:SetWidth(FRAME_WIDTH * 0.95)
        self.Stagger.Frame:SetPoint('TOP', self, 'BOTTOM', 0, -3)

        -- Attach the Stagger bar to the Frame
        self.Stagger:SetPoint('TOPLEFT', self.Stagger.Frame)
        self.Stagger:SetPoint('BOTTOMRIGHT', self.Stagger.Frame, 0, 1)
    end

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    self.NameTag = CreateFontString(self.Overlay, 13)
    self.NameTag:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    self.NameTag:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    self:Tag(self.NameTag, '[leadericon][Level< ][Name][ - >Realm]')

    self.HealthTag = CreateFontString(self.Overlay, 17)
    self.HealthTag:SetPoint('RIGHT', self.Health, -1, -1)
    self.HealthTag.frequentUpdates = true
    self:Tag(self.HealthTag, '[Health]')

    self.PowerTextTag = CreateFontString(self.Overlay, 10)
    self.PowerTextTag:SetPoint('RIGHT', self.Power, -1, -1)
    self.PowerTextTag.frequentUpdates = true
    self:Tag(self.PowerTextTag, '[Power]')

    if self.Portrait then
        self.GuildTag = CreateFontString(self.Overlay, 12)
        self.GuildTag:SetPoint('TOP', self.NameTag, 'BOTTOM', 0, -1)
        self.GuildTag:SetPoint('LEFT', self.NameTag)
        self.GuildTag:SetPoint('RIGHT', self.NameTag)
        self:Tag(self.GuildTag, '[Guild]')
    end

    ----------------------------------------------------------------------------
    -- Icons
    ----------------------------------------------------------------------------
    if unit == 'player' then
        self.Resting = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.Resting:SetSize(20,20)
        self.Resting:SetPoint('LEFT', self.Overlay, 'BOTTOMLEFT', 0, 2)

        self.Combat = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.Combat:SetSize(20,20)
        self.Combat:SetPoint('RIGHT', self.Overlay, 'BOTTOMRIGHT', 0, 2)
    end

    if unit == 'target' then
        self.QuestIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.QuestIcon:SetSize(32,32)
        self.QuestIcon:SetPoint('CENTER', self.Overlay, 'LEFT')
    end

    self.LFDRole = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.LFDRole:SetSize(15,15)
    self.LFDRole:SetPoint('CENTER', self.Overlay, 'TOPRIGHT', 1, 0)

    if unit == 'party' then
        self.ReadyCheck = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.ReadyCheck:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
        self.ReadyCheck:SetPoint('CENTER')
    end

    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(23,23)
    self.RaidIcon:SetPoint('LEFT', 3, 0)

    self.PvP = self.Overlay:CreateTexture(nil, 'OVERLAY', nil, 1)
    self.PvP:SetSize(21,21)
    self.PvP:SetPoint('CENTER', self.Overlay, 'LEFT')

    self.PvP.Prestige = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.PvP.Prestige:SetSize(41,43)
    self.PvP.Prestige:SetPoint('CENTER', self.PvP)

    if unit == 'party' or unit == 'target' or unit == 'focus' then
        self.PhaseIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.PhaseIcon:SetPoint('TOP', self)
        self.PhaseIcon:SetPoint('BOTTOM', self)
        self.PhaseIcon:SetWidth(FRAME_HEIGHT * 2)
        self.PhaseIcon:SetTexture([[Interface\Icons\Spell_Frost_Stun]])
        self.PhaseIcon:SetTexCoord(0.05, 0.95, 0.25, 0.75)
        self.PhaseIcon:SetAlpha(0.5)
        self.PhaseIcon:SetBlendMode('ADD')
        self.PhaseIcon:SetDesaturated(true)
        self.PhaseIcon:SetVertexColor(0.4, 0.8, 1)
    end

    self.ResurrectIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ResurrectIcon:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ResurrectIcon:SetPoint('CENTER')

    ----------------------------------------------------------------------------
    -- Cast Bars
    ----------------------------------------------------------------------------
    if unit == 'player' or unit == 'target' then
        self.Castbar = CreateStatusBar(self, 'Castbar')

        -- Build a frame around the Castbar
        self.Castbar.Frame = CreateFrame('Frame', '$parentFrame', self.Castbar)
        self.Castbar.Frame:SetFrameLevel(self.Castbar:GetFrameLevel()-1)
        self.Castbar.Frame.bg = self.Castbar.Frame:CreateTexture(nil, 'BACKGROUND')
        self.Castbar.Frame.bg:SetAllPoints(self.Castbar.Frame)
        self.Castbar.Frame.bg:SetColorTexture(0, 0, 0, 1)
        ns.CreateBorder(self.Castbar.Frame)

        -- Attach the Castbar to the Frame
        self.Castbar:SetPoint('TOPLEFT', self.Castbar.Frame, 1, -1)
        self.Castbar:SetPoint('BOTTOMRIGHT', self.Castbar.Frame, -1, 1)

        -- Size and place the Castbar Frame
        if unit == 'player' then
            self.Castbar.Frame:SetSize(320,20)
            self.Castbar.Frame:SetPoint('BOTTOM', oUF_ZoeyUnitFrameAnchor, 0, -30)
        elseif unit == 'target' then
            self.Castbar.Frame:SetSize(500,30)
            self.Castbar.Frame:SetPoint('BOTTOM', oUF_ZoeyUnitFrameAnchor, 0, 127)
        end

        -- Spell Icon
        if unit == 'target' then
            self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'BACKDROP')
            self.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            self.Castbar.Icon:SetPoint('TOPLEFT', self.Castbar.Frame, 1, -1)
            self.Castbar.Icon:SetPoint('BOTTOMLEFT', self.Castbar.Frame, 1, 1)
            self.Castbar.Icon:SetWidth(self.Castbar.Frame:GetHeight())

            -- Anchor the castbar to the icon.
            self.Castbar:SetPoint('TOPLEFT', self.Castbar.Icon, 'TOPRIGHT', 1, 0)
        end

        -- Add a spark
        self.Castbar.Spark = self.Castbar:CreateTexture(nil, 'OVERLAY')
        self.Castbar.Spark:SetHeight(self.Castbar:GetHeight()*2.5)
        self.Castbar.Spark:SetBlendMode('ADD')
        self.Castbar.Spark:SetAlpha(0.5)

        -- Player only Latency
        if unit == 'player' then
            self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'OVERLAY')
            self.Castbar.SafeZone:SetTexture(self.Castbar:GetStatusBarTexture():GetTexture())
            self.Castbar.SafeZone:SetVertexColor(unpack(colors.cast.safezone))

            self.Castbar.Lag = CreateFontString(self.Castbar, 10)
            self.Castbar.Lag:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -7)
        end

        -- Castbar Texts
        if unit == 'player' then
            self.Castbar.Text = CreateFontString(self.Castbar, 14)
            self.Castbar.Time = CreateFontString(self.Castbar, 10)

        elseif unit == 'target' then
            self.Castbar.Text = CreateFontString(self.Castbar, 20)
            self.Castbar.Time = CreateFontString(self.Castbar, 16)
        end
        self.Castbar.Text:SetPoint('LEFT', 10, 0)
        self.Castbar.Time:SetPoint('RIGHT', -10, 0)

        -- Castbar Function Hooks
        self.Castbar.OnUpdate = CastbarOnUpdate
        self.Castbar.PostCastStart = PostCastStart
        self.Castbar.PostChannelStart = PostCastStart
        self.Castbar.PostCastStop = PostCastStop
        self.Castbar.PostChannelStop = PostChannelStop
        self.Castbar.PostCastFailed = PostCastFailed
        self.Castbar.PostCastInterrupted = PostCastFailed
        self.Castbar.PostCastInterruptible = PostCastInterruptible
        self.Castbar.PostCastNotInterruptible = PostCastNotInterruptible
    end

    ----------------------------------------------------------------------------
    -- Auras
    ----------------------------------------------------------------------------
    if unit == 'player' or unit == 'pet' or unit == 'target' then

        self.Buffs = CreateFrame('Frame', '$parentBuffs', self)

        self.Buffs['growth-y'] = 'UP'
        self.Buffs['spacing'] = 3
        self.Buffs['size'] = 20

        local size = (self.Buffs['size'] + self.Buffs['spacing'])

        if unit == 'player' then
            self.Buffs:SetSize(size * 6, 1)
            self.Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 8)
            self.Buffs['initialAnchor'] = 'BOTTOMLEFT'
            self.Buffs['growth-x'] = 'RIGHT'

        elseif unit == 'target' then
            self.Buffs:SetSize(size * 2, 1)
            self.Buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 8)
            self.Buffs['initialAnchor'] = 'BOTTOMRIGHT'
            self.Buffs['growth-x'] = 'LEFT'
        end
        self.Buffs['num'] = floor(self.Buffs:GetWidth() / size + .5) * 4

        self.Buffs.PostCreateIcon = PostCreateAuraIcon
        self.Buffs.PostUpdateIcon = PostUpdateAuraIcon
    end

    if unit == 'player' or unit == 'target' then

        self.Debuffs = CreateFrame('Frame', '$parentDebuffs', self)

        self.Debuffs['growth-y'] = 'UP'
        self.Debuffs['spacing'] = 3
        self.Debuffs['size'] = 43

        local size = (self.Debuffs['size'] + self.Debuffs['spacing'])

        if unit == 'player' then
            self.Debuffs:SetSize(size * 2, 1)
            self.Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 8)
            self.Debuffs['initialAnchor'] = 'BOTTOMRIGHT'
            self.Debuffs['growth-x'] = 'LEFT'
        elseif unit == 'target' then
            self.Debuffs:SetSize(size * 4, 1)
            self.Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 8)
            self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
            self.Debuffs['growth-x'] = 'RIGHT'
        end

        self.Debuffs['num'] = floor(self.Debuffs:GetWidth() / size + .5) * 2

        self.Debuffs.PostCreateIcon = PostCreateAuraIcon
        self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
    elseif unit == 'party' then

        self.Debuffs = CreateFrame('Frame', '$parentDebuffs', self)
        self.Debuffs:SetSize(FRAME_WIDTH, 1)
        self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 12, -15)

        self.Debuffs['initialAnchor'] = 'LEFT'
        self.Debuffs['growth-x'] = 'RIGHT'
        self.Debuffs['spacing'] = 3
        self.Debuffs['size'] = 30

        local size = (self.Debuffs['size'] + self.Debuffs['spacing'])
        self.Debuffs['num'] = floor(self.Debuffs:GetWidth() / size + .5)

        self.Debuffs.PostCreateIcon = PostCreateAuraIcon
        self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
    end

end)

oUF:RegisterStyle('ZoeyThin', function(self, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 20
    local FRAME_WIDTH  = 135

    if isSingle then
        self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    -- Initliaze the style
    InitStyle(self, unit, isSingle)
    CreateHealPrediction(self)

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    self.NameTag = CreateFontString(self.Overlay, 11)
    self.NameTag:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    self.NameTag:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    self:Tag(self.NameTag, '[Level< ][Name]')

    self.StatusTextTag = CreateFontString(self.Overlay, 15)
    self.StatusTextTag:SetPoint('RIGHT', self.Health, -1, 0)
    self:Tag(self.StatusTextTag, '[Status]')

    ----------------------------------------------------------------------------
    -- Icons
    ----------------------------------------------------------------------------
    self.Leader = CreateCornerIndicator(self.Overlay)
    self.Leader:SetBackdropColor(0.65, 0.65, 1, 1)
    self.Leader:SetPoint('TOPLEFT')

    self.Assistant = CreateCornerIndicator(self.Overlay)
    self.Assistant:SetBackdropColor(1, 0.75, 0.5, 1)
    self.Assistant:SetPoint('TOPLEFT')

    self.LFDRole = CreateCornerIndicator(self.Overlay)
    self.LFDRole:SetPoint('TOPRIGHT')
    self.LFDRole.Override = LFDOverride

    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(16,16)
    self.RaidIcon:SetPoint('LEFT', 3, 0)

end)

oUF:RegisterStyle('ZoeySquare', function(self, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 40
    local FRAME_WIDTH  = 65
    local POWER_HEIGHT = 5

    if isSingle then
        self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    -- Initliaze the style
    InitStyle(self, unit, isSingle)
    CreateHealPrediction(self,true)

    -- Grow healthbar top to bottom
    self.Health:SetOrientation('VERTICAL')

    -- Change Range Fading
    self[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.25
    }

    ----------------------------------------------------------------------------
    -- Build the other status bars
    ----------------------------------------------------------------------------
    self.Power = CreateStatusBar(self, 'PowerBar')
    self.Power:SetHeight(POWER_HEIGHT)
    self.Power:SetPoint('LEFT', 1, 0)
    self.Power:SetPoint('RIGHT', -1, 0)
    self.Power:SetPoint('BOTTOM', 0, 1)
    self.Power.PostUpdate = PostUpdatePower

    self.Health:SetPoint('BOTTOM', self.Power, 'TOP', 0, 1)

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    self.NameTag = CreateFontString(self.Overlay, 9, 'center')
    self.NameTag:SetPoint('TOPLEFT', 3, -3)
    self.NameTag:SetPoint('TOPRIGHT', -3, -3)
    self:Tag(self.NameTag, '[Name]')

    self.StatusTextTag = CreateFontString(self.Overlay, 11, 'center')
    self.StatusTextTag:SetPoint('BOTTOMLEFT', self.Health, 3, 1)
    self.StatusTextTag:SetPoint('BOTTOMRIGHT', self.Health, -3, 1)
    self:Tag(self.StatusTextTag, '[Status]')

    ----------------------------------------------------------------------------
    -- Icons
    ----------------------------------------------------------------------------
    self.Leader = CreateCornerIndicator(self.Overlay)
    self.Leader:SetBackdropColor(0.65, 0.65, 1, 1)
    self.Leader:SetPoint('TOPLEFT')

    self.Assistant = CreateCornerIndicator(self.Overlay)
    self.Assistant:SetBackdropColor(1, 0.75, 0.5, 1)
    self.Assistant:SetPoint('TOPLEFT')

    self.LFDRole = CreateCornerIndicator(self.Overlay)
    self.LFDRole:SetPoint('TOPRIGHT')
    self.LFDRole.Override = LFDOverride

    self.ReadyCheck = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ReadyCheck:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ReadyCheck:SetPoint('CENTER')

    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(16,16)
    self.RaidIcon:SetPoint('LEFT', 3, 0)

    self.ResurrectIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ResurrectIcon:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ResurrectIcon:SetPoint('CENTER')

end)
