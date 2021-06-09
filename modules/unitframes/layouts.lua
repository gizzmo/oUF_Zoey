local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local _, playerClass = UnitClass('player')

--------------------------------------------------------------------------------
local CreateFontString = Module.CreateFontString
local CreateStatusBar = Module.CreateStatusBar




--------------------------------------------------------------------------------
-- Castbar Functions
local function PostCastStart(Castbar, unit)
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

    if Castbar.Lag then
        local _, _, _, ms = GetNetStats()
        Castbar.Lag:SetFormattedText('%d ms', ms)
    end

    Castbar:PostCastInterruptible(unit)
end

local function PostCastStop(Castbar, unit, spellID)
    Castbar:Show()
end

local function PostCastFail(Castbar, unit, spellID)
    local parent = Castbar.__owner
    local r,g,b = unpack(parent.colors.cast.failed)

    Castbar:SetStatusBarColor(r,g,b)

    if Castbar.bg then
        local mu = Castbar.bg.multiplier
        Castbar.bg:SetVertexColor(r*mu, g*mu, b*mu)
    end
end

local function PostCastInterruptible(Castbar, unit)
    local parent = Castbar.__owner
    if unit == 'target' then
        if Castbar.notInterruptible then
            Castbar.Frame.Border:SetColor(1,1,1)
        else
            Castbar.Frame.Border:SetColor(unpack(parent.colors.border))
        end
    end
end

-- We override the `OnUpdate` function so we can fade out after.
local function CastbarOnUpdate(Castbar, elapsed)
    if Castbar.casting or Castbar.channeling then
        local duration = Castbar.casting and Castbar.duration + elapsed or Castbar.duration - elapsed

        if (Castbar.casting and duration >= Castbar.max) or (duration <= 0) then
            Castbar.casting = nil
            Castbar.channeling = nil
            return
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
    button.cd:SetHideCountdownNumbers(true) -- hides cooldown font

    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count:ClearAllPoints()
    button.count:SetPoint('CENTER', button, 'BOTTOMRIGHT', -1, 0)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetPoint('TOPLEFT', -1, 1)
    button.bg:SetPoint('BOTTOMRIGHT', 1, -1)
    button.bg:SetColorTexture(0, 0, 0, 1)
end

local function PostUpdateAuraIcon(Auras, unit, button, index, position, duration, expiration, debuffType, isStealable)
    if button.isPlayer or button.caster == 'pet' then
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
        local square = CreateFrame('Frame', nil, parent, BackdropTemplateMixin and "BackdropTemplate")
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



------------------------------------------------------------------ The Styles --
function Module:ConstructStyle(object, unit, isSingle)
    -- Background
    object.bg = object:CreateTexture(nil, 'BACKGROUND')
    object.bg:SetAllPoints(object)
    object.bg:SetColorTexture(0, 0, 0, 1)

    -- Border
    object:CreateElement('Border')

    -- Highlight
    object:CreateElement('Highlight')

    -- Frame Range Fading
    object[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.5
    }

    -- DispelHighlight
    do
        local texture = object.Overlay:CreateTexture(nil, 'OVERLAY')
        texture:SetAllPoints(object)
        texture:SetTexture("Interface\\AddOns\\"..ADDON_NAME.."\\media\\Dispel.tga")
        texture:SetBlendMode("ADD")
        texture:SetVertexColor(1, 1, 1, 0) -- start hiddend
        texture.dispelAlpha = 0.7

        -- Register with oUF
        object.Dispellable = {
            dispelTexture = texture
        }
    end


    -- Status bars
    object:CreateElement('Health')
    object:CreateElement('Power')
    object:CreateElement('HealthPrediction')
    object:CreateElement('Portrait')

    -- Icons
    if unit == 'player' then
        object:CreateElement('RestingIndicator')
        object:CreateElement('CombatIndicator')
    end
    if unit == 'party'
    or unit == 'raid' then
        object:CreateElement('ReadyCheckIndicator')
    end

    if unit == 'player'
    or unit == 'target'
    or unit == 'party'
    or unit == 'raid' then
        object:CreateElement('ResurrectIndicator')
    end

    -- Build the rest of the object depending on the style
    Module['Construct_'..object.style](self, object, unit, isSingle)
end

function Module:UpdateStyle(object)
    -- Update the rest of the object depening on the style
    Module['Update_'..object.style](self, object)

    -- This will only configure elements that exist on the object.
    object:ConfigureAllElements()
end

function Module:Construct_Zoey(object, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Class Specific
    ----------------------------------------------------------------------------
    -- Class Power
    if unit == 'player' then
        object:CreateElement('ClassPower')

        -- Monk Stagger Bar
        if playerClass == 'MONK' then
            object:CreateElement('StaggerBar')
        elseif playerClass == 'PRIEST' then
            -- object:CreateElement('AdditionalPowerBar')
        end
    end

    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    object.NameTag = CreateFontString(object.Overlay, 13)
    object.NameTag:SetPoint('LEFT', object, 'TOPLEFT', 3, 1)
    object.NameTag:SetPoint('RIGHT', object, 'TOPRIGHT', -3, 1)
    object:Tag(object.NameTag, '[leadericon][Level<$ ][Name][ - $>Realm]')

    object.HealthTag = CreateFontString(object.Overlay, 17)
    object.HealthTag:SetPoint('RIGHT', object.Health, -1, -1)
    object:Tag(object.HealthTag, '[Health]')

    object.PowerTextTag = CreateFontString(object.Overlay, 10)
    object.PowerTextTag:SetPoint('RIGHT', object.Power, -1, -1)
    object:Tag(object.PowerTextTag, '[Power]')

    if unit == 'party' then
        object.GuildTag = CreateFontString(object.Overlay, 12)
        object.GuildTag:SetPoint('TOP', object.NameTag, 'BOTTOM', 0, -1)
        object.GuildTag:SetPoint('LEFT', object.NameTag)
        object.GuildTag:SetPoint('RIGHT', object.NameTag)
        object:Tag(object.GuildTag, '[Guild]')
    end

    ----------------------------------------------------------------------------
    -- Indicators
    ----------------------------------------------------------------------------
    if unit == 'target' then
        object.QuestIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.QuestIndicator:SetSize(32,32)
        object.QuestIndicator:SetPoint('CENTER', object.Overlay, 'LEFT')
    end

    if unit == 'party' or unit == 'target' or unit == 'focus' then
        object.PhaseIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
        object.PhaseIndicator:SetPoint('TOP', object)
        object.PhaseIndicator:SetPoint('BOTTOM', object)
        object.PhaseIndicator:SetWidth(object:GetHeight() * 2)
        object.PhaseIndicator:SetTexture([[Interface\Icons\Spell_Frost_Stun]])
        object.PhaseIndicator:SetTexCoord(0.05, 0.95, 0.25, 0.75)
        object.PhaseIndicator:SetAlpha(0.5)
        object.PhaseIndicator:SetBlendMode('ADD')
        object.PhaseIndicator:SetDesaturated(true)
        object.PhaseIndicator:SetVertexColor(0.4, 0.8, 1)
    end

    object.GroupRoleIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.GroupRoleIndicator:SetSize(15,15)
    object.GroupRoleIndicator:SetPoint('CENTER', object.Overlay, 'TOPRIGHT', 1, 0)

    object.RaidTargetIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.RaidTargetIndicator:SetSize(23,23)
    object.RaidTargetIndicator:SetPoint('LEFT', 3, 0)

    object.PvPIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY', nil, 1)
    object.PvPIndicator:SetSize(21,21)
    object.PvPIndicator:SetPoint('CENTER', object.Overlay, 'LEFT')

    object.PvPIndicator.Badge = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.PvPIndicator.Badge:SetSize(41,43)
    object.PvPIndicator.Badge:SetPoint('CENTER', object.PvPIndicator)

    object.SummonIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.SummonIndicator:SetSize(object:GetHeight(), object:GetHeight())
    object.SummonIndicator:SetPoint('CENTER')

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
            object.Castbar.Frame:SetPoint('BOTTOM', UIParent, 0, 215)
        elseif unit == 'target' then
            object.Castbar.Frame:SetSize(300,30)
            object.Castbar.Frame:SetPoint('BOTTOM', UIParent, 0, 345)
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

    elseif unit == 'boss' then
        object.Castbar = CreateStatusBar(object)

        object.Castbar.Frame = CreateFrame('Frame', nil, object.Castbar)
        object.Castbar.Frame:SetFrameLevel(object.Castbar:GetFrameLevel()-1)
        object.Castbar.Frame.bg = object.Castbar.Frame:CreateTexture(nil, 'BACKGROUND')
        object.Castbar.Frame.bg:SetAllPoints(object.Castbar.Frame)
        object.Castbar.Frame.bg:SetColorTexture(0, 0, 0, 1)

        object.Castbar:SetPoint('TOPLEFT', object.Castbar.Frame, 1, -1)
        object.Castbar:SetPoint('BOTTOMRIGHT', object.Castbar.Frame, -1, 1)

        -- Size and place the Castbar Frame
        object.Castbar.Frame:SetSize(object:GetWidth(), 20)
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

    elseif not unit:match('%wtarget$') then
        object.Castbar = CreateStatusBar(object, true)

        object.Castbar:SetFrameLevel(object.Health:GetFrameLevel()+1)
        object.Castbar:SetPoint('BOTTOMRIGHT', object.Health, 'BOTTOMRIGHT')
        object.Castbar:SetPoint('BOTTOMLEFT', object.Health, 'BOTTOMLEFT')
        object.Castbar:SetHeight(2)

        object.Castbar.Text = CreateFontString(object.Castbar, 9)
        object.Castbar.Text:SetPoint('BOTTOMLEFT', object.Castbar, 'TOPLEFT', 2, 0)
    end

    if object.Castbar then
        -- Add a spark
        object.Castbar.Spark = object.Castbar:CreateTexture(nil, 'OVERLAY')
        object.Castbar.Spark:SetPoint("CENTER", object.Castbar:GetStatusBarTexture(), "RIGHT", 0, 0)
        object.Castbar.Spark:SetHeight(object.Castbar:GetHeight()*2.5)
        object.Castbar.Spark:SetBlendMode('ADD')
        object.Castbar.Spark:SetAlpha(0.5)

        -- Castbar Function Hooks
        object.Castbar.OnUpdate = CastbarOnUpdate
        object.Castbar.PostCastStart = PostCastStart
        object.Castbar.PostCastStop = PostCastStop
        object.Castbar.PostCastFail = PostCastFail
        object.Castbar.PostCastInterruptible = PostCastInterruptible
    end


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

    elseif unit == 'boss' then
        object.Buffs = CreateFrame('Frame', nil, object)
        object.Buffs:SetSize(object:GetWidth(), 1)
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
            object.Debuffs:SetSize(object:GetWidth(), 1)
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
function Module:Update_Zoey(object)
end

function Module:Construct_ZoeyThin(object, unit, isSingle)
    ----------------------------------------------------------------------------
    -- Tags
    ----------------------------------------------------------------------------
    object.NameTag = CreateFontString(object.Overlay, 11)
    object.NameTag:SetPoint('LEFT', object, 'TOPLEFT', 3, 1)
    object.NameTag:SetPoint('RIGHT', object, 'TOPRIGHT', -3, 1)
    object:Tag(object.NameTag, '[Level<$ ][Name]')

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
function Module:Update_ZoeyThin(object)
end

function Module:Construct_ZoeySquare(object, unit, isSingle)
    -- Change Range Fading
    object[IsAddOnLoaded('oUF_SpellRange') and 'SpellRange' or 'Range'] = {
        insideAlpha = 1,
        outsideAlpha = 0.25
    }

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

    object.RaidTargetIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.RaidTargetIndicator:SetSize(16,16)
    object.RaidTargetIndicator:SetPoint('LEFT', 3, 0)

    object.SummonIndicator = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.SummonIndicator:SetSize(object:GetHeight(), object:GetHeight())
    object.SummonIndicator:SetPoint('CENTER')
end
function Module:Update_ZoeySquare(object)
end
