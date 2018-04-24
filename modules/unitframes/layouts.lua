local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local _, playerClass = UnitClass('player')

--------------------------------------------------------------------------------
Module.mousefocus = nil
local function OnEnter(self)
    UnitFrame_OnEnter(self)

    Module.mousefocus = self
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end

local function OnLeave(self)
    UnitFrame_OnLeave(self)

    Module.mousefocus = nil
    for _, fs in ipairs( self.__tags ) do
        fs:UpdateTag()
    end
end


local function CreateFontString(parent, size, justify)
    local fs = parent:CreateFontString(nil, 'ARTWORK')
    fs:SetFont(Addon.Media:Fetch('font', Addon.db.profile.general.font), size or 16)
    fs:SetJustifyH(justify or 'LEFT')
    fs:SetWordWrap(false)
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0,0,0,1)

    return fs
end

local function CreateStatusBar(parent, noBG)
    local sb = CreateFrame('StatusBar', nil, parent)
    sb:SetStatusBarTexture(Addon.Media:Fetch('statusbar', Addon.db.profile.general.texture))

    if not noBG then
        sb.bg = sb:CreateTexture(nil, 'BACKGROUND')
        sb.bg:SetTexture(Addon.Media:Fetch('statusbar', Addon.db.profile.general.texture))
        sb.bg:SetAllPoints(true)
        sb.bg.multiplier = 0.4
    end

    return sb
end



local function UpdateUnitBorderColor(object)
    if not object.Border or not object.unit then return end

    local c = UnitClassification(object.unit)
    if c == 'worldboss' then c = 'boss' end
    local t = object.colors.classification[c] or object.colors.border

    object.Border:SetColor(unpack(t))
end

local function HighlightUpdate(object)
    local show

    -- Frame is curently mouse focused
    if Module.mousefocus == object then
       show = true
    end

    -- Dont show highlighting on player or target frames
    if object.unit ~= 'player' and strsub(object.unit, 1, 6) ~= 'target' then
       -- Frame is not the current target
       if UnitIsUnit(object.unit, 'target') then
          show = true
       end
    end

    if show then
        object.Highlight:Show()
    else
        object.Highlight:Hide()
    end
end

--------------------------------------------------------------------------------
local function HealthUpdateColor(Health, unit, cur, max)
    local db = Module.db.profile.colors
    local parent = Health.__owner
    local r, g, b, t

    if not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        t = parent.colors.tapped
    elseif Health.disconnected then
        t = parent.colors.disconnected
    elseif db.health_class and UnitIsPlayer(unit) and not db.health_force_reaction then
        local _, class = UnitClass(unit)
        t = parent.colors.class[class]
    elseif db.health_class and UnitReaction(unit, 'player') then
        t = parent.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.health_by_value then
        r, g, b = parent.ColorGradient(cur, max, unpack(parent.colors.smooth))
    else
        t = parent.colors.health
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        Health:SetStatusBarColor(r, g, b)

        local bg = Health.bg
        if bg then
            local t

            if db.use_health_backdrop_dead and UnitIsDeadOrGhost(unit) then
                t = db.health_backdrop_dead
                r, g, b = t[1], t[2], t[3]
            elseif db.health_backdrop_class then
                local t
                if UnitIsPlayer(unit) then
                    local _, class = UnitClass(unit)
                    t = parent.colors.class[class]
                elseif UnitReaction(unit, 'player') then
                    t = parent.colors.reaction[UnitReaction(unit, 'player')]
                end

                if t then
                    r, g, b = t[1], t[2], t[3]
                end
            elseif db.health_backdrop_custom then
                t = db.health_backdrop
                r, g, b = t[1], t[2], t[3]
            else -- defaults to a multiplier
                local mult = 0.4
                r, g, b = r * mult, g * mult, b * mult
            end

            bg:SetVertexColor(r, g, b)
        end
    end
end

local function PowerUpdateColor(Power, unit, cur, min, max, displayType)
    local db = Module.db.profile.colors
    local parent = Power.__owner
    local r, g, b, t

    if db.power_class and UnitIsPlayer(unit) then
        local class = select(2, UnitClass(unit))
        t = parent.colors.class[class]
    elseif db.power_class and UnitReaction(unit, 'player') then
        t = parent.colors.reaction[UnitReaction(unit, 'player')]
    elseif db.power_custom then
        t = parent.colors.power.custom
    else
        local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

        t = parent.colors.power[ptoken]
        if not t then
            if altR then
                r, g, b = altR, altG, altB

                if r > 1 or g > 1 or b > 1 then
                    -- BUG: As of 7.0.3, altR, altG, altB may be in 0-1 or 0-255 range.
                    r, g, b = r / 255, g / 255, b / 255
                end
            else
                t = parent.colors.power[ptype]
            end
        end
    end

    if t then
        r, g, b = t[1], t[2], t[3]
    end

    if r or g or b then
        Power:SetStatusBarColor(r, g, b)

        local bg = Power.bg
        if bg then
            local mult = 0.4
            bg:SetVertexColor(r * mult, g * mult, b * mult)
        end
    end
end

--------------------------------------------------------------------------------
-- Castbar Functions
local function PostCastStart(Castbar, unit, name, castID, spellID)
    local parent = Castbar.__owner
    local r,g,b = unpack(parent.colors.cast.normal)

    if not Castbar.Frame then
        r,g,b = 1,1,1
    end

    Castbar:SetAlpha(1.0)
    Castbar.Spark:Show()

    Castbar:SetStatusBarColor(r,g,b)

    if Castbar.bg then
        local mu = Castbar.bg.multiplier
        Castbar.bg:SetVertexColor(r*mu, g*mu, b*mu)
    end

    if Castbar.notInterruptible then
        Castbar:PostCastNotInterruptible(unit)
    else
        Castbar:PostCastInterruptible(unit)
    end
end

local function PostCastStop(Castbar, unit, spellname, castID, spellID)
    Castbar:SetValue(Castbar.max)
    Castbar:Show()
end

local function PostChannelStop(Castbar, unit, spellname, spellID)
    Castbar:SetValue(0)
    Castbar:Show()
end

local function PostCastFailed(Castbar, unit, spellname, castID, spellID)
    local parent = Castbar.__owner
    local r,g,b = unpack(parent.colors.cast.failed)

    Castbar:SetValue(Castbar.max)
    Castbar:Show()

    Castbar:SetStatusBarColor(r,g,b)

    if Castbar.bg then
        local mu = Castbar.bg.multiplier
        Castbar.bg:SetVertexColor(r*mu, g*mu, b*mu)
    end
end

local function PostCastInterruptible(Castbar, unit)
    local parent = Castbar.__owner
    if unit == 'target' then
        Castbar.Frame.Border:SetColor(unpack(parent.colors.border))
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

--------------------------------------------------------------------------------
-- Aura Function
local function PostCreateAuraIcon(Auras, button)
    button.cd:SetReverse(true)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count:ClearAllPoints()
    button.count:SetPoint('CENTER', button, 'BOTTOMRIGHT', -1, 0)

    -- parent count fontstring to a frame
    -- so we can push it above the Cooldown Frame
    local countFrame = CreateFrame('Frame', nil, button)
    countFrame:SetFrameLevel(button.cd:GetFrameLevel() +1)
    button.count:SetParent(countFrame)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetPoint('TOPLEFT', -1, 1)
    button.bg:SetPoint('BOTTOMRIGHT', 1, -1)
    button.bg:SetColorTexture(0, 0, 0, 1)
end

local PostUpdateAuraIcon
do
    local playerUnits = { player = true, pet = true, vehicle = true }

    function PostUpdateAuraIcon(Auras, unit, button, index, offset)
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
end

local function PostUpdateAuras(Auras)
    -- Auras could be either Buffs or Debuffs.
    local self = Auras.__owner

    -- Sometimes these values can be nil
    local visibleBuffs =  self.Buffs.visibleBuffs or 0
    local visibleDebuffs = self.Debuffs.visibleDebuffs or 0

    -- Figure out some things
    local trueSize =  self.Buffs.size +  self.Buffs.spacing
    local buffsPerRow = floor((self:GetWidth() + self.Buffs.spacing) / trueSize)
    local fullRows = floor(visibleBuffs / buffsPerRow)
    local excessBuffs = (visibleBuffs - (fullRows * buffsPerRow))

    -- First start with how many full rows are set
    local offset = trueSize*fullRows

    -- Then figure out if Buffs and Debuffs will overlap
    if excessBuffs > 0 and excessBuffs + (visibleDebuffs*2) > buffsPerRow then
        offset = offset + trueSize
    end

    self.Debuffs:SetPoint('BOTTOM', self.Buffs, 0, offset)

    -- NOTE: There is a very small edge case where if the width is a odd
    -- number of icons the debuffs will be bumped up when it could fit
end

--------------------------------------------------------------------------------
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

local function GroupRoleCornerIndicator(self)
    local element = self.GroupRoleIndicator
    local role = UnitGroupRolesAssigned(self.unit)
    if role == 'TANK' then
        element:SetBackdropColor(1, 1, 1, 1)
        element:Show()
    elseif role == 'HEALER' then
        element:SetBackdropColor(0, 1, 0, 1)
        element:Show()
    else
        element:Hide()
    end
end

--------------------------------------------------------------------------------
-- ClassIcons Functions
local ClassPowerUpdateColor
do
    local classPowerType = {
        MONK    = 'CHI',
        PALADIN = 'HOLY_POWER',
        WARLOCK = 'SOUL_SHARDS',
        ROGUE   = 'COMBO_POINTS',
        DRUID   = 'COMBO_POINTS',
        MAGE    = 'ARCANE_CHARGES'
    }

    function ClassPowerUpdateColor(ClassPower)
        local parent = ClassPower.__owner
        local color = parent.colors.power[classPowerType[playerClass] or 'COMBO_POINTS']
        for i = 1, #ClassPower do
            local icon = ClassPower[i]

            icon:SetStatusBarColor(color[1], color[2], color[3])
            icon.bg:SetVertexColor(color[1]*0.4, color[2]*0.4, color[3]*0.4)
        end
    end
end

local function ClassPowerPostUpdate(ClassPower, cur, max, mod, maxChanged, powerType)
    -- Show or hide the entire frame on enable/disable
    if max == nil then return ClassPower:Hide()
    elseif max ~= nil then ClassPower:Show() end

    -- Only need to update when the max hax changed
    if maxChanged then
        -- Figure out the new width -- (Inside width - number of gaps / max)
        local width = (((ClassPower:GetWidth()-2) - (max-1)) / max)

        for i = 1, max do
            ClassPower[i]:SetWidth(width)
            ClassPower[i].bg:Show()
        end

        for i = max+1, 6 do
            ClassPower[i].bg:Hide()
        end
    end
end

--------------------------------------------------------------------------------
-- HealPrediction
local function CreateHealPrediction(self, vertical)
    local myBar = CreateStatusBar(self.Health, true)
    myBar:SetStatusBarColor(64/255, 204/255, 255/255, .7)

    local otherBar = CreateStatusBar(self.Health, true)
    otherBar:SetStatusBarColor(64/255, 255/255, 64/255, .7)

    local absorbBar = CreateStatusBar(self.Health, true)
    absorbBar:SetStatusBarColor(220/255, 255/255, 230/255, .7)

    local healAbsorbBar = CreateStatusBar(self.Health, true)
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
    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        maxOverflow = 1.00,
        frequentUpdates = true,
    }
end


------------------------------------------------------------------ The Styles --
function Module:ConstructStyle(object, unit, isSingle)
    -- Clean unit names like 'boss1'
    unit = unit:gsub('%d', '')

    -- We can trust that the 'unit' passed will be the correct database key.
    -- Following execution, if it came from oUF:Spawn its the first parameter;
    -- If it came from oUF:SpawnHeader its the 'oUF-guessUnit', which we force
    -- the value of in 'oUF-initialConfigFunction'
    object.db = self.db.profile.units[unit]
    object.isSingle = isSingle
    object.objectName = unit

    -- Make the frame interactiveable
    object:RegisterForClicks('AnyUp')
    object:SetScript('OnEnter', OnEnter)
    object:SetScript('OnLeave', OnLeave)

    -- Background
    object.bg = object:CreateTexture(nil, 'BACKGROUND')
    object.bg:SetAllPoints(object)
    object.bg:SetColorTexture(0, 0, 0, 1)

    -- Border: changes color depending on the unit's classification (rare,elite)
    Addon:CreateBorder(object)
    object:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
    table.insert(object.__elements, UpdateUnitBorderColor)

    -- Overlay Frame -- used to attach icons/text to
    object.Overlay = CreateFrame('Frame', nil, object)
    object.Overlay:SetAllPoints(object)
    object.Overlay:SetFrameLevel(10) -- todo: does it have to be that high?

    -- Highlight
    object.Highlight = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.Highlight:SetAllPoints(object)
    object.Highlight:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
    object.Highlight:SetBlendMode('ADD')
    object.Highlight:SetVertexColor(1,1,1)
    object.Highlight:SetAlpha(0.3)
    object.Highlight:Hide()

    object:HookScript('OnEnter', HighlightUpdate)
    object:HookScript('OnLeave', HighlightUpdate)
    object:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate, true)
    table.insert(object.__elements, HighlightUpdate)

    -- Frame Range Fading
    object[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.5
    }

    -- All frames will have a health status bar
    object.Health = CreateStatusBar(object)
    object.Health:SetPoint('TOP', 0, -1)
    object.Health:SetPoint('LEFT', 1, 0)
    object.Health:SetPoint('RIGHT', -1, 0)
    object.Health:SetPoint('BOTTOM', 0, 1)
    object.Health.frequentUpdates = true
    object.Health.UpdateColor = HealthUpdateColor

    -- DispelHighlight
    object.DispelHighlight = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.DispelHighlight:SetAllPoints(object.Health)
    object.DispelHighlight:SetTexture("Interface\\AddOns\\"..ADDON_NAME.."\\media\\Dispel.tga")
    object.DispelHighlight:SetBlendMode('ADD')
    object.DispelHighlight:SetAlpha(0.7)

    -- Build the rest of the object depending on the style
    Module['Construct_'..object.style](self, object, unit, isSingle)
end

function Module:UpdateStyle(object)
    -- Update the rest of the object depening on the style
    -- Module['Update_'..object.style](self, object) -- NYI

    -- Update all oUF elements, something with them may have changed.
    object:UpdateAllElements('ForceUpdate')
end

function Module:Construct_Zoey(object, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 40
    local FRAME_WIDTH = 135

    if unit == 'player' or unit == 'target' then
        FRAME_WIDTH = 227
    end

    if isSingle then
        object:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    CreateHealPrediction(object)

    ----------------------------------------------------------------------------
    -- Build the other status bars
    ----------------------------------------------------------------------------
    object.Power = CreateStatusBar(object)
    object.Power:SetHeight(FRAME_HEIGHT * 0.25)
    object.Power:SetPoint('LEFT', 1, 0)
    object.Power:SetPoint('RIGHT', -1, 0)
    object.Power:SetPoint('BOTTOM', 0, 1)
    object.Power.frequentUpdates = true
    object.Power.UpdateColor = PowerUpdateColor

    object.Health:SetPoint('BOTTOM', object.Power, 'TOP', 0, 1)

    if unit == 'party' then
        object.Portrait = CreateFrame('PlayerModel', nil, object)
        object.Portrait:SetHeight(FRAME_HEIGHT - 1.5)
        object.Portrait:SetPoint('TOP', 0, -1)
        object.Portrait:SetPoint('LEFT', 1, 0)
        object.Portrait:SetPoint('RIGHT', -2, 0)
        object.Portrait:SetAlpha(0.4)

        object.Health:SetPoint('TOP', object.Portrait, 'BOTTOM', 0, -1.5)

        -- Portraits double the frame size
        FRAME_HEIGHT = FRAME_HEIGHT * 2

        if isSingle then object:SetHeight(FRAME_HEIGHT) end
    end

    ----------------------------------------------------------------------------
    -- Class Specific
    ----------------------------------------------------------------------------
    -- Class Power
    if unit == 'player' then
        object.ClassPower = CreateFrame('Frame', nil, object)
        object.ClassPower:SetHeight(10)
        object.ClassPower:SetWidth(FRAME_WIDTH - 10)
        object.ClassPower:SetPoint('TOP', object, 'BOTTOM', 0, -3)
        object.ClassPower:SetFrameLevel(object:GetFrameLevel() -1)
        Addon:CreateBorder(object.ClassPower)

        object.ClassPower.bg = object.ClassPower:CreateTexture(nil,'BACKGROUND')
        object.ClassPower.bg:SetAllPoints(object.ClassPower)
        object.ClassPower.bg:SetColorTexture(0,0,0,1)

        object.ClassPower.PostUpdate = ClassPowerPostUpdate
        object.ClassPower.UpdateTexture = ClassPowerUpdateColor

        for i = 1, 6 do
            local icon = CreateStatusBar(object.ClassPower)

            icon:SetPoint('TOP', 0, -1)
            icon:SetPoint('LEFT', 1, 0)
            icon:SetPoint('BOTTOM', 0, 1)

            if i ~= 1 then
                icon:SetPoint('LEFT', object.ClassPower[i-1], 'RIGHT', 1, 0)
            end

            -- Reanchor so it's not hidden when the icon is
            icon.bg:SetParent(object.ClassPower)
            icon.bg:SetDrawLayer('BACKGROUND', 1)

            object.ClassPower[i] = icon
        end
    end

    -- Monk Stagger Bar
    if unit == 'player' and playerClass == 'MONK' then
        object.Stagger = CreateStatusBar(object)
        object.Stagger:SetFrameLevel(object:GetFrameLevel()-1)

        -- Build a frame around the stagger bar
        object.Stagger.Frame = CreateFrame('Frame', nil, object.Stagger)
        object.Stagger.Frame:SetFrameLevel(object.Stagger:GetFrameLevel()-1)
        object.Stagger.Frame.bg = object.Stagger.Frame:CreateTexture(nil, 'BACKGROUND')
        object.Stagger.Frame.bg:SetAllPoints(object.Stagger.Frame)
        object.Stagger.Frame.bg:SetColorTexture(0, 0, 0, 1)
        Addon:CreateBorder(object.Stagger.Frame)

        -- Size and place the Stagger Frame
        object.Stagger.Frame:SetHeight(10)
        object.Stagger.Frame:SetWidth(FRAME_WIDTH - 10)
        object.Stagger.Frame:SetPoint('TOP', object, 'BOTTOM', 0, -3)

        -- Attach the Stagger bar to the Frame
        object.Stagger:SetPoint('TOPLEFT', object.Stagger.Frame)
        object.Stagger:SetPoint('BOTTOMRIGHT', object.Stagger.Frame, 0, 1)
    end

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    object.NameTag = CreateFontString(object.Overlay, 13)
    object.NameTag:SetPoint('LEFT', object, 'TOPLEFT', 3, 1)
    object.NameTag:SetPoint('RIGHT', object, 'TOPRIGHT', -3, 1)
    object:Tag(object.NameTag, '[leadericon][Level< ][Name][ - >Realm]')

    object.HealthTag = CreateFontString(object.Overlay, 17)
    object.HealthTag:SetPoint('RIGHT', object.Health, -1, -1)
    object.HealthTag.frequentUpdates = true
    object:Tag(object.HealthTag, '[Health]')

    object.PowerTextTag = CreateFontString(object.Overlay, 10)
    object.PowerTextTag:SetPoint('RIGHT', object.Power, -1, -1)
    object.PowerTextTag.frequentUpdates = true
    object:Tag(object.PowerTextTag, '[Power]')

    if object.Portrait then
        object.GuildTag = CreateFontString(object.Overlay, 12)
        object.GuildTag:SetPoint('TOP', object.NameTag, 'BOTTOM', 0, -1)
        object.GuildTag:SetPoint('LEFT', object.NameTag)
        object.GuildTag:SetPoint('RIGHT', object.NameTag)
        object:Tag(object.GuildTag, '[Guild]')
    end

    ----------------------------------------------------------------------------
    -- Indicators
    ----------------------------------------------------------------------------
    if unit == 'player' then
        object.RestingIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.RestingIndicator:SetSize(20,20)
        object.RestingIndicator:SetPoint('LEFT', object.Overlay, 'BOTTOMLEFT', 0, 2)

        object.CombatIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.CombatIndicator:SetSize(20,20)
        object.CombatIndicator:SetPoint('RIGHT', object.Overlay, 'BOTTOMRIGHT', 0, 2)
    end

    if unit == 'target' then
        object.QuestIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.QuestIndicator:SetSize(32,32)
        object.QuestIndicator:SetPoint('CENTER', object.Overlay, 'LEFT')
    end

    object.GroupRoleIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.GroupRoleIndicator:SetSize(15,15)
    object.GroupRoleIndicator:SetPoint('CENTER', object.Overlay, 'TOPRIGHT', 1, 0)

    if unit == 'party' then
        object.ReadyCheckIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.ReadyCheckIndicator:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
        object.ReadyCheckIndicator:SetPoint('CENTER')
    end

    object.RaidTargetIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.RaidTargetIndicator:SetSize(23,23)
    object.RaidTargetIndicator:SetPoint('LEFT', 3, 0)

    object.PvPIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY', nil, 1)
    object.PvPIndicator:SetSize(21,21)
    object.PvPIndicator:SetPoint('CENTER', object.Overlay, 'LEFT')

    object.PvPIndicator.Prestige = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.PvPIndicator.Prestige:SetSize(41,43)
    object.PvPIndicator.Prestige:SetPoint('CENTER', object.PvPIndicator)

    if unit == 'party' or unit == 'target' or unit == 'focus' then
        object.PhaseIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.PhaseIndicator:SetPoint('TOP', object)
        object.PhaseIndicator:SetPoint('BOTTOM', object)
        object.PhaseIndicator:SetWidth(FRAME_HEIGHT * 2)
        object.PhaseIndicator:SetTexture([[Interface\Icons\Spell_Frost_Stun]])
        object.PhaseIndicator:SetTexCoord(0.05, 0.95, 0.25, 0.75)
        object.PhaseIndicator:SetAlpha(0.5)
        object.PhaseIndicator:SetBlendMode('ADD')
        object.PhaseIndicator:SetDesaturated(true)
        object.PhaseIndicator:SetVertexColor(0.4, 0.8, 1)
    end

    object.ResurrectIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.ResurrectIndicator:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    object.ResurrectIndicator:SetPoint('CENTER')

    ----------------------------------------------------------------------------
    -- Cast Bars
    ----------------------------------------------------------------------------
    if unit == 'player' or unit == 'target' then
        object.Castbar = CreateStatusBar(object)

        object.Castbar.Frame = CreateFrame('Frame', nil, object.Castbar)
        object.Castbar.Frame:SetFrameLevel(object.Castbar:GetFrameLevel()-1)
        object.Castbar.Frame.bg = object.Castbar.Frame:CreateTexture(nil, 'BACKGROUND')
        object.Castbar.Frame.bg:SetAllPoints(object.Castbar.Frame)
        object.Castbar.Frame.bg:SetColorTexture(0, 0, 0, 1)
        Addon:CreateBorder(object.Castbar.Frame)

        object.Castbar:SetPoint('TOPLEFT', object.Castbar.Frame, 1, -1)
        object.Castbar:SetPoint('BOTTOMRIGHT', object.Castbar.Frame, -1, 1)

        -- Size and place the Castbar Frame
        if unit == 'player' then
            object.Castbar.Frame:SetSize(300,18)
            object.Castbar.Frame:SetPoint('BOTTOM', self.Anchor, 0, -30)
        elseif unit == 'target' then
            object.Castbar.Frame:SetSize(300,30)
            object.Castbar.Frame:SetPoint('BOTTOM', self.Anchor, 0, 100)
        end

        -- Spell Icon
        if unit == 'target' then
            object.Castbar.Icon = object.Castbar:CreateTexture(nil, 'BACKDROP')
            object.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            object.Castbar.Icon:SetPoint('TOPLEFT', object.Castbar.Frame, 1, -1)
            object.Castbar.Icon:SetPoint('BOTTOMLEFT', object.Castbar.Frame, 1, 1)
            object.Castbar.Icon:SetWidth(object.Castbar.Frame:GetHeight())

            -- Anchor the castbar to the icon.
            object.Castbar:SetPoint('TOPLEFT', object.Castbar.Icon, 'TOPRIGHT', 1, 0)
        end

        -- Player only Latency
        if unit == 'player' then
            object.Castbar.SafeZone = object.Castbar:CreateTexture(nil,'OVERLAY')
            object.Castbar.SafeZone:SetTexture(object.Castbar:GetStatusBarTexture():GetTexture())
            object.Castbar.SafeZone:SetVertexColor(unpack(object.colors.cast.safezone))

            object.Castbar.Lag = CreateFontString(object.Castbar, 10)
            object.Castbar.Lag:SetPoint('TOPRIGHT', object.Castbar, 'BOTTOMRIGHT', 0, -7)
        end

        -- Castbar Texts
        if unit == 'player' then
            object.Castbar.Text = CreateFontString(object.Castbar, 13)
            object.Castbar.Time = CreateFontString(object.Castbar, 9)

        elseif unit == 'target' then
            object.Castbar.Text = CreateFontString(object.Castbar, 18)
            object.Castbar.Time = CreateFontString(object.Castbar, 12)
        end
        object.Castbar.Text:SetPoint('LEFT', 5, 0)
        object.Castbar.Time:SetPoint('RIGHT', -5, 0)

    elseif unit:match('boss%d') then
        object.Castbar = CreateStatusBar(object)

        object.Castbar.Frame = CreateFrame('Frame', nil, object.Castbar)
        object.Castbar.Frame:SetFrameLevel(object.Castbar:GetFrameLevel()-1)
        object.Castbar.Frame.bg = object.Castbar.Frame:CreateTexture(nil, 'BACKGROUND')
        object.Castbar.Frame.bg:SetAllPoints(object.Castbar.Frame)
        object.Castbar.Frame.bg:SetColorTexture(0, 0, 0, 1)

        object.Castbar:SetPoint('TOPLEFT', object.Castbar.Frame, 1, -1)
        object.Castbar:SetPoint('BOTTOMRIGHT', object.Castbar.Frame, -1, 1)

        -- Size and place the Castbar Frame
        object.Castbar.Frame:SetSize(FRAME_WIDTH, 20)
        object.Castbar.Frame:SetPoint('BOTTOMLEFT', object, 'BOTTOMRIGHT', 8, 0)

        -- Spell Icon
        object.Castbar.Icon = object.Castbar:CreateTexture(nil, 'BACKDROP')
        object.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        object.Castbar.Icon:SetPoint('TOPLEFT', object.Castbar.Frame, 1, -1)
        object.Castbar.Icon:SetPoint('BOTTOMLEFT', object.Castbar.Frame, 1, 1)
        object.Castbar.Icon:SetWidth(object.Castbar.Frame:GetHeight())

        -- Anchor the castbar to the icon.
        object.Castbar:SetPoint('TOPLEFT', object.Castbar.Icon, 'TOPRIGHT', 1, 0)

        -- Castbar Texts
        object.Castbar.Text = CreateFontString(object.Castbar, 9)
        object.Castbar.Text:SetPoint('LEFT', 5, 0)

    else
        object.Castbar = CreateStatusBar(object, true)

        object.Castbar:SetFrameLevel(object.Health:GetFrameLevel()+1)
        object.Castbar:SetPoint('BOTTOMRIGHT', object.Health, 'BOTTOMRIGHT')
        object.Castbar:SetPoint('BOTTOMLEFT', object.Health, 'BOTTOMLEFT')
        object.Castbar:SetHeight(2)

        object.Castbar.Text = CreateFontString(object.Castbar, 9)
        object.Castbar.Text:SetPoint('BOTTOMLEFT', object.Castbar, 'TOPLEFT', 2, 0)
    end

    -- Add a spark
    object.Castbar.Spark = object.Castbar:CreateTexture(nil, 'OVERLAY')
    object.Castbar.Spark:SetHeight(object.Castbar:GetHeight()*2.5)
    object.Castbar.Spark:SetBlendMode('ADD')
    object.Castbar.Spark:SetAlpha(0.5)

    -- Castbar Function Hooks
    object.Castbar.OnUpdate = CastbarOnUpdate
    object.Castbar.PostCastStart = PostCastStart
    object.Castbar.PostChannelStart = PostCastStart
    object.Castbar.PostCastStop = PostCastStop
    object.Castbar.PostChannelStop = PostChannelStop
    object.Castbar.PostCastFailed = PostCastFailed
    object.Castbar.PostCastInterrupted = PostCastFailed
    object.Castbar.PostCastInterruptible = PostCastInterruptible
    object.Castbar.PostCastNotInterruptible = PostCastNotInterruptible

    ----------------------------------------------------------------------------
    -- Auras
    ----------------------------------------------------------------------------
    if unit == 'player' or unit == 'target' then

        object.Buffs = CreateFrame('Frame', nil, object)

        object.Buffs.size = 20
        object.Buffs.spacing = 3

        local trueSize = object.Buffs.size + object.Buffs.spacing
        local buffsPerRow = floor((object:GetWidth() + object.Buffs.spacing) / trueSize)
        object.Buffs.num = buffsPerRow * 4

        object.Buffs:SetPoint('BOTTOM', object, 'TOP', 0, 8)
        object.Buffs:SetSize((trueSize * buffsPerRow) - object.Buffs.spacing, 1)

        if unit == 'player' then
            object.Buffs.initialAnchor = 'BOTTOMLEFT'
            object.Buffs['growth-x'] = 'RIGHT'
        elseif unit == 'target' then
            object.Buffs.initialAnchor = 'BOTTOMRIGHT'
            object.Buffs['growth-x'] = 'LEFT'
        end
        object.Buffs['growth-y'] = 'UP'

        object.Buffs.PostCreateIcon = PostCreateAuraIcon
        object.Buffs.PostUpdateIcon = PostUpdateAuraIcon
        object.Buffs.PostUpdate = PostUpdateAuras

        ------------------------------------------------------------------------

        object.Debuffs = CreateFrame('Frame', nil, object)

        -- The debuffs are double the size of buffs.
        object.Debuffs.size = (object.Buffs.size * 2) + object.Buffs.spacing
        object.Debuffs.spacing = object.Buffs.spacing
        object.Debuffs.num = object.Buffs.num / 4

        -- Match the Buff Frame so the icons stay aligned
        object.Debuffs:SetPoint('BOTTOM', object.Buffs)
        object.Debuffs:SetSize(object.Buffs:GetSize())

        if unit == 'player' then
            object.Debuffs.initialAnchor = 'BOTTOMRIGHT'
            object.Debuffs['growth-x'] = 'LEFT'
        elseif unit == 'target' then
            object.Debuffs.initialAnchor = 'BOTTOMLEFT'
            object.Debuffs['growth-x'] = 'RIGHT'
        end
        object.Debuffs['growth-y'] = 'UP'

        object.Debuffs.PostCreateIcon = PostCreateAuraIcon
        object.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
        object.Debuffs.PostUpdate = PostUpdateAuras

    elseif unit:match('boss%d') then
        object.Buffs = CreateFrame('Frame', nil, object)
        object.Buffs:SetSize(FRAME_WIDTH, 1)
        object.Buffs:SetPoint('TOPLEFT', object, 'TOPRIGHT', 8, 0)

        object.Buffs.initialAnchor = 'TOPLEFT'
        object.Buffs['growth-x'] = 'RIGHT'
        object.Buffs['growth-y'] = 'DOWN'
        object.Buffs.spacing = 3
        object.Buffs.size = 20

        local trueSize = object.Buffs.size + object.Buffs.spacing
        object.Buffs.num = floor(object.Buffs:GetWidth() / trueSize)

        object.Buffs.PostCreateIcon = PostCreateAuraIcon
        object.Buffs.PostUpdateIcon = PostUpdateAuraIcon

    elseif unit == 'party' or unit == 'focus' then

        object.Debuffs = CreateFrame('Frame', nil, object)

        if unit == 'focus' then
            object.Debuffs:SetSize(object:GetWidth(), 1)
            object.Debuffs:SetPoint('TOP', object, 'BOTTOM', 0, -8)
        else
            object.Debuffs:SetSize(FRAME_WIDTH, 1)
            object.Debuffs:SetPoint('TOPLEFT', object, 'TOPRIGHT', 12, 0)
        end

        object.Debuffs.initialAnchor = 'TOPLEFT'
        object.Debuffs['growth-x'] = 'RIGHT'
        object.Debuffs['growth-y'] = 'DOWN'
        object.Debuffs.spacing = 3
        object.Debuffs.size = 30

        local trueSize = object.Debuffs.size + object.Debuffs.spacing
        object.Debuffs.num = floor(object.Debuffs:GetWidth() / trueSize)

        object.Debuffs.PostCreateIcon = PostCreateAuraIcon
        object.Debuffs.PostUpdateIcon = PostUpdateAuraIcon

    end
end
function Module:Construct_ZoeyThin(object, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 20
    local FRAME_WIDTH  = 135

    if isSingle then
        object:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    CreateHealPrediction(object)

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    object.NameTag = CreateFontString(object.Overlay, 11)
    object.NameTag:SetPoint('LEFT', object, 'TOPLEFT', 3, 1)
    object.NameTag:SetPoint('RIGHT', object, 'TOPRIGHT', -3, 1)
    object:Tag(object.NameTag, '[Level< ][Name]')

    object.StatusTextTag = CreateFontString(object.Overlay, 15)
    object.StatusTextTag:SetPoint('RIGHT', object.Health, -1, 0)
    object:Tag(object.StatusTextTag, '[Status]')

    ----------------------------------------------------------------------------
    -- Indicators
    ----------------------------------------------------------------------------
    object.LeaderIndicator = CreateCornerIndicator(object.Overlay)
    object.LeaderIndicator:SetBackdropColor(0.65, 0.65, 1, 1)
    object.LeaderIndicator:SetPoint('TOPLEFT')

    object.AssistantIndicator = CreateCornerIndicator(object.Overlay)
    object.AssistantIndicator:SetBackdropColor(1, 0.75, 0.5, 1)
    object.AssistantIndicator:SetPoint('TOPLEFT')

    object.GroupRoleIndicator = CreateCornerIndicator(object.Overlay)
    object.GroupRoleIndicator:SetPoint('TOPRIGHT')
    object.GroupRoleIndicator.Override = GroupRoleCornerIndicator

    object.RaidTargetIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.RaidTargetIndicator:SetSize(16,16)
    object.RaidTargetIndicator:SetPoint('LEFT', 3, 0)

    object.PvPIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY', nil, 1)
    object.PvPIndicator:SetSize(16,16)
    object.PvPIndicator:SetPoint('CENTER', object.Overlay, 'LEFT')
end
function Module:Construct_ZoeySquare(object, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Setup the frame
    ----------------------------------------------------------------------------
    local FRAME_HEIGHT = 40
    local FRAME_WIDTH  = 65

    if isSingle then
        object:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    CreateHealPrediction(object,true)

    -- Grow healthbar top to bottom
    object.Health:SetOrientation('VERTICAL')

    -- Change Range Fading
    object[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.25
    }

    ----------------------------------------------------------------------------
    -- Build the other status bars
    ----------------------------------------------------------------------------
    object.Power = CreateStatusBar(object)
    object.Power:SetHeight(FRAME_HEIGHT * 0.125)
    object.Power:SetPoint('LEFT', 1, 0)
    object.Power:SetPoint('RIGHT', -1, 0)
    object.Power:SetPoint('BOTTOM', 0, 1)
    object.Power.UpdateColor = PowerUpdateColor

    object.Health:SetPoint('BOTTOM', object.Power, 'TOP', 0, 1)

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    object.NameTag = CreateFontString(object.Overlay, 9, 'center')
    object.NameTag:SetPoint('TOPLEFT', 3, -3)
    object.NameTag:SetPoint('TOPRIGHT', -3, -3)
    object:Tag(object.NameTag, '[Name]')

    object.StatusTextTag = CreateFontString(object.Overlay, 11, 'center')
    object.StatusTextTag:SetPoint('BOTTOMLEFT', object.Health, 3, 1)
    object.StatusTextTag:SetPoint('BOTTOMRIGHT', object.Health, -3, 1)
    object:Tag(object.StatusTextTag, '[Status]')

    ----------------------------------------------------------------------------
    -- Indicators
    ----------------------------------------------------------------------------
    object.LeaderIndicator = CreateCornerIndicator(object.Overlay)
    object.LeaderIndicator:SetBackdropColor(0.65, 0.65, 1, 1)
    object.LeaderIndicator:SetPoint('TOPLEFT')

    object.AssistantIndicator = CreateCornerIndicator(object.Overlay)
    object.AssistantIndicator:SetBackdropColor(1, 0.75, 0.5, 1)
    object.AssistantIndicator:SetPoint('TOPLEFT')

    object.GroupRoleIndicator = CreateCornerIndicator(object.Overlay)
    object.GroupRoleIndicator:SetPoint('TOPRIGHT')
    object.GroupRoleIndicator.Override = GroupRoleCornerIndicator

    object.ReadyCheckIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.ReadyCheckIndicator:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    object.ReadyCheckIndicator:SetPoint('CENTER')

    object.RaidTargetIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.RaidTargetIndicator:SetSize(16,16)
    object.RaidTargetIndicator:SetPoint('LEFT', 3, 0)

    object.ResurrectIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.ResurrectIndicator:SetSize(FRAME_HEIGHT, FRAME_HEIGHT)
    object.ResurrectIndicator:SetPoint('CENTER')
end
