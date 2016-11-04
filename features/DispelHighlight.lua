-- Get the addon namespace
local addon, ns = ...

local colors = { -- these are nicer than DebuffTypeColor
    Curse        = { 0.8, 0,   1   },
    Disease      = { 0.8, 0.6, 0   },
    Enrage       = { 1,   0.2, 0.6 },
    Invulnerable = { 1,   1,   0.4 },
    Magic        = { 0,   0.8, 1   },
    Poison       = { 0,   0.8, 0   },
}
oUF.colors.debuff = colors

local LibDispellable = LibStub('LibDispellable-1.0')

------------------------------------------------------------------------

local function Update(self, event, unit)
    if unit ~= self.unit then return end
    local element = self.DispelHighlight

    local dispellable, debufftype

    if LibDispellable:HasDispel() and UnitCanAssist('player', unit) then
        for index, dispelSpell, _, _, _, _, type in LibDispellable:IterateDispellableAuras(unit, true) do
            dispellable = true
            debuffType = type
        end
    end

    if dispellable then
        element:SetVertexColor(unpack(colors[debuffType]))
        element:Show()
    else
        element:Hide()
    end
end

local function ForceUpdate(element)
    return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
    local element = self.DispelHighlight
    if(element) then
        element.__owner = self
        element.ForceUpdate = ForceUpdate

        self:RegisterEvent("UNIT_AURA", Update)

        if element.GetTexture and not element:GetTexture() then
            element:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
        end

        return true
    end
end

local function Disable(self)
    local element = self.DispelHighlight
    if(element) then
        element:Hide()

        self:UnregisterEvent("UNIT_AURA", Update)
    end
end

oUF:AddElement("DispelHighlight", Update, Enable, Disable)

------------------------------------------------------------------------
