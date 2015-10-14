--// Get the addon namespace
local addon, ns = ...

local config = ns.config
local colors = oUF.colors

local _, playerClass = UnitClass("player")
local playerUnits = { player = true, pet = true, vehicle = true }

--//----------------------------
--// FUNCTIONS
--//----------------------------

local function UpdateUnitBorderColor(self)
    if not self.Border or not self.unit then return end

    local c = UnitClassification(self.unit)
    if c == 'worldboss' then c = 'boss' end
    if c == 'rareelite' then c = 'rare' end
    local t = config.border.colors[c]

    if not t then
        t = config.border.colors.normal
    end

    self.Border:SetColor(unpack(t))
end


--// Mouseover and Target Highlighting
local function HighlightShouldShow(self)

    --// Frame is curently mouse focused
    if ns.Mouse_Focus == self then
        return true
    end

    --// Frame is not the current target
    if not UnitIsUnit(self.unit, 'target') then
        return false
    end

    --// We dont want to show target highlighting for these frames
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


--// Health and Power, mostly for setting color
local function PostUpdateHealth(Health, unit, min, max)
    local r,g,b,t

    --// Determin the color we want to use
    if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
        t = colors.tapped
    elseif not UnitIsConnected(unit) then
        t = colors.disconnected
    else
        t = colors.health
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if b then
        --// Set the health bar color
        Health:SetStatusBarColor(r, g, b)

        --// Set the background color
        Health.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)
    end
end

local function PostUpdatePower(Power, unit, min, max)
    local r,g,b,t

    --// Determin the color we want to use
    if UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        t = colors.class[class]
    else
        local power = select(2, UnitPowerType(unit))
        t = colors.power[power]
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if b then
        --// Set the power bar color
        Power:SetStatusBarColor(r, g, b)

        --// Set the background color
        Power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)
    end
end


--// Castbar Functions
local function PostCastStart(Castbar, unit, name, castid)
    Castbar:SetAlpha(1.0)
    Castbar.Spark:Show()

    local r,g,b = unpack(colors.cast.normal)

    --// Set the Castbar color
    Castbar:SetStatusBarColor(r,g,b)

    --// Set the background color
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
    Castbar:SetValue(Castbar.max)
    Castbar:Show()

    local r,g,b = unpack(colors.cast.failed)

    --// Set the Castbar color
    Castbar:SetStatusBarColor(r,g,b)

    --// Set the background color
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


--// Aura Function
local function PostCreateAuraIcon(iconframe, button)
    button.cd:SetReverse(true)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count:ClearAllPoints()
    button.count:SetPoint('CENTER', button, 'BOTTOMRIGHT', -1, 0)

    ns.CreateBorder(button)
end

local function PostUpdateAuraIcon(iconframe, unit, button, index, offset)
    local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, button.filter)

    if playerUnits[caster] then
        button.icon:SetDesaturated(false)
    else
        button.icon:SetDesaturated(true)
    end

    if unit == 'player' or button.debuff then
        button:SetScript('OnMouseUp', function(self, mouseButton)
            if mouseButton ~= 'RightButton'
            or InCombatLockdown()
            then return end

            CancelUnitBuff(unit, index)
        end)
    end
end


--// Other Functions
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

local function BarOnHide(bar)
    local parent = bar:GetParent()
    parent:SetHeight(parent:GetHeight() - bar:GetHeight() - 1)
end

local function BarOnShow(bar)
    local parent = bar:GetParent()
    parent:SetHeight(parent:GetHeight() + bar:GetHeight() + 1)
end

local function CreateText(parent, size, justify)
    local fs = parent:CreateFontString(nil, 'OVERLAY')
    fs:SetFont(config.font, size or 16)
    fs:SetJustifyH(justify or 'LEFT')
    fs:SetWordWrap(false)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0,0,0,1)

    return fs
end

local function CreateStatusBar(parent, name)
    local sb = CreateFrame("StatusBar", (name and '$parent'..name or nil), parent)
    sb:SetStatusBarTexture(config.statusbar)

    sb.bg = sb:CreateTexture(nil, "BACKGROUND")
    sb.bg:SetTexture(config.statusbar)
    sb.bg:SetAllPoints(true)

    return sb
end

--//----------------------------
--// STYLE FUNCTION
--//----------------------------
--// Things every style will have
local function SharedStyle(self)

    --// Make the frame interactiveable
    self:RegisterForClicks('AnyUp')
    self:SetScript('OnEnter', OnEnter)
    self:SetScript('OnLeave', OnLeave)

    --// Background
    local Background = self:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(self)
    Background:SetTexture(0, 0, 0, 1)

    --// Border: changes color depending on the unit's classification (rare,elite)
    ns.CreateBorder(self)
    self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
    table.insert(self.__elements, UpdateUnitBorderColor)

    --// Highlight: create the highlight
    self.Highlight = CreateFrame('Frame', '$parentHighlight', self)
    self.Highlight:SetAllPoints(self)
    self.Highlight:SetFrameLevel(15) -- needs to be the very top
    self.Highlight:Hide()

    self.Highlight.texture = self.Highlight:CreateTexture(nil, 'OVERLAY')
    self.Highlight.texture:SetAllPoints(self.Highlight)
    self.Highlight.texture:SetTexture(config.highlight.texture)
    self.Highlight.texture:SetBlendMode('ADD')
    self.Highlight.texture:SetVertexColor(unpack(config.highlight.color))
    self.Highlight.texture:SetAlpha(config.highlight.alpha)

    --// Highlight: enable Updates
    self:HookScript('OnEnter', HighlightUpdate)
    self:HookScript('OnLeave', HighlightUpdate)
    self:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate)
    table.insert(self.__elements, HighlightUpdate)

    --// Overlay Frame -- used to attach icons/text to
    self.Overlay = CreateFrame('Frame', '$parentOverlay', self)
    self.Overlay:SetAllPoints(self)
    self.Overlay:SetFrameLevel(10)

    --// Spell Range
    local ranger = "Range"
    if IsAddOnLoaded("oUF_SpellRange") then
        ranger = "SpellRange"
    end

    self[ranger] = {
        insideAlpha = 1,
        outsideAlpha = 0.5
    }

end

--// Main Core style
oUF:RegisterStyle('Zoey', function(self, unit)
    SharedStyle(self)

    -- // Frame Width. Height will be set after bars are created
    if unit == 'player' or unit == 'target' then
        self:SetWidth(222)
    else
        self:SetWidth(135)
    end

    --// Used for bar positioning
    local FRAME_HEIGHT  = 1

    --//----------------------------
    --// Portrait
    --//----------------------------
    if unit == 'party' then
        self.Portrait = CreateFrame('PlayerModel', '$parentPortrait', self)
        self.Portrait:SetHeight(38)
        self.Portrait:SetPoint('TOP', 0, -FRAME_HEIGHT)
        self.Portrait:SetPoint('LEFT', 1,0)
        self.Portrait:SetPoint('RIGHT',-2,0)

        --// Darken up the Portrait just a bit
        self.Portrait.Overlay = self.Portrait:CreateTexture(nil, 'OVERLAY')
        self.Portrait.Overlay:SetTexture(0,0,0,0.4)
        self.Portrait.Overlay:SetPoint("TOPLEFT", 0,0)
        self.Portrait.Overlay:SetPoint("BOTTOMRIGHT", 1, -1)

        --// Up The Offset Value
        FRAME_HEIGHT = FRAME_HEIGHT + self.Portrait:GetHeight() + 2
    end

    --//----------------------------
    --// Health Bar
    --//----------------------------
    self.Health = CreateStatusBar(self, 'HealthBar')
    self.Health:SetHeight(27)
    self.Health:SetPoint('TOP', 0, -FRAME_HEIGHT)
    self.Health:SetPoint('LEFT', 1,0)
    self.Health:SetPoint('RIGHT',-1,0)
    self.Health.PostUpdate = PostUpdateHealth

    --// Up The FRAME_HEIGHT
    FRAME_HEIGHT = FRAME_HEIGHT + self.Health:GetHeight() + 1

    --//----------------------------
    --// Power Bar
    --//----------------------------
    self.Power = CreateStatusBar(self,'PowerBar')
    self.Power:SetHeight(10)
    self.Power:SetPoint('TOP', 0, -FRAME_HEIGHT)
    self.Power:SetPoint('LEFT', 1,0)
    self.Power:SetPoint('RIGHT',-1,0)
    self.Power.PostUpdate = PostUpdatePower

    --// Up The FRAME_HEIGHT
    FRAME_HEIGHT = FRAME_HEIGHT + self.Power:GetHeight() + 1

    --//----------------------------
    --// Class Bars
    --//----------------------------
    if unit == 'player' then

        --//----------------------------
        --// Death Knight Runes
        --//----------------------------
        if playerClass == 'DEATHKNIGHT' then

            self.Runes = CreateFrame('Frame', '$parentRunebar', self)
            self.Runes:SetHeight(5)
            self.Runes:SetPoint('TOP', 0, -FRAME_HEIGHT)
            self.Runes:SetPoint('LEFT', 1,0)
            self.Runes:SetPoint('RIGHT', -1,0)

            local width = ((self:GetWidth() - 2) / 6) - ((6 - 1) / 6)

            for i = 1, 6 do
                local rune = CreateStatusBar(self.Runes, 'Rune'..i)
                rune:SetSize(width, self.Runes:GetHeight())
                rune.bg.multiplier = 0.4

                if i == 1 then
                    rune:SetPoint('LEFT')
                else
                    rune:SetPoint('LEFT', self.Runes[i-1], 'RIGHT', 1, 0)
                end

                self.Runes[i] = rune
            end

            --// Up The FRAME_HEIGHT
            FRAME_HEIGHT = FRAME_HEIGHT + self.Runes:GetHeight() + 1

        end

        --//----------------------------
        --// Druid Eclipse
        --//----------------------------
        if playerClass == 'DRUID' then



        end

        --//----------------------------
        --// Paladin Holy Power
        --//----------------------------
        if playerClass == 'PALADIN' then

            self.ClassIcons = CreateFrame('Frame', '$parentHolyPowerBar', self)
            self.ClassIcons:SetHeight(5)
            self.ClassIcons:SetPoint('TOP', 0, -FRAME_HEIGHT)
            self.ClassIcons:SetPoint('LEFT', 1,0)
            self.ClassIcons:SetPoint('RIGHT', -1,0)

            local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

            for i = 1, 3 do
                local power = self.ClassIcons:CreateTexture(nil, 'ARTWORK')
                power:SetTexture(config.statusbar)
                power:SetSize(width, self.ClassIcons:GetHeight())

                if i == 1 then
                    power:SetPoint('LEFT', self.ClassIcons, 0, 0)
                else
                    power:SetPoint('LEFT', self.ClassIcons[i-1], 'RIGHT', 1, 0)
                end

                power.bg = self.ClassIcons:CreateTexture(nil, 'BACKGROUND')
                power.bg:SetTexture(config.statusbar)
                power.bg:SetAllPoints(power)

                -- // Color
                local r,g,b = unpack(colors.power.HOLY_POWER)

                power:SetVertexColor(r,g,b)
                power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

                self.ClassIcons[i] = power
            end

            --// There is no 4th and 5th holy power, but ClassIcon requires it.
            for i= 4, 5 do
                self.ClassIcons[i] = self.ClassIcons:CreateTexture(nil, 'ARTWORK')
            end


            --// Up The FRAME_HEIGHT
            FRAME_HEIGHT = FRAME_HEIGHT + self.ClassIcons:GetHeight() + 1

        end

        --//----------------------------
        --// Shaman Totems
        --//----------------------------
        if playerClass == 'SHAMAN' then



        end

        --//----------------------------
        --// Warlock Soul Shards
        --//----------------------------
        if playerClass == 'WARLOCK' then

            self.ClassIcons = CreateFrame('Frame', '$parentClassIconsBar', self)
            self.ClassIcons:SetHeight(5)
            self.ClassIcons:SetPoint('TOP', 0, -FRAME_HEIGHT)
            self.ClassIcons:SetPoint('LEFT', 1,0)
            self.ClassIcons:SetPoint('RIGHT', -1,0)

            local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

            for i = 1, 3 do
                local shard = self.ClassIcons:CreateTexture(nil, 'ARTWORK')
                shard:SetTexture(config.statusbar)
                shard:SetSize(width, self.ClassIcons:GetHeight())

                if i == 1 then
                    shard:SetPoint('LEFT', self.ClassIcons, 0, 0)
                else
                    shard:SetPoint('LEFT', self.ClassIcons[i-1], 'RIGHT', 1, 0)
                end

                shard.bg = self.ClassIcons:CreateTexture(nil, 'BACKGROUND')
                shard.bg:SetTexture(config.statusbar)
                shard.bg:SetAllPoints(shard)

                -- // Color
                local r,g,b = unpack(colors.power.SOUL_SHARDS)

                shard:SetVertexColor(r,g,b)
                shard.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

                self.ClassIcons[i] = shard
            end

            --// There is no 4th and 5th soul shards, but ClassIcon requires it.
            for i= 4, 5 do
                self.ClassIcons[i] = self.ClassIcons:CreateTexture(nil, 'ARTWORK')
            end

            --// Up The FRAME_HEIGHT
            FRAME_HEIGHT = FRAME_HEIGHT + self.ClassIcons:GetHeight() + 1

        end

    elseif unit == 'target' then

        --//----------------------------
        --// Combo Points
        --//----------------------------
        if playerClass == 'ROGUE' or playerClass == 'DRUID' then

            --// Combo points float above the healthbar
            --// so they can be hidden if the druid isnt in cat form

            self.CPoints = CreateFrame('Frame', '$parentCPointsFrame', self)
            self.CPoints:SetHeight(5)
            self.CPoints:SetPoint('BOTTOMLEFT', self.Health, 'TOPLEFT', 0, 1)
            self.CPoints:SetPoint('BOTTOMRIGHT', self.Health, 'TOPRIGHT', 0, 1)

            self.CPoints:SetFrameLevel(3) --// Push it above the portrait

            --// Background
            local Background = self.CPoints:CreateTexture(nil, 'BACKGROUND')
            Background:SetPoint('TOPLEFT', -1, 1)
            Background:SetPoint('BOTTOMRIGHT', 1, -1)
            Background:SetTexture(0, 0, 0, 1)

            local width = ((self:GetWidth() - 2) / 5) - ((5 - 1) / 5)

            for i = 1, 5 do
                local point = self.CPoints:CreateTexture(nil, 'ARTWORK')
                point:SetTexture(config.statusbar)
                point:SetSize(width, self.CPoints:GetHeight())

                if i == 1 then
                    point:SetPoint('LEFT', self.CPoints, 0, 0)
                else
                    point:SetPoint('LEFT', self.CPoints[i-1], 'RIGHT', 1, 0)
                end

                point.bg = self.CPoints:CreateTexture(nil, 'BACKGROUND')
                point.bg:SetTexture(config.statusbar)
                point.bg:SetAllPoints(point)

                -- // Color
                local r,g,b = unpack(colors.comboPoints.normal)

                point:SetVertexColor(r,g,b)
                point.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

                self.CPoints[i] = point
            end

            --// Last combo point should be red, but not the bg
            self.CPoints[5]:SetVertexColor(unpack(colors.comboPoints.last))

            --// Toggle the frame when the Druid enters/leaves Cat Form
            if playerClass == 'DRUID' then
                local f = CreateFrame('Frame', nil, self)
                f:RegisterEvent('PLAYER_LOGIN')
                f:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
                f:SetScript('OnEvent', function()
                    if GetShapeshiftFormID() == CAT_FORM then
                        self.CPoints:Show()
                    else
                        self.CPoints:Hide()
                    end
                end)
            end
        end
    end

    --//----------------------------
    --// Experience Bar
    --//----------------------------
    if unit == 'player' and IsAddOnLoaded('oUF_Experience') and UnitLevel(unit) ~= MAX_PLAYER_LEVEL then
        self.Experience = CreateFrame('Statusbar', '$parentExperience', self)
        self.Experience:SetStatusBarTexture(config.statusbar)
        self.Experience:SetHeight(5)
        self.Experience:SetPoint('TOP', 0, -FRAME_HEIGHT)
        self.Experience:SetPoint('LEFT', 1,0)
        self.Experience:SetPoint('RIGHT',-1,0)

        self.Experience.Rested = CreateFrame('StatusBar', '$parentRested', self.Experience)
        self.Experience.Rested:SetStatusBarTexture(config.statusbar)
        self.Experience.Rested:SetAllPoints(self.Experience)

        self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BACKGROUND')
        self.Experience.bg:SetAllPoints(self.Experience)
        self.Experience.bg:SetTexture(config.statusbar)

        --// Resize the main frame when this frame Hides or Shows
        self.Experience:SetScript('OnShow', BarOnShow)
        self.Experience:SetScript('OnHide', BarOnHide)

        --// Main Color
        local r,g,b = unpack(colors.experience.main)

        self.Experience:SetStatusBarColor(r,g,b)
        self.Experience.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

        --// Rested Color
        self.Experience.Rested:SetStatusBarColor(unpack(colors.experience.rested))

        --// Up The FRAME_HEIGHT
        FRAME_HEIGHT = FRAME_HEIGHT + self.Experience:GetHeight() + 1
    end


    --// Finaly time to set the Frame Height
    self:SetHeight(FRAME_HEIGHT)

    --//----------------------------
    --// Texts
    --//----------------------------
    --// Name Text
    local Name = CreateText(self.Overlay, 16)
    Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    Name:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    self:Tag(Name, '[Zoey:Level< ][Zoey:Name]')

    --// Health Text
    if unit == 'target' then
        --// Target uses two health texts to make the
        --// final 20% big and red for Execute and Kill Shot
        local HealthText = CreateText(self.Overlay, 22)
        HealthText:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(HealthText, '[Zoey:TargetHealth]')

        local HealthText2 = CreateText(self.Overlay, 29)
        HealthText2:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(HealthText2, '[Zoey:TargetHealth2]')
    else
        local HealthText = CreateText(self.Overlay, 22)
        HealthText:SetPoint('RIGHT', self.Health, -1, -1)
        self:Tag(HealthText, '[Zoey:Health]')
    end

    --// Power Text
    local PowerText = CreateText(self.Overlay, 12)
    PowerText:SetPoint('RIGHT', self.Power, -1, -1)
    self:Tag(PowerText, '[Zoey:Power]')

    --// Experience Text
    if self.Experience then
        local Experience = CreateText(self.Overlay, 10)
        Experience:SetPoint('CENTER', self.Experience, 'BOTTOM', 0, -5)
        self:Tag(Experience, '[Zoey:Exp]')
    end

    --//----------------------------
    --// Icons
    --//----------------------------
    if unit == 'player' then
        --// Resting Icon
        self.Resting = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.Resting:SetSize(25,25)
        self.Resting:SetPoint('LEFT', self.Overlay, 'BOTTOMLEFT', 0, -2)

        --// Combat Icon
        self.Combat = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.Combat:SetSize(25,25)
        self.Combat:SetPoint('RIGHT', self.Overlay, 'BOTTOMRIGHT', 0, -2)
    end

    if unit == 'target' then
        --// Quest Mob Icon
        self.QuestIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.QuestIcon:SetSize(32,32)
        self.QuestIcon:SetPoint('CENTER', self.Overlay, 'LEFT', 0, 0)
    end

    --// Leader Icon
    self.Leader = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.Leader:SetSize(15,15)
    self.Leader:SetPoint('CENTER', self.Overlay, 'TOPLEFT', 0, 3)

    --// LFD Role Icon
    self.LFDRole = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.LFDRole:SetSize(15,15)
    self.LFDRole:SetPoint('CENTER', self.Overlay, 'TOPRIGHT', 1, 0)

    --// Ready Check icon
    self.ReadyCheck = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ReadyCheck:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ReadyCheck:SetPoint('CENTER', self.Overlay, 'CENTER', 0, 0)

    --// Raid Icon (Skull, Cross, Square ...)
    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(23,23)
    self.RaidIcon:SetPoint('LEFT', self.Overlay, 3, 0)

    --// PvP Icon -- The img used isnt perfect, it sucks
    self.PvP = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.PvP:SetSize(21,21)
    self.PvP:SetPoint('CENTER', self.Overlay, 'LEFT', 0,0)

    local faction = UnitFactionGroup(unit)
    if faction == 'Horde' then
        self.PvP:SetTexCoord(0.08, 0.58, 0.045, 0.545)
    elseif faction == 'Alliance' then
        self.PvP:SetTexCoord(0.07, 0.58, 0.06, 0.57)
    else
        self.PvP:SetTexCoord(0.05, 0.605, 0.015, 0.57)
    end

    if unit == 'party' or unit == 'target' or unit == 'focus' then
        --// Phase Icon -- is the unit in a different phase then the player
        self.PhaseIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
        self.PhaseIcon:SetPoint('TOP', self)
        self.PhaseIcon:SetPoint('BOTTOM', self)
        self.PhaseIcon:SetWidth(FRAME_HEIGHT * 2)
        self.PhaseIcon:SetTexture([[Interface\Icons\Spell_Frost_Stun]])
        self.PhaseIcon:SetTexCoord(0.05, 0.95, 0.25, 0.75)
        self.PhaseIcon:SetAlpha(0.5)
        self.PhaseIcon:SetBlendMode("ADD")
        self.PhaseIcon:SetDesaturated(true)
        self.PhaseIcon:SetVertexColor(0.4, 0.8, 1)
    end

    --//----------------------------
    --// Cast Bars
    --//----------------------------
    if unit == 'player' or unit == 'target' then

        --// The Castbar its self
        self.Castbar = CreateStatusBar(self, 'Castbar')

        if unit == 'player' then
            self.Castbar:SetSize(300,22)
            self.Castbar:SetPoint('CENTER', UIParent, 'BOTTOM', 0, 200)
        elseif unit == 'target' then
            self.Castbar:SetSize(590,38)
            self.Castbar:SetPoint('CENTER', UIParent, 'BOTTOM', 0, 425)
        end

        --// Add a spark
        self.Castbar.Spark = self.Castbar:CreateTexture(nil, 'OVERLAY')
        self.Castbar.Spark:SetHeight(self.Castbar:GetHeight()*2.5)
        self.Castbar.Spark:SetBlendMode('ADD')
        self.Castbar.Spark:SetAlpha(0.5)

        --// Player only Latency
        if unit == 'player' then
            self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'OVERLAY')
            self.Castbar.SafeZone:SetTexture(config.statusbar)
            self.Castbar.SafeZone:SetVertexColor(unpack(colors.cast.safezone))

            self.Castbar.Lag = CreateText(self.Castbar, 10)
            self.Castbar.Lag:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -7)
        end

        --// Castbar Texts
        if unit == 'player' then
            self.Castbar.Text = CreateText(self.Castbar, 14)
            self.Castbar.Time = CreateText(self.Castbar, 10)

        elseif unit == 'target' then
            self.Castbar.Text = CreateText(self.Castbar, 20)
            self.Castbar.Time = CreateText(self.Castbar, 16)
        end
        self.Castbar.Text:SetPoint('LEFT', 10, 0)
        self.Castbar.Time:SetPoint('RIGHT', -10, 0)

        --// Castbar Function Hooks
        self.Castbar.OnUpdate = CastbarOnUpdate
        self.Castbar.PostCastStart = PostCastStart
        self.Castbar.PostChannelStart = PostCastStart
        self.Castbar.PostCastStop = PostCastStop
        self.Castbar.PostChannelStop = PostChannelStop
        self.Castbar.PostCastFailed = PostCastFailed
        self.Castbar.PostCastInterrupted = PostCastFailed
        self.Castbar.PostCastInterruptible = PostCastInterruptible
        self.Castbar.PostCastNotInterruptible = PostCastNotInterruptible

        --// Build a frame around the Castbar
        self.Castbar.Frame = CreateFrame('Frame', '$parentFrame', self.Castbar)
        self.Castbar.Frame:SetPoint('TOPLEFT', -1, 1)
        self.Castbar.Frame:SetPoint('BOTTOMRIGHT', 1, -1)
        self.Castbar.Frame:SetFrameLevel(self.Castbar:GetFrameLevel()-1)

        self.Castbar.Frame.bg = self.Castbar.Frame:CreateTexture(nil, 'BACKGROUND')
        self.Castbar.Frame.bg:SetAllPoints(self.Castbar.Frame)
        self.Castbar.Frame.bg:SetTexture(0, 0, 0, 1)

        ns.CreateBorder(self.Castbar.Frame)
    end

    --//----------------------------
    --// Auras
    --//----------------------------
    if unit == 'player' or unit == 'target' then

        --// Buffs
        self.Buffs = CreateFrame('Frame', nil, self)

        self.Buffs:SetHeight(25)
        self.Buffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -6)
        self.Buffs:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -6)

        self.Buffs['growth-y'] = 'DOWN'
        self.Buffs['spacing'] = 7.5
        self.Buffs['size'] = 25
        self.Buffs['num'] = 9


        if unit == 'player' then
            self.Buffs['initialAnchor'] = 'TOPLEFT'
            self.Buffs['growth-x'] = 'RIGHT'

        elseif unit == 'target' then
            self.Buffs['initialAnchor'] = 'TOPRIGHT'
            self.Buffs['growth-x'] = 'LEFT'
        end

        self.Buffs.PostCreateIcon = PostCreateAuraIcon
        self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

        --// Debuffs
        self.Debuffs = CreateFrame('Frame', nil, self)
        self.Debuffs:SetHeight(75)
        self.Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 6)
        self.Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 6)

        self.Debuffs['growth-y'] = 'UP'
        self.Debuffs['spacing'] = 7.5
        self.Debuffs['size'] = 34

        if unit == 'player' then
            self.Debuffs['initialAnchor'] = 'BOTTOMRIGHT'
            self.Debuffs['growth-x'] = 'LEFT'
        elseif unit == 'target' then
            self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
            self.Debuffs['growth-x'] = 'RIGHT'
        end

        self.Debuffs.PostCreateIcon = PostCreateAuraIcon
        self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
    end

    --//----------------------------
    --// Heal Prediction Bar
    --//----------------------------
    local mhpb = CreateFrame('StatusBar', nil, self.Health)
    mhpb:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    mhpb:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    mhpb:SetWidth(self:GetWidth())
    mhpb:SetStatusBarTexture(config.statusbar)
    mhpb:SetStatusBarColor(0, 1, 0, 0.25) -- TODO: tweek colors

    local ohpb = CreateFrame('StatusBar', nil, self.Health)
    ohpb:SetPoint('TOPLEFT', mhpb:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
    ohpb:SetPoint('BOTTOMLEFT', mhpb:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
    ohpb:SetWidth(self:GetWidth())
    ohpb:SetStatusBarTexture(config.statusbar)
    ohpb:SetStatusBarColor(0, 1, 0, 0.25) -- TODO: tweek colors

    -- Register it with oUF
    self.HealPrediction = {
        myBar = mhpb,    -- status bar to show my incoming heals
        otherBar = ohpb, -- status bar to show other peoples incoming heals
        maxOverflow = 1, -- amount of overflow past the end of the health bar
    }

end)

oUF:RegisterStyle('ZoeyThin', function(self, unit)
    SharedStyle(self)

    -- // Frame Width. Height will be set after bars are created
    self:SetWidth(135)

    --// Used for bar positioning
    local FRAME_HEIGHT  = 1

    --//----------------------------
    --// Health Bar
    --//----------------------------
    self.Health = CreateStatusBar(self, 'HealthBar')
    self.Health:SetHeight(18)
    self.Health:SetPoint('TOP', 0, -FRAME_HEIGHT)
    self.Health:SetPoint('LEFT', 1,0)
    self.Health:SetPoint('RIGHT',-1,0)
    self.Health.PostUpdate = PostUpdateHealth

    --// Up The FRAME_HEIGHT
    FRAME_HEIGHT = FRAME_HEIGHT + self.Health:GetHeight() + 1

    --// Finaly time to set the Frame Height
    self:SetHeight(FRAME_HEIGHT)

    --//----------------------------
    --// Texts
    --//----------------------------
    --// Name Text
    local Name = CreateText(self.Overlay, 12)
    Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
    Name:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
    self:Tag(Name, '[Zoey:Level< ][Zoey:Name]')

    --// Status Text
    local StatusText = CreateText(self.Overlay, 16)
    StatusText:SetPoint('RIGHT', self.Health, -1, 0)
    self:Tag(StatusText, '[Zoey:Status]')

    --//----------------------------
    --// Icons
    --//----------------------------
    --// Leader Icon
    self.Leader = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.Leader:SetSize(13,13)
    self.Leader:SetPoint('CENTER', self.Overlay, 'TOPLEFT', 0, 0)

    --// LFD Role Icon
    self.LFDRole = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.LFDRole:SetSize(13,13)
    self.LFDRole:SetPoint('CENTER', self.Overlay, 'TOPRIGHT', 0, 0)

    --// Ready Check icon
    self.ReadyCheck = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ReadyCheck:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ReadyCheck:SetPoint('CENTER', self.Overlay, 'CENTER', 0, 0)

    --// Raid Icon (Skull, Cross, Square ...)
    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(16,16)
    self.RaidIcon:SetPoint('CENTER', self.Overlay, 'LEFT', 0, 0)

end)

oUF:RegisterStyle('ZoeySquare', function(self, unit)
    SharedStyle(self)

    -- // Frame Width. Height will be set after bars are created
    self:SetWidth(53)

    --// Used for bar positioning
    local FRAME_HEIGHT = 1

    --//----------------------------
    --// Health Bar
    --//----------------------------
    self.Health = CreateStatusBar(self, 'HealthBar')
    self.Health:SetHeight(25)
    self.Health:SetPoint('TOP', 0, -FRAME_HEIGHT)
    self.Health:SetPoint('LEFT', 1,0)
    self.Health:SetPoint('RIGHT',-1,0)
    self.Health.PostUpdate = PostUpdateHealth

    --// Up The FRAME_HEIGHT
    FRAME_HEIGHT = FRAME_HEIGHT + self.Health:GetHeight() + 1

    --//----------------------------
    --// Power Bar
    --//----------------------------
    self.Power = CreateStatusBar(self, 'PowerBar')
    self.Power:SetHeight(5)
    self.Power:SetPoint('TOP', 0, -FRAME_HEIGHT)
    self.Power:SetPoint('LEFT', 1,0)
    self.Power:SetPoint('RIGHT',-1,0)
    self.Power.PostUpdate = PostUpdatePower

    --// Up The FRAME_HEIGHT
    FRAME_HEIGHT = FRAME_HEIGHT + self.Power:GetHeight() + 1

    --// Finaly time to set the Frame Height
    self:SetHeight(FRAME_HEIGHT)

    --//----------------------------
    --// Texts
    --//----------------------------
    --// Name Text
    local Name = CreateText(self.Overlay, 10, 'center')
    Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 1, -1)
    Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -1, -1)
    self:Tag(Name, '[Zoey:Name]')

    --// Status Text
    local StatusText = CreateText(self.Overlay, 12, 'center')
    StatusText:SetPoint('BOTTOM',  self)
    self:Tag(StatusText, '[Zoey:Status]')

    --//----------------------------
    --// Icons
    --//----------------------------
    --// Leader Icon
    self.Leader = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.Leader:SetSize(10,10)
    self.Leader:SetPoint('CENTER', self.Overlay, 'TOPLEFT', 0, 0)

    --// LFD Role Icon
    self.LFDRole = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.LFDRole:SetSize(13,13)
    self.LFDRole:SetPoint('CENTER', self.Overlay, 'TOPRIGHT', 0, 0)

    --// Ready Check icon
    self.ReadyCheck = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.ReadyCheck:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    self.ReadyCheck:SetPoint('CENTER', self.Overlay, 'CENTER', 0, 0)

    --// Raid Icon (Skull, Cross, Square ...)
    self.RaidIcon = self.Overlay:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetSize(16,16)
    self.RaidIcon:SetPoint('CENTER', self.Overlay, 'LEFT', 0, 0)

end)

--//----------------------------
--// SPAWN UNITS
--//----------------------------
local u = {}
local Spawn = function(unit)
    local object = oUF:Spawn(unit)
    u[unit:lower()] = object
    return object
end

oUF:Factory(function(self)

    local bgap,sgap = 200, 12

    --//----------------------------
    --// Player
    Spawn('Player'):SetPoint('RIGHT', UIParent, 'BOTTOM', -(bgap/2), 300)

    --// Player Pet
    Spawn('Pet'      ):SetPoint('RIGHT', u.player, 'LEFT', -sgap, 0)
    Spawn('PetTarget'):SetPoint('BOTTOM', u.pet, 'TOP', 0, sgap)

    --// Targets
    Spawn('Target'      ):SetPoint('LEFT', u.player, 'RIGHT', bgap, 0)
    Spawn('TargetTarget'):SetPoint('LEFT', u.target, 'RIGHT', sgap, 0)

    --// Focus
    self:SetActiveStyle('ZoeyThin')
    Spawn('Focus'      ):SetPoint('RIGHT', u.pet, 'LEFT', -sgap, 0)
    Spawn('FocusTarget'):SetPoint('BOTTOM', u.focus, 'TOP', 0, sgap)

    --//----------------------------
    --// Party
    self:SetActiveStyle('Zoey')
    self:SpawnHeader('oUF_ZoeyParty', nil, 'party',
        'showParty', true,
        'yOffset', 50,
        'oUF-initialConfigFunction', [[
            self:SetWidth( 135 )
            self:SetHeight( 80 )
        ]],

        'point', 'BOTTOM'
    ):SetPoint('BOTTOMLEFT', UIParent, 'LEFT', sgap, -200)

    --// Party Targets
    self:SpawnHeader('oUF_ZoeyPartyTargets', nil, 'party',
        'showParty', true,
        'yOffset', 90,
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'target')
            self:SetWidth( 135 )
            self:SetHeight( 40 )
        ]],

        'point', 'BOTTOM'
    ):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 'BOTTOMRIGHT', sgap, 0)

    --// Party Pets
    self:SetActiveStyle('ZoeyThin')
    self:SpawnHeader('oUF_ZoeyPartyPets', nil, 'party',
        'showParty', true,
        'yOffset', 110,
        'oUF-initialConfigFunction', [[
            self:SetAttribute('unitsuffix', 'pet')
            self:SetWidth( 135 )
            self:SetHeight( 20 )
        ]],

        'point', 'BOTTOM'
    ):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 0, -28)

    --//----------------------------
    --// Raid Size 1 - 10
    self:SetActiveStyle('Zoey')
    local Raid = {}
    for i = 1, 2 do
        local group = self:SpawnHeader('oUF_ZoeyRaid10_g'..i, nil,
            'custom [@raid11,exists] hide; [@raid1,exists] show; hide',

            'showRaid', true,
            'yOffset', 10.2,
            'groupFilter', tostring(i),

            'oUF-initialConfigFunction', [[
                self:SetWidth( 138 )
                self:SetHeight( 39 )
            ]],

            'point', 'BOTTOM'
        )

        if i == 1 then
            group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -200)
        else
            group:SetPoint('BOTTOMLEFT', Raid[i - 1], 'BOTTOMRIGHT', 16, 0)
        end

        Raid[i] = group
    end

    --// Raid Size 11 - 25
    self:SetActiveStyle('ZoeyThin')
    local Raid = {}
    for i = 1, 5 do
        local group = self:SpawnHeader('oUF_ZoeyRaid25_g'..i, nil,
            'custom [@raid26,exists] hide; [@raid11,exists] show; hide ',

            'showRaid', true,
            'yOffset', 7.1,
            'groupFilter', tostring(i),
            'sortDir', 'DESC',

            'oUF-initialConfigFunction', [[
                self:SetWidth( 138 )
                self:SetHeight( 19 )
            ]],

            'point', 'BOTTOM'
        )

        if i == 1 then
            group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -200)
        else
            group:SetPoint('BOTTOM', Raid[i - 1], 'TOP', 0, 15)
        end

        Raid[i] = group
    end

    --// Raid Size 26 - 40
    self:SetActiveStyle('ZoeySquare')
    local Raid = {}
    for i = 1, 8 do
        local group = self:SpawnHeader('oUF_ZoeyRaid40_g'..i, nil,
            'custom [@raid26,exists] show; hide',

            'showRaid', true,
            'xOffset', 10,
            'groupFilter', tostring(i),

            'oUF-initialConfigFunction', [[
                self:SetWidth( 53 )
                self:SetHeight( 33 )
            ]],

            'point', 'LEFT'
        )

        if i == 1 then
            group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -200)
        else
            group:SetPoint('BOTTOMLEFT', Raid[i - 1], 'TOPLEFT', 0, 10)
        end

        Raid[i] = group
    end

end)

--//----------------------------
--// Extra Stuff for the UI
--//----------------------------
oUF:Factory(function(self)

    --// Hide the Blizzard Buffs
    BuffFrame:Hide()
    BuffFrame:UnregisterAllEvents()
    TemporaryEnchantFrame:Hide()
    ConsolidatedBuffs:Hide()

    --// Hide the Compact Raid Frame Manager and Container
    CompactRaidFrameManager:UnregisterAllEvents()
    CompactRaidFrameManager.Show = CompactRaidFrameManager.Hide
    CompactRaidFrameManager:Hide()

    CompactRaidFrameContainer:UnregisterAllEvents()
    CompactRaidFrameContainer.Show = CompactRaidFrameContainer.Hide
    CompactRaidFrameContainer:Hide()

    --// Skin the Mirror Timers
    for i = 1, 3 do
        local barname = 'MirrorTimer' .. i
        local bar = _G[ barname ]

        for i, region in pairs( { bar:GetRegions() } ) do
            if region.GetTexture and region:GetTexture() == 'SolidTexture' then
                region:Hide()
            end
        end

        ns.CreateBorder(bar)

        bar:SetParent( UIParent )
        bar:SetSize(285, 28)

        if i > 1 then
            local p1, p2, p3, p4, p5 = bar:GetPoint()
            bar:SetPoint(p1, p2, p3, p4, p5 - 15)
        end

        bar.bg = bar:GetRegions()
        bar.bg:ClearAllPoints()
        bar.bg:SetAllPoints( bar )
        bar.bg:SetTexture( config.statusbar )
        bar.bg:SetVertexColor( 0.2, 0.2, 0.2, 1 )

        bar.text = _G[ barname .. 'Text' ]
        bar.text:ClearAllPoints()
        bar.text:SetPoint( 'LEFT', bar, 4, 1 )
        bar.text:SetFont( config.font, 16)

        bar.border = _G[ barname .. 'Border' ]
        bar.border:Hide()

        bar.bar = _G[ barname .. 'StatusBar' ]
        bar.bar:SetPoint('TOPLEFT', bar, 1, -1)
        bar.bar:SetPoint('BOTTOMRIGHT', bar, -1, 1)
        bar.bar:SetStatusBarTexture( config.statusbar )
        bar.bar:SetAlpha( 0.8 )
    end

    --// Disable Blizzard options that are rendered useless by having this unit frame addon
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

    --// Remove Items from the Rightclick Menu
    for _, menu in pairs( UnitPopupMenus ) do
        for i = #menu, 1, -1 do
            local name = menu[ i ]
            if name:match( '^LOCK_%u+_FRAME$' )
            or name:match( '^UNLOCK_%u+_FRAME$' )
            or name:match( '^MOVE_%u+_FRAME$' )
            or name:match( '^RESET_%u+_FRAME_POSITION' )
            then
                table.remove( menu, i )
            end
        end
    end


end)

--//----------------------------
--// THE END
