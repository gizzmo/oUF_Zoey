local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local HighlightOnEnter, HighlightOnLeave, HighlightUpdate
do
    local mouseFocus
    function HighlightOnEnter(object)
        mouseFocus = object
        HighlightUpdate(object)
    end
    function HighlightOnLeave(object)
        mouseFocus = nil
        HighlightUpdate(object)
    end

    function HighlightUpdate(object)
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
end

function Module.CreateHighlight(object)
    object.Highlight = object.Overlay:CreateTexture(nil, 'OVERLAY')
    object.Highlight:SetAllPoints(object)
    object.Highlight:SetTexture([[Interface\QuestFrame\UI-QuestLogTitleHighlight]])
    object.Highlight:SetBlendMode('ADD')
    object.Highlight:SetVertexColor(1,1,1, 0.3)
    object.Highlight:Hide() -- start hidden

    object:HookScript('OnEnter', HighlightOnEnter)
    object:HookScript('OnLeave', HighlightOnLeave)
    object:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate, true)
    table.insert(object.__elements, HighlightUpdate) -- So its run with 'UpdateAllElements'
end
