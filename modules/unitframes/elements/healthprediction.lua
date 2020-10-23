local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local function PostUpdateHealthPrediction(HealthPrediction, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
    local parent = HealthPrediction.__owner
    local width, height = parent.Health:GetSize()

    -- The size cant be set at creation, so we'll do it here.
    HealthPrediction.myBar:SetSize(width, height)
    HealthPrediction.otherBar:SetSize(width, height)
    HealthPrediction.absorbBar:SetSize(width, height)
    HealthPrediction.healAbsorbBar:SetSize(width, height)

    -- We only need to run once, used to init the bar size.
    HealthPrediction.PostUpdate = nil
end

function Module.CreateHealthPrediction(object)
    -- Incoming heals from the player
    local myBar = CreateStatusBar(object.Health, true)
    myBar:SetStatusBarColor(unpack(object.colors.healthPrediction.personal))
    myBar:SetPoint('LEFT', object.Health:GetStatusBarTexture(), 'RIGHT')

    -- Incoming heals from others
    local otherBar = CreateStatusBar(object.Health, true)
    otherBar:SetStatusBarColor(unpack(object.colors.healthPrediction.others))
    otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')

    -- Damage absorptions
    local absorbBar = CreateStatusBar(object.Health, true)
    absorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.absorbs))
    absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')

    -- Healing absorptions
    local healAbsorbBar = CreateStatusBar(object.Health, true)
    healAbsorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.healAbsorbs))
    healAbsorbBar:SetPoint('RIGHT', object.Health:GetStatusBarTexture())
    healAbsorbBar:SetReverseFill(true)

    -- Register with oUF
    object.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        maxOverflow = 1 + object.colors.healthPrediction.maxOverflow,
        PostUpdate = PostUpdateHealthPrediction,
    }
end
