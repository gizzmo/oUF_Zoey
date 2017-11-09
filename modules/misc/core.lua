local ADDON_NAME, Addon = ...

local MODULE_NAME = 'Miscellaneous'
local Module = Addon:NewModule(MODULE_NAME)

-- The place to modify other parts of the UI
-- before they are big enough for a real module

function Module:OnEnable()
    self:SkinMirrorTimers()
end

function Module:SkinMirrorTimers()
    for i = 1, 3 do
        local barname = 'MirrorTimer'..i
        local bar = _G[barname]

        -- Hide old border
        _G[barname..'Border']:Hide()

        -- Place where we want
        bar:SetParent(UIParent)
        bar:SetSize(285, 28)

        if i > 1 then
            local p1, p2, p3, p4, p5 = bar:GetPoint()
            bar:SetPoint(p1, p2, p3, p4, p5 - 15)
        end

        -- Add our style
        bar.bar = _G[ barname..'StatusBar' ]
        bar.bar:SetPoint('TOPLEFT', bar, 1, -1)
        bar.bar:SetPoint('BOTTOMRIGHT', bar, -1, 1)
        bar.bar:SetStatusBarTexture(Addon.Media:Fetch('statusbar', Addon.db.profile.general.texture))
        bar.bar:SetAlpha(0.8)

        bar.bg = bar:GetRegions()
        bar.bg:ClearAllPoints()
        bar.bg:SetAllPoints(bar)
        bar.bg:SetTexture(Addon.Media:Fetch('statusbar', Addon.db.profile.general.texture))
        bar.bg:SetVertexColor(0.2, 0.2, 0.2, 1)

        bar.text = _G[barname..'Text']
        bar.text:ClearAllPoints()
        bar.text:SetPoint('LEFT', bar, 6, -1)
        bar.text:SetFont(Addon.Media:Fetch('font', Addon.db.profile.font), 16)

        Addon:CreateBorder(bar)
    end
end
