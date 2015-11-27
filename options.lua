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

end)
