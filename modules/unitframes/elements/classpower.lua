local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local CreateStatusBar = Module.CreateStatusBar

local function ClassPowerPostUpdate(ClassPower, cur, max, mod, maxChanged, powerType)
    -- Show or hide the entire frame on enable/disable
    if max == nil then return ClassPower:Hide()
    elseif max ~= nil then ClassPower:Show() end

    -- Only need to update when the max hax changed
    if maxChanged then
        -- Figure out the new width -- (Inside width - number of gaps / max)
        local width = (((ClassPower:GetWidth()-2) - (max-1)) / max)

        -- Update the new width
        for i = 1, max do
            ClassPower[i]:SetWidth(width)
            ClassPower[i].bg:Show() --insure it's shown
        end

        -- oUF has already hidden the icon, so lets also hide the bg.
        for i = max+1, 6 do
            ClassPower[i].bg:Hide()
        end
    end
end

function Module.CreateClassPower(object)
    object.ClassPower = CreateFrame('Frame', nil, object)
    object.ClassPower:SetHeight(10)
    object.ClassPower:SetWidth(object:GetWidth() - 10)
    object.ClassPower:SetPoint('TOP', object, 'BOTTOM', 0, -3)
    object.ClassPower:SetFrameLevel(object:GetFrameLevel() -1)
    Addon:CreateBorder(object.ClassPower)

    object.ClassPower.bg = object.ClassPower:CreateTexture(nil,'BACKGROUND')
    object.ClassPower.bg:SetAllPoints(object.ClassPower)
    object.ClassPower.bg:SetColorTexture(0,0,0,1)

    object.ClassPower.PostUpdate = ClassPowerPostUpdate

    for i = 1, 6 do
        local icon = CreateStatusBar(object.ClassPower)

        icon:SetPoint('TOP', 0, -1)
        icon:SetPoint('LEFT', 1, 0)
        icon:SetPoint('BOTTOM', 0, 1)

        if i ~= 1 then
            icon:SetPoint('LEFT', object.ClassPower[i-1], 'RIGHT', 1, 0)
        end

        -- oUF Hides the child icon when its not active. But we want the
        -- background to still be visable while its inactive.
        icon.bg:SetParent(object.ClassPower)
        icon.bg:SetDrawLayer('BACKGROUND', 1)

        object.ClassPower[i] = icon
    end
end

function Module.CreateStaggerBar(object)
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
    object.Stagger.Frame:SetWidth(object:GetWidth() - 10)
    object.Stagger.Frame:SetPoint('TOP', object, 'BOTTOM', 0, -3)

    -- Attach the Stagger bar to the Frame
    object.Stagger:SetPoint('TOPLEFT', object.Stagger.Frame)
    object.Stagger:SetPoint('BOTTOMRIGHT', object.Stagger.Frame, 0, 1)
end
