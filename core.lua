--// Get the addon namespace
local addon, ns = ...

--// Get the Tags
local tags = ns.tags

-----------------------------
--// CONFIG
-----------------------------
local config = {

	healthbar_color = {89/255, 89/255, 89/255},
	healthbar_texture = [[Interface\AddOns\oUF_Zoey\media\Armory]],
	powerbar_texture = [[Interface\AddOns\oUF_Zoey\media\Armory]],

	portrait_size = 59,
	healthbar_size = 31,
	powerbar_size = 5,
	bar_spacing = 1,

	border_texture = [[Interface\AddOns\oUF_Zoey\media\ThinSquare]],
	border_colors = {
		normal = {113/255, 113/255, 113/255},
		rare = {1,1,1},
		elite = {1,1,0},
		boss = {1, .5, 1}
	},
	border_size = 12,
	border_padding = 4,

	font = [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]],

	highlight_color = {1,1,1, 75/255},
}
-----------------------------
--// FUNCTIONS
-----------------------------

local SetBorder = function(self)
	if type(self) ~= 'table' or not self.CreateTexture then return end

	--// Defaults
	local size = config.border_size
	local padding = config.border_padding
	local texture = config.border_texture

	--// If there is no textures, create them
	if not self.BorderTextures then
		t = {}

		for i = 1, 8 do
			t[i] = self:CreateTexture(nil, 'ARTWORK')
			t[i]:SetTexture(texture)
			t[i]:SetSize(size, size)
		end

		t[1].name = 'Top Left'
		t[1]:SetPoint('TOPLEFT', -padding, padding)
		t[1]:SetTexCoord(0.5, 0, 0.5, 1, 0.625, 0, 0.625, 1)


		t[2].name = 'Top'
		t[2]:SetPoint('TOPLEFT', size - padding, padding)
		t[2]:SetPoint('TOPRIGHT', -size + padding, padding)
		t[2]:SetTexCoord(0.25, 9.2808, 0.375, 9.2808, 0.25, 0, 0.375, 0)

		t[3].name = 'Top Right'
		t[3]:SetPoint('TOPRIGHT', padding, padding)
		t[3]:SetTexCoord(0.625, 0, 0.625, 1, 0.75, 0, 0.75, 1)

		t[4].name = 'Left'
		t[4]:SetPoint('TOPLEFT', -padding, -size + padding)
		t[4]:SetPoint('BOTTOMLEFT', -padding, size - padding)
		t[4]:SetTexCoord(0, 0, 0, 1.948, 0.125, 0, 0.125, 1.948)

		t[5].name = 'Right'
		t[5]:SetPoint('TOPRIGHT', padding, -size + padding)
		t[5]:SetPoint('BOTTOMRIGHT', padding, size - padding)
		t[5]:SetTexCoord(0.125, 0, 0.125, 1.948, 0.25, 0, 0.25, 1.948)

		t[6].name = 'Bottom Left'
		t[6]:SetPoint('BOTTOMLEFT', -padding, -padding)
		t[6]:SetTexCoord(0.75, 0, 0.75, 1, 0.875, 0, 0.875, 1)

		t[7].name = 'Bottom'
		t[7]:SetPoint('BOTTOMLEFT', size - padding, -padding)
		t[7]:SetPoint('BOTTOMRIGHT', -size + padding, -padding)
		t[7]:SetTexCoord(0.375, 9.2808, 0.5, 9.2808, 0.375, 0, 0.5, 0)

		t[8].name = 'Bottom Right'
		t[8]:SetPoint('BOTTOMRIGHT', padding, -padding)
		t[8]:SetTexCoord(0.875, 0, 0.875, 1, 1, 0, 1, 1)

		self.BorderTextures = t
	end

	--// Determin the border color
	local colors = config.border_colors
	local c = UnitClassification(self.unit)
	if c == "worldboss" then c = "boss" end
	if c == "rareelite" then c = "rare" end
	local r,g,b = unpack(colors[c] and colors[c] or colors['normal'])

	--// Set the border color
	for _, tex in ipairs(self.BorderTextures) do
		tex:SetVertexColor(r, g, b)
	end
end


--[[
function CreateHighlight(self)
	local Highlight = CreateFrame("Frame", nil, self)
	Highlight:SetAllPoints(self)
	Highlight:SetFrameLevel(self:GetFrameLevel() + 15)

	Highlight.tex = Highlight:CreateTexture(nil, "OVERLAY")
	Highlight.tex:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
	Highlight.tex:SetBlendMode('ADD')
	Highlight.tex:SetAlpha(0.5)
	Highlight.tex:SetAllPoints(Highlight)
	Highlight.tex:SetVertexColor(unpack(config.highlight_color))

	Highlight:Hide()
	self.Highlight = Highlight
end

local function UpdateHighlight(self)
	if UnitIsUnit('target', self.unit) then
		self.Highlight:Show()
	else
		self.Highlight:Hide()
	end
end


self:HookScript("OnEnter", function(self) self.Highlight:Show() end)
self:HookScript("OnLeave", function(self) self.Highlight:Hide() end)
self:RegisterEvent('PLAYER_TARGET_CHANGED', UpdateHighlight)
--]]


-----------------------------
--// STYLE FUNCTION
-----------------------------
oUF:RegisterStyle('oUF_Zoey', function(self, unit)

	--// Rightclick Menu
	self.menu = function(self)
		local unit = self.unit:sub(1, -2)
		if unit == 'party' or unit == 'partypet' then
			ToggleDropDownMenu(1, nil, _G['PartyMemberFrame' .. self.id .. 'DropDown'], 'cursor', 0, 0)
		else
			local cunit = self.unit:gsub('^%l', string.upper)
			if cunit == 'Vehicle' then
				cunit = 'Pet'
			end
			if _G[cunit .. 'FrameDropDown'] then
				ToggleDropDownMenu(1, nil, _G[cunit .. 'FrameDropDown'], 'cursor', 0, 0)
			end
		end
	end
	self:RegisterForClicks("AnyUp")
	self:SetAttribute("*type2", "menu")

	--// Hover Effects
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	--// Background
	local Background = self:CreateTexture(nil, "BACKGROUND")
	Background:SetAllPoints(self)
	Background:SetTexture(0, 0, 0, 1)

	--// Border
	SetBorder(self)

	--// Overlay Frame -- used to attach icons/text to
	local Overlay = CreateFrame('Frame', '$parentOverlay', self)
	Overlay:SetAllPoints(self)
	Overlay:SetFrameLevel(10)

	------------------------------
	--// Name Text
	------------------------------
	local Name = Overlay:CreateFontString(nil, 'OVERLAY')
	Name:SetFont(config.font, 16, config.fontOutline)
	Name:SetJustifyH('LEFT')
	Name:SetShadowOffset(1, -1)

	self:Tag(Name, '[Zoey:Name]')

	--// Default location
	Name:SetPoint("LEFT", self, "TOPLEFT", 3, 1)
	Name:SetPoint("RIGHT", self, "TOPRIGHT", -3, 1)

	--// Reposistion for target frame
	if unit == 'target' then
		Name:SetPoint("TOPLEFT", 3, -1)
		Name:SetPoint("TOPRIGHT", -3, -1)
	end

	--// Hover Effect on Player (and pet?)
	if unit == 'player' then --or unit == 'pet' then
		Name:Hide()
		self:HookScript("OnEnter", function() Name:Show(); end)
		self:HookScript("OnLeave", function() Name:Hide(); end)
	end


	--// Bar Position
	local offset = config.bar_spacing

	------------------------------
	--// Portrait
	------------------------------
	if unit == 'target' then -- later well add party
		self.Portrait = CreateFrame("PlayerModel", '$parentPortrait', self)
		self.Portrait:SetHeight(config.portrait_size)
		self.Portrait:SetPoint('TOP', 0, -offset)
		self.Portrait:SetPoint('LEFT', 1,0)
		self.Portrait:SetPoint('RIGHT',-1,0)

		--// offset the health bar's position
		offset = offset + self.Portrait:GetHeight() + config.bar_spacing
	end

	------------------------------
	--// Health Bar
	------------------------------
	self.Health = CreateFrame("StatusBar", '$parentHealthBar', self)
	self.Health:SetStatusBarTexture(config.healthbar_texture)
	self.Health:SetHeight(config.healthbar_size)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.frequentUpdates = .2

	-- Text
	self.Health.Text = self.Health:CreateFontString(nil, 'OVERLAY')
	self.Health.Text:SetFont(config.font, 21, config.fontOutline)
	self.Health.Text:SetJustifyH('RIGHT')
	self.Health.Text:SetShadowOffset(1, -1)
	self.Health.Text:SetPoint('RIGHT', -1, 0)
	self:Tag(self.Health.Text, '[Zoey:Health]')

	self.Health.PostUpdate = function(Health, unit, min,max)
		local r,g,b

		--// Determin the color we want to use
		if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
			r,g,b = unpack(self.colors.tapped)
		elseif not UnitIsConnected(unit) then
			r,g,b = unpack(self.colors.disconnected)
		else
			r,g,b = unpack(config.healthbar_color)
		end

		--// Set the health bar color
		Health:SetStatusBarColor(r, g, b)

		--// Set the background color
		Health.bg:SetVertexColor(25/255, 25/255, 25/255)
	end

	--// Background
	self.Health.bg = self:CreateTexture(nil, "BACKGROUND")
	self.Health.bg:SetTexture(config.healthbar_texture)
	self.Health.bg:SetAllPoints(self.Health)

	--// offset the power bar's position
	offset = offset + self.Health:GetHeight() + config.bar_spacing

	------------------------------
	--// Power Bar
	------------------------------
	self.Power = CreateFrame('StatusBar', '$parentPowerBar', self)
	self.Power:SetStatusBarTexture(config.powerbar_texture)
	self.Power:SetHeight(config.powerbar_size)
	self.Power:SetPoint('TOP', 0, -offset)
	self.Power:SetPoint('LEFT', 1,0)
	self.Power:SetPoint('RIGHT',-1,0)
	self.Power.frequentUpdates = .2

	-- Fix the colors
	self.Power.PostUpdate = function(Power, unit, min, max)
		local r,g,b

		--// Determin the color we want to use
		if UnitIsPlayer(unit) then
			local _, class = UnitClass(unit)
			r,g,b = unpack(self.colors.class[class])
		else
			local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)
			r,g,b = unpack(self.colors.power[ptoken])
		end

		--// Set the power bar color
		Power:SetStatusBarColor(r, g, b)

		--// Set the background color
		Power.bg:SetVertexColor(r * 0.4, g * 0.4, b * 0.4)
	end

	--// Background
	self.Power.bg = self:CreateTexture(nil, "BACKGROUND")
	self.Power.bg:SetTexture(config.powerbar_texture)
	self.Power.bg:SetAllPoints(self.Power)

	--// The true height of the frame
	offset = offset + self.Power:GetHeight() + config.bar_spacing

	--// -----------------------------
	--// Frame Size
	--// -----------------------------
	self:SetHeight(offset)
	self:SetWidth(139) -- default width

	if unit == 'player' or unit == 'target' then
		self:SetWidth(285)
	end

end)

-----------------------------
--// SPAWN UNITS
-----------------------------
oUF:Factory(function(self)

	local u = self.units
	local b = 'oUF_Zoey_Frames_'

	--// Player
	self:Spawn('Player'				):SetPoint('TOP', UIParent, 'CENTER', 0, -302)

	--// Player Pet
	self:Spawn('Pet'				):SetPoint('TOPRIGHT', u.player, 'TOPLEFT', -15, 0)
	self:Spawn('PetTarget'			):SetPoint('BOTTOM', u.pet, 'TOP', 0, 16)
	self:Spawn('PetTargetTarget'	):SetPoint('BOTTOM', u.pettarget, 'TOP', 0, 16)

	--// Targets
	self:Spawn('Target'				):SetPoint('BOTTOM', u.player, 'TOP', 0, 18)
	self:Spawn('TargetTarget'		):SetPoint('TOPLEFT', u.target, 'TOPRIGHT', 15, 0)
	self:Spawn('TargetTargetTarget'	):SetPoint('BOTTOMLEFT', u.target, 'BOTTOMRIGHT', 15, 0)

	--// Focus
	self:Spawn('Focus'				):SetPoint('TOPRIGHT', u.pet, 'TOPLEFT', -15, 0)
	self:Spawn('FocusTarget'		):SetPoint('BOTTOM', u.focus, 'TOP', 0, 16)
	self:Spawn('FocusTargetTarget'	):SetPoint('BOTTOM', u.focustarget, 'TOP', 0, 15)

end)

--// Disable Blizzard options that are rendered useless by having a unit frame addon
for _, button in pairs({
	'UnitFramePanelPartyBackground',
	'UnitFramePanelPartyPets',
	'UnitFramePanelFullSizeFocusFrame',

	'CombatPanelTargetOfTarget',
	'CombatPanelTOTDropDown',
	'CombatPanelTOTDropDownButton',
	'CombatPanelEnemyCastBarsOnPortrait',

	'DisplayPanelShowAggroPercentage',

	'FrameCategoriesButton9',
}) do
	_G['InterfaceOptions'..button]:SetAlpha(0.35)
	_G['InterfaceOptions'..button]:Disable()
	_G['InterfaceOptions'..button]:EnableMouse(false)
end

--// Remove Items from the Rightclick Menu
do
	for k, v in pairs(UnitPopupMenus) do
		for x, i in pairs(UnitPopupMenus[k]) do
			if i == 'SET_FOCUS'
			or i == 'CLEAR_FOCUS'
			or i == 'MOVE_PLAYER_FRAME'
			or i == 'MOVE_TARGET_FRAME' then
				table.remove(UnitPopupMenus[k],x)
			end
		end
	end
end
-----------------------------
--// THE END