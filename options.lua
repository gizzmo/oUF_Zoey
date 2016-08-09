-- Get the addon namespace
local addon, ns = ...


--------------------------------------------------------------------------------
local function SetAllFonts()
    local font = LibStub('LibSharedMedia-3.0'):Fetch('font', ns.db.font)

    for i = 1, #ns.fontstrings do
        local fs = ns.fontstrings[i]
        local _, size = fs:GetFont()
        fs:SetFont(font, size or 16)
    end
end

local function SetAllStatusBarTextures()
    local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', ns.db.statusbar)

    for i = 1, #ns.statusbars do
        local sb = ns.statusbars[i]

        --// Is it a statusbar or a texture
        if sb.SetStatusBarTexture then
            local r, g, b, a = sb:GetStatusBarColor()
            sb:SetStatusBarTexture(texture)
            sb:SetStatusBarColor(r, g, b, a)

        else
            local r, g, b, a = sb:GetVertexColor()
            sb:SetTexture(texture)
            sb:SetVertexColor(r, g, b, a)
        end
    end
end

------------------------------------------------------------------------
-- Options panel
------------------------------------------------------------------------
LibStub('PhanxConfig-OptionsPanel'):New('oUF Zoey', nil, function(panel)
    local db = ns.db
    local Media = LibStub('LibSharedMedia-3.0')

    --------------------------------------------------------------------
    local title, notes = panel:CreateHeader(panel.name, 'oUF_Zoey is a layout for Haste\'s oUF framework. Use this panel to configure some basic options for this layout.')

    --------------------------------------------------------------------
    local statusbar = panel:CreateMediaDropdown('Statusbar texture', nil, 'statusbar')
    statusbar:SetPoint('TOPLEFT', notes, 'BOTTOMLEFT', 0, -12)
    statusbar:SetPoint('TOPRIGHT', notes, 'BOTTOM', -12, -16)

    function statusbar:OnValueChanged(value)
        if value == db.statusbar then return end
        db.statusbar = value
        SetAllStatusBarTextures()
    end

    --------------------------------------------------------------------
    local font = panel:CreateMediaDropdown('Font', nil, 'font')
    font:SetPoint('TOPLEFT', statusbar, 'BOTTOMLEFT', 0, -10)
    font:SetPoint('TOPRIGHT', statusbar, 'BOTTOMRIGHT', 0, -10)

    function font:OnValueChanged(value)
        if value == db.font then return end
        db.font = value
        SetAllFonts()
    end

    --------------------------------------------------------------------
    local player_target_gap = panel:CreateSlider('Player Target gap', 'The gap between the Player and Target frames',
        12, -- minValue
        500, --maxValue
        2 -- valueStep
    )
    player_target_gap:SetPoint('TOPLEFT', font, 'BOTTOMLEFT', 0, -10)
    player_target_gap:SetPoint('TOPRIGHT', font, 'BOTTOMRIGHT', 0, -10)

    function player_target_gap:OnValueChanged(value)
        db.ptgap = value

        oUF_ZoeyUnitFrameAnchor:SetWidth(value)
    end

    --------------------------------------------------------------------
    local frames_offset = panel:CreateSlider('Unit frames offset', 'The distance from the bottom of the window.',
        50, -- minValue
        500, --maxValue
        1 -- valueStep

        -- TODO: figure out the max values possible and keep auras and other frames visibility
    )
    frames_offset:SetPoint('TOPLEFT', player_target_gap, 'BOTTOMLEFT', 0, -10)
    frames_offset:SetPoint('TOPRIGHT', player_target_gap, 'BOTTOMRIGHT', 0, -10)

    function frames_offset:OnValueChanged(value)
        db.frames_offset = value

        local point, relativeTo, relativePoint, xOffset, yOffset = oUF_ZoeyUnitFrameAnchor:GetPoint(1)
        oUF_ZoeyUnitFrameAnchor:SetPoint(point, relativeTo, relativePoint, xOffset, value)
    end

    --------------------------------------------------------------------
    -- Update when the options panel is shown
    function panel.refresh()
        statusbar:SetValue(db.statusbar)
        statusbar.valueBG:SetTexture(Media:Fetch('statusbar', db.statusbar))

        font:SetValue(db.font)

        player_target_gap:SetValue(db.ptgap)

        frames_offset:SetValue(db.frames_offset)
    end
end)
