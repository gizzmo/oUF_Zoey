local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local CreateStatusBar = Module.CreateStatusBar

--[[ TODO:
    Possible bug: Size wont update with frame size
    Setting: Size doesnt need to be the exact size of the health bar.
             will also need option to set anchor point [TOP, BOTTOM, CENTER]

    Setting: en/disable
]]

local function PostUpdateHealthPrediction(HealthPrediction)
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
    local health = object.Health

    local myBar = CreateStatusBar(health, true)
    local otherBar = CreateStatusBar(health, true)
    local absorbBar = CreateStatusBar(health, true)
    local healAbsorbBar = CreateStatusBar(health, true)

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

function Module.ConfigureHealthPrediction(object)
    local health = object.Health
    local orientation = health:GetOrientation()
    local reverseFill = health:GetReverseFill()
    local healthPrediction = object.HealthPrediction

    local myBar = healthPrediction.myBar
    local otherBar = healthPrediction.otherBar
    local absorbBar = healthPrediction.absorbBar
    local healAbsorbBar = healthPrediction.healAbsorbBar

    healthPrediction.maxOverflow = 1 + object.colors.healthPrediction.maxOverflow
    myBar:SetStatusBarColor(unpack(object.colors.healthPrediction.personal))
    otherBar:SetStatusBarColor(unpack(object.colors.healthPrediction.others))
    absorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.absorbs))
    healAbsorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.healAbsorbs))

    myBar:SetOrientation(orientation)
    otherBar:SetOrientation(orientation)
    absorbBar:SetOrientation(orientation)
    healAbsorbBar:SetOrientation(orientation)

    myBar:SetReverseFill(reverseFill)
    otherBar:SetReverseFill(reverseFill)
    absorbBar:SetReverseFill(reverseFill)
    healAbsorbBar:SetReverseFill(not reverseFill)

    -- Anchor Points
    myBar:ClearAllPoints()
    otherBar:ClearAllPoints()
    absorbBar:ClearAllPoints()
    healAbsorbBar:ClearAllPoints()

    local point
    local relativePoint

    if orientation == 'HORIZONTAL' then
        point = reverseFill and 'RIGHT' or 'LEFT'
        relativePoint = reverseFill and 'LEFT' or 'RIGHT'
    else
        point = reverseFill and 'TOP' or 'BOTTOM'
        relativePoint = reverseFill and 'BOTTOM' or 'TOP'
    end

    myBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint)
    otherBar:SetPoint(point, myBar:GetStatusBarTexture(), relativePoint)
    absorbBar:SetPoint(point, otherBar:GetStatusBarTexture(), relativePoint)
    healAbsorbBar:SetPoint(relativePoint, health:GetStatusBarTexture())
end
