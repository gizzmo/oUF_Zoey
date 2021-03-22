local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local function Update(object)
    if not object.Border or not object.unit then return end

    local c = UnitClassification(object.unit)
    if c == 'worldboss' then c = 'boss' end
    local t = object.colors.classification[c] or object.colors.border

    object.Border:SetColor(unpack(t))
end

function Module.CreateBorder(object)
    Addon:CreateBorder(object)

    object:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Update)
    table.insert(object.__elements, Update)
end

function Module.ConfigureBorder(object)
end
