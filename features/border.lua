-- Get the addon namespace
local addon, ns = ...

-- keep track of what objects we've put borders on?
ns.borderedObjects = {}

local sections = { 'TOPLEFT', 'TOP', 'TOPRIGHT', 'LEFT', 'RIGHT', 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT' }

local methods = {
    SetColor = function(self, r,g,b)
        if not r or not g or not b then
            r,g,b = unpack(oUF.colors.border.normal)
        end

        for _, tex in pairs(self) do
            tex:SetVertexColor(r,g,b)
        end
    end,

    SetSize = function(self, size, offset)
        local s = size or ns.config.border.size
        local o = offset or (floor(s / 2 + 0.5) - 2)

        for _, tex in pairs(self) do
            tex:SetSize(s,s)
        end

        self.TOPLEFT:SetPoint('TOPLEFT', -o, o)
        self.TOPRIGHT:SetPoint('TOPRIGHT', o, o)
        self.BOTTOMLEFT:SetPoint('BOTTOMLEFT', -o, -o)
        self.BOTTOMRIGHT:SetPoint('BOTTOMRIGHT', o, -o)
    end

    -- do we need more methods?
}

function ns.CreateBorder(self)
    if type(self) ~= 'table' or self.border then return end

    -- keep track of what objects we've put borders on?
    table.insert(ns.borderedObjects, self)

    -- set the methods
    local B = setmetatable({}, { __index = methods })

    -- create the border textures
    for i = 1, #sections do
        local x = self:CreateTexture(nil, 'BORDER')
        x:SetTexture(ns.config.border.texture)
        B[sections[i]] = x
    end

    -- Align the texture      ULx, ULy,    LLx, LLy,    URx, URy,    LRx, LRy
    B.LEFT:SetTexCoord       (0,   0,      0,   1,      1/8, 0,      1/8, 1)
    B.RIGHT:SetTexCoord      (1/8, 0,      1/8, 1,      2/8, 0,      2/8, 1)
    B.TOP:SetTexCoord        (2/8, 1,      3/8, 1,      2/8, 0,      3/8, 0)
    B.BOTTOM:SetTexCoord     (3/8, 1,      4/8, 1,      3/8, 0,      4/8, 0)
    B.TOPLEFT:SetTexCoord    (4/8, 0,      4/8, 1,      5/8, 0,      5/8, 1)
    B.TOPRIGHT:SetTexCoord   (5/8, 0,      5/8, 1,      6/8, 0,      6/8, 1)
    B.BOTTOMLEFT:SetTexCoord (6/8, 0,      6/8, 1,      7/8, 0,      7/8, 1)
    B.BOTTOMRIGHT:SetTexCoord(7/8, 0,      7/8, 1,      1,   0,      1,   1)

    -- Attach the edges to the corners. So we dont
    -- have to adjust their size just the corners
    B.TOP:SetPoint('TOPLEFT', B.TOPLEFT, 'TOPRIGHT')
    B.TOP:SetPoint('TOPRIGHT', B.TOPRIGHT, 'TOPLEFT')
    B.LEFT:SetPoint('TOPLEFT', B.TOPLEFT, 'BOTTOMLEFT')
    B.LEFT:SetPoint('BOTTOMLEFT', B.BOTTOMLEFT, 'TOPLEFT')
    B.RIGHT:SetPoint('TOPRIGHT', B.TOPRIGHT, 'BOTTOMRIGHT')
    B.RIGHT:SetPoint('BOTTOMRIGHT', B.BOTTOMRIGHT, 'TOPRIGHT')
    B.BOTTOM:SetPoint('BOTTOMLEFT', B.BOTTOMLEFT, 'BOTTOMRIGHT')
    B.BOTTOM:SetPoint('BOTTOMRIGHT', B.BOTTOMRIGHT, 'BOTTOMLEFT')

    -- set the default color and size
    B:SetColor()
    B:SetSize()

    -- save the border and return it
    self.Border = B
    return B
end
