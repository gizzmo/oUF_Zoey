-- Get the addon namespace
local addon, ns = ...

local colors = oUF.colors

local _, playerClass = UnitClass('player')
local playerUnits = { player = true, pet = true, vehicle = true }
local classPowerType = {
    MONK    = 'CHI',
    PALADIN = 'HOLY_POWER',
    PRIEST  = 'SHADOW_ORBS',
    WARLOCK = 'SOUL_SHARDS',
}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------
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
    if ns.Mouse_Focus == self then
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

    return false
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
            if(power.GetAlternativeColor) then
                r, g, b = power:GetAlternativeColor(unit, ptype, ptoken, altR, altG, altB)
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

    if Castbar.interrupt then
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
local function PostCreateAuraIcon(iconframe, button)
    button.cd:SetReverse(true)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count:ClearAllPoints()
    button.count:SetPoint('CENTER', button, 'BOTTOMRIGHT', -1, 0)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetPoint('TOPLEFT', -1, 1)
    button.bg:SetPoint('BOTTOMRIGHT', 1, -1)
    button.bg:SetColorTexture(0, 0, 0, 1)
end

local function PostUpdateAuraIcon(iconframe, unit, button, index, offset)
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

-- PvP Icon
local function PvPPostUpdate(icon, status)
    if not status then return end

    -- Fix the texture
    if status == 'Horde' then
        icon:SetTexCoord(0.08, 0.58, 0.045, 0.545)
    elseif status == 'Alliance' then
        icon:SetTexCoord(0.07, 0.58, 0.06, 0.57)
    elseif status == 'ffa' then
        icon:SetTexCoord(0.05, 0.605, 0.015, 0.57)
    end
end

-- Experience Bar
local function ExpOnHide(bar)
    local parent = bar:GetParent()
    ns:Defer(function()
        bar:SetPoint('BOTTOM', 0, -bar:GetHeight())
        parent:SetHeight(parent:GetHeight() - bar:GetHeight() - 1)
    end)
end

local function ExpOnShow(bar)
    local parent = bar:GetParent()
    ns:Defer(function()
        bar:SetPoint('BOTTOM', 0, 1)
        parent:SetHeight(parent:GetHeight() + bar:GetHeight() + 1)
    end)
end

-- Corner Indicators
local CORNER_BACKDROP = {
    bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8,
    edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
    insets = {left = 1, right = 1, top = 1, bottom = 1},
}

local function CreateCornerIndicator(parent)
    local square = CreateFrame('Frame', nil, parent)
    square:SetBackdrop(CORNER_BACKDROP)
    square:SetBackdropBorderColor(0, 0, 0, 1)
    square:SetSize(6,6)
    return square
end

-- Icon Overrides
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
local function ClassIconsUpdateTexture(element)
    local color = oUF.colors.power[classPowerType[playerClass]]
    for i = 1, #element do
        local icon = element[i]

        icon:SetVertexColor(color[1], color[2], color[3])
        icon.bg:SetVertexColor(color[1]*0.4, color[2]*0.4, color[3]*0.4)
    end
end

local function ClassIconsPostUpdate(self, cur, max, hasMaxChanged, event)
    if not hasMaxChanged then return end -- dont need to udpate

    -- Figure out the width
    local width = ((self:GetWidth() - (max-1)) / max)

    for i = 1, max do
        self[i]:SetWidth(width) -- TODO: do we need to defer this?
        self[i].bg:Show()
    end

    -- hide unused bgs
    for i = max + 1, 6 do
        self[i].bg:Hide()
    end
end

-- Other Functions
ns.Mouse_Focus = nil
local function OnEnter(self)
    UnitFrame_OnEnter(self)

    ns.Mouse_Focus = self
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end

local function OnLeave(self)
    UnitFrame_OnLeave(self)

    ns.Mouse_Focus = nil
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end

local function CreateFontString(parent, size, justify)
    local font = LibStub('LibSharedMedia-3.0'):Fetch('font', ns.db.font)

    local fs = parent:CreateFontString(nil, 'ARTWORK')
    fs:SetFont(font, size or 16)
    fs:SetJustifyH(justify or 'LEFT')
    fs:SetWordWrap(false)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0,0,0,1)
    tinsert(ns.fontstrings, fs)

    return fs
end

local function CreateStatusBar(parent, name, noBG)
    local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.db.statusbar)

    local sb = CreateFrame('StatusBar', (name and '$parent'..name or nil), parent)
    sb:SetStatusBarTexture(texture)
    tinsert(ns.statusbars, sb)

    if not noBG then
        sb.bg = sb:CreateTexture(nil, 'BACKGROUND')
        sb.bg:SetTexture(texture)
        sb.bg:SetAllPoints(true)
        tinsert(ns.statusbars, sb.bg)
    end

    return sb
end

--------------------------------------------------------------------------------
-- Things every style will have
--------------------------------------------------------------------------------
local function InitStyle(self, unit, isSingle)
    -- Make the frame interactiveable
    self:RegisterForClicks('AnyUp')
    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)

    -- Change the Strata layer
    self:SetFrameStrata('LOW')

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
    self.Health.colorTapping = true
    self.Health.colorDisconnected = true
    self.Health.colorHealth = true
    self.Health.bg.multiplier = 0.4

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
        FRAME_WIDTH = 222
    end

    if isSingle then
        self:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    -- Initliaze the style
    InitStyle(self, unit, isSingle)

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

    if unit == 'player' and UnitLevel(unit) ~= MAX_PLAYER_LEVEL then
        local EXP_HEIGHT = 5
        self.Experience = CreateStatusBar(self, 'Experience', true)
        self.Experience:SetHeight(EXP_HEIGHT - 1)
        self.Experience:SetPoint('LEFT', 1, 0)
        self.Experience:SetPoint('RIGHT', -1, 0)
        self.Experience:SetPoint('BOTTOM', 0, 1)

        self.Experience.Rested = CreateStatusBar(self.Experience, 'Rested')
        self.Experience.Rested:SetAllPoints(self.Experience)

        -- Colors
        local r,g,b = unpack(colors.experience.main)
        self.Experience:SetStatusBarColor(r,g,b)
        self.Experience.Rested:SetStatusBarColor(unpack(colors.experience.rested))
        self.Experience.Rested.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

        -- Resize the main frame when this frame Hides or Shows
        self.Experience:SetScript('OnShow', ExpOnShow)
        self.Experience:SetScript('OnHide', ExpOnHide)

        self.Power:SetPoint('BOTTOM', self.Experience, 'TOP', 0, 1)

        -- Keep this var up to date
        FRAME_HEIGHT = FRAME_HEIGHT + EXP_HEIGHT

        --
        if isSingle then self:SetHeight(FRAME_HEIGHT) end
    end

    ----------------------------------------------------------------------------
    -- Class Specific -- NOTE: Should it be between health and power?
    ----------------------------------------------------------------------------
    if unit == 'player' and (playerClass == 'MONK') then -- NOTE: only monk is tested
        local CI_HEIGHT = 5
        self.ClassIcons = CreateFrame('Frame', '$parentClassIcons', self)
        self.ClassIcons:SetHeight(CI_HEIGHT)

        self.ClassIcons:SetPoint('LEFT', 1, 0)
        self.ClassIcons:SetPoint('RIGHT', -1, 0)
        self.ClassIcons:SetPoint('BOTTOM', (self.Experience or self), 'TOP', 0, 1)

        self.Power:SetPoint('BOTTOM', self.ClassIcons, 'TOP', 0, 1)

        self.ClassIcons:SetFrameLevel(4)
        self.ClassIcons.PostUpdate = ClassIconsPostUpdate
        self.ClassIcons.UpdateTexture = ClassIconsUpdateTexture

        local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.db.statusbar)

        for i = 1, 6 do
            local icon = self.ClassIcons:CreateTexture(nil, 'ARTWORK')
            icon:SetTexture(texture)

            icon:SetPoint('TOP')
            icon:SetPoint('BOTTOM')
            icon:SetPoint('LEFT')

            if i ~= 1 then
                icon:SetPoint('LEFT', self.ClassIcons[i-1], 'RIGHT', 1, 0)
            end

            icon.bg = self.ClassIcons:CreateTexture(nil, 'BACKGROUND')
            icon.bg:SetTexture(texture)
            icon.bg:SetAllPoints(icon)

            self.ClassIcons[i] = icon
        end

        -- Keep this var up to date
        FRAME_HEIGHT = FRAME_HEIGHT + CI_HEIGHT

        --
        if isSingle then self:SetHeight(FRAME_HEIGHT) end
    end

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    self.NameTag = CreateFontString(self.Overlay, 14)
    self.NameTag:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    self.NameTag:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    --TODO: we should reset colors returned from the tags
    self:Tag(self.NameTag, '[leadericon][Level< ][Name][|r - >Realm]')

    if unit == 'target' then
        -- Target uses two health texts to make the
        -- final 20% big and red for Execute and Kill Shot
        self.HealthTag = CreateFontString(self.Overlay, 19)
        self.HealthTag:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(self.HealthTag, '[TargetHealth]')

        self.HealthTag2 = CreateFontString(self.Overlay, 27)
        self.HealthTag2:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(self.HealthTag2, '[TargetHealth2]')
    else
        self.HealthTag = CreateFontString(self.Overlay, 19)
        self.HealthTag:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(self.HealthTag, '[Health]')
    end

    self.PowerTextTag = CreateFontString(self.Overlay, 12)
    self.PowerTextTag:SetPoint('RIGHT', self.Power, -1, -1)
    self:Tag(self.PowerTextTag, '[Power]')

    if self.Experience then
        self.ExperienceTag = CreateFontString(self.Overlay, 10)
        self.ExperienceTag:SetPoint('CENTER', self.Experience, 'BOTTOM', 0, -5)
        self:Tag(self.ExperienceTag, '[Exp]')
    end

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

    self.PvP = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.PvP:SetSize(21,21)
    self.PvP:SetPoint('CENTER', self.Overlay, 'LEFT')
    self.PvP.PostUpdate = PvPPostUpdate

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
            tinsert(ns.statusbars, self.Castbar.SafeZone)

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
        self.Buffs:SetHeight(1) -- Needs a size to display

        self.Buffs['growth-y'] = 'UP'
        self.Buffs['spacing'] = 3
        self.Buffs['size'] = 25

        if unit == 'player' then
            self.Buffs:SetWidth(FRAME_WIDTH * 0.63)
            self.Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 8)
            self.Buffs['initialAnchor'] = 'BOTTOMLEFT'
            self.Buffs['growth-x'] = 'RIGHT'

        elseif unit == 'target' then
            self.Buffs:SetWidth(FRAME_WIDTH * 0.26)
            self.Buffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 8)
            self.Buffs['initialAnchor'] = 'BOTTOMRIGHT'
            self.Buffs['growth-x'] = 'LEFT'

        elseif unit == 'pet' then
            self.Buffs:SetWidth(FRAME_WIDTH)
            self.Buffs:SetPoint('TOP', self, 'BOTTOM', 0, -8)
            self.Buffs['initialAnchor'] = 'TOPLEFT'
            self.Buffs['growth-x'] = 'RIGHT'
            self.Buffs['growth-y'] = 'DOWN'
        end

        local size = (self.Buffs['size'] + self.Buffs['spacing'])
        self.Buffs['num'] = floor(self.Buffs:GetWidth() / size + .5) * 5


        self.Buffs.PostCreateIcon = PostCreateAuraIcon
        self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

        self.Buffs.CustomFilter   = ns.CustomAuraFilters[unit]
                                 or ns.CustomAuraFilters.default
    end

    if unit == 'player' or unit == 'target' then

        self.Debuffs = CreateFrame('Frame', '$parentDebuffs', self)
        self.Debuffs:SetHeight(1) -- Needs a size to display

        self.Debuffs['growth-y'] = 'UP'
        self.Debuffs['spacing'] = 3
        self.Debuffs['size'] = 37

        if unit == 'player' then
            self.Debuffs:SetWidth(FRAME_WIDTH * 0.36) -- 1/3rds
            self.Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 8)
            self.Debuffs['initialAnchor'] = 'BOTTOMRIGHT'
            self.Debuffs['growth-x'] = 'LEFT'
        elseif unit == 'target' then
            self.Debuffs:SetWidth(FRAME_WIDTH * 0.73) -- 2/3rds
            self.Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 8)
            self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
            self.Debuffs['growth-x'] = 'RIGHT'
        end

        local size = (self.Debuffs['size'] + self.Debuffs['spacing'])
        self.Debuffs['num'] = floor(self.Debuffs:GetWidth() / size + .5) * 4

        self.Debuffs.PostCreateIcon = PostCreateAuraIcon
        self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon

        self.Debuffs.CustomFilter   = ns.CustomAuraFilters[unit]
                                   or ns.CustomAuraFilters.default
    end

    ----------------------------------------------------------------------------
    -- Heal Prediction
    ----------------------------------------------------------------------------
    local mhpb = CreateStatusBar(self.Health, 'HealPredictionMyHeals', true)
    mhpb:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT')
    mhpb:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT')
    mhpb:SetWidth(self:GetWidth())
    mhpb:SetStatusBarColor(0.25, 0.8, 1, 0.5)

    local ohpb = CreateStatusBar(self.Health, 'HealPredictionOtherHeals', true)
    ohpb:SetPoint('TOPLEFT', mhpb:GetStatusBarTexture(), 'TOPRIGHT')
    ohpb:SetPoint('BOTTOMLEFT', mhpb:GetStatusBarTexture(), 'BOTTOMRIGHT')
    ohpb:SetWidth(self:GetWidth())
    ohpb:SetStatusBarColor(0.25, 1, 0.25, 0.5)

    self.HealPrediction = {
        myBar = mhpb,    -- status bar to show my incoming heals
        otherBar = ohpb, -- status bar to show other peoples incoming heals
        maxOverflow = 1, -- amount of overflow past the end of the health bar
        -- TODO: absorbs?
    }

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

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    self.NameTag = CreateFontString(self.Overlay, 12)
    self.NameTag:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    self.NameTag:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    self:Tag(self.NameTag, '[Level< ][Name]')

    self.StatusTextTag = CreateFontString(self.Overlay, 16)
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
    self.NameTag = CreateFontString(self.Overlay, 10, 'center')
    self.NameTag:SetPoint('TOPLEFT', 3, -3)
    self.NameTag:SetPoint('TOPRIGHT', -3, -3)
    self:Tag(self.NameTag, '[Name]')

    self.StatusTextTag = CreateFontString(self.Overlay, 12, 'center')
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
