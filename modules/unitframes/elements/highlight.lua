local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local mouseFocus
local function Update(object)
    local show

    -- Frame is curently mouse focused
    if mouseFocus == object then
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

local function OnEnter(object)
    mouseFocus = object
    Update(object)
end

local function OnLeave(object)
    mouseFocus = nil
    Update(object)
end

function Module.CreateHighlight(object)
    local element = object.Overlay:CreateTexture(nil, 'OVERLAY')
    element:SetAllPoints(object)
    element:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
    element:SetBlendMode('ADD')
    element:SetVertexColor(1,1,1, 0.3)
    element:Hide() -- start hidden

    object:HookScript('OnEnter', OnEnter)
    object:HookScript('OnLeave', OnLeave)
    object:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
    table.insert(object.__elements, Update) -- So its run with 'UpdateAllElements'

    object.Highlight = element
end
