-- Get the addon namespace
local addon, ns = ...

-- command to open options panel
SLASH_oUF_Zoey1 = '/zoey'
function SlashCmdList.oUF_Zoey(cmd)
    cmd = strlower(cmd)
    if cmd == 'config' or cmd == '' then
        InterfaceOptionsFrame_OpenToCategory('oUF Zoey')
        InterfaceOptionsFrame_OpenToCategory('oUF Zoey')
    end
    -- TODO add option for layout switching
end


--//----------------------------------------------------------------------
--// Options panel
--//----------------------------------------------------------------------
LibStub("PhanxConfig-OptionsPanel"):New('oUF Zoey', nil, function(panel)
    local db = oUF_ZoeyConfig
    local Media = LibStub("LibSharedMedia-3.0")

    --------------------------------------------------------------------
    local title, notes = panel:CreateHeader(panel.name, 'oUF_Zoey is a layout for Haste\'s oUF framework. Use this panel to configure some basic options for this layout.')

    --------------------------------------------------------------------
    local statusbar = panel:CreateMediaDropdown('Statusbar texture', nil, "statusbar")
    statusbar:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -12)
    statusbar:SetPoint("TOPRIGHT", notes, "BOTTOM", -12, -16)

    function statusbar:OnValueChanged(value)
        if value == db.statusbar then return end
        db.statusbar = value
        ns.SetAllStatusBarTextures()
    end

    --------------------------------------------------------------------
    local player_target_gap = panel:CreateSlider('Player Target gap', 'The gap between the Player and Target frames',
        12, -- minValue
        500, --maxValue
        2 -- valueStep
    )
    player_target_gap:SetPoint('TOPLEFT', statusbar, 'BOTTOMLEFT', 0, -10)
    player_target_gap:SetPoint('TOPRIGHT', statusbar, 'BOTTOMRIGHT', 0, -10)

    function player_target_gap:OnValueChanged(value)
        local point, relativeTo, relativePoint, xOffset, yOffset

        db.ptgap = value

        -- adjust Player frame
        point, relativeTo, relativePoint, xOffset, yOffset = oUF_ZoeyPlayer:GetPoint(1)
        oUF_ZoeyPlayer:SetPoint(point, relativeTo, relativePoint, -(value/2), yOffset)

        -- adjust Target frame
        point, relativeTo, relativePoint, xOffset, yOffset = oUF_ZoeyTarget:GetPoint(1)
        oUF_ZoeyTarget:SetPoint(point, relativeTo, relativePoint, value, yOffset)
    end

    --------------------------------------------------------------------
    -- Update when the options panel is shown
    function panel.refresh()
        statusbar:SetValue(db.statusbar)
        statusbar.valueBG:SetTexture(Media:Fetch("statusbar", db.statusbar))

        player_target_gap:SetValue(db.ptgap)
    end
end)
