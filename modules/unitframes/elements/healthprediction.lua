local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local CreateStatusBar = Module.CreateStatusBar

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
    local orientation = health:GetOrientation()
	local reverseFill = health:GetReverseFill()

    local myBar = CreateStatusBar(health, true)
    local otherBar = CreateStatusBar(health, true)
    local absorbBar = CreateStatusBar(health, true)
    local healAbsorbBar = CreateStatusBar(health, true)

    myBar:SetStatusBarColor(unpack(object.colors.healthPrediction.personal))
    otherBar:SetStatusBarColor(unpack(object.colors.healthPrediction.others))
    absorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.absorbs))
    healAbsorbBar:SetStatusBarColor(unpack(object.colors.healthPrediction.healAbsorbs))

    myBar:SetOrientation(orientation)
    otherBar:SetOrientation(orientation)
    absorbBar:SetOrientation(orientation)
    healAbsorbBar:SetOrientation(orientation)

    healAbsorbBar:SetReverseFill(true)

    if orientation == 'HORIZONTAL' then
        myBar:SetPoint('LEFT', health:GetStatusBarTexture(), 'RIGHT')
        otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
        absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
        healAbsorbBar:SetPoint('RIGHT', health:GetStatusBarTexture())
    else
        myBar:SetPoint('BOTTOM', health:GetStatusBarTexture(), 'TOP')
        otherBar:SetPoint('BOTTOM', myBar:GetStatusBarTexture(), 'TOP')
        absorbBar:SetPoint('BOTTOM', otherBar:GetStatusBarTexture(), 'TOP')
        healAbsorbBar:SetPoint('TOP', health:GetStatusBarTexture())
    end

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
