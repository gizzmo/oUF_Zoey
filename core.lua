--// Get the addon namespace
local addon, ns = ...

local config = ns.config
local colors = oUF.colors


--//----------------------------
--// FUNCTIONS
--//----------------------------

--// Border Creation
local function CreateBorder(self, size)

	--// Want to change the Color? Use SetBorderColor
	local size = config.border.size
	local padding = config.border.padding
	local texture = config.border.texture
	local color = config.border.colors.normal

	--// Temp hold the textures
	local t = {}

	--// Shared for all 8 textures
	for i = 1, 8 do
		t[i] = self:CreateTexture(nil, 'ARTWORK')
		t[i]:SetTexture(texture)
		t[i]:SetSize(size, size)
		t[i]:SetVertexColor(unpack(color))
	end

	t[1].name = 'Top Left'
	t[1]:SetPoint('TOPLEFT', -padding, padding)
	t[1]:SetTexCoord(0.5, 0, 0.5, 1, 0.625, 0, 0.625, 1)

	t[2].name = 'Top'
	t[2]:SetPoint('TOPLEFT', size - padding, padding)
	t[2]:SetPoint('TOPRIGHT', -size + padding, padding)
	t[2]:SetTexCoord(0.25, 1, 0.375, 1, 0.25, 0, 0.375, 0)

	t[3].name = 'Top Right'
	t[3]:SetPoint('TOPRIGHT', padding, padding)
	t[3]:SetTexCoord(0.625, 0, 0.625, 1,0.75, 0, 0.75, 1)

	t[4].name = 'Left'
	t[4]:SetPoint('TOPLEFT', -padding, -size + padding)
	t[4]:SetPoint('BOTTOMLEFT', -padding, size - padding)
	t[4]:SetTexCoord(0, 0, 0, 1, 0.125, 0, 0.125, 1)

	t[5].name = 'Right'
	t[5]:SetPoint('TOPRIGHT', padding, -size + padding)
	t[5]:SetPoint('BOTTOMRIGHT', padding, size - padding)
	t[5]:SetTexCoord(0.125, 0, 0.125, 1, 0.25, 0, 0.25, 1)

	t[6].name = 'Bottom Left'
	t[6]:SetPoint('BOTTOMLEFT', -padding, -padding)
	t[6]:SetTexCoord(0.75, 0, 0.75, 1, 0.875, 0, 0.875, 1)

	t[7].name = 'Bottom'
	t[7]:SetPoint('BOTTOMLEFT', size - padding, -padding)
	t[7]:SetPoint('BOTTOMRIGHT', -size + padding, -padding)
	t[7]:SetTexCoord(0.375, 1, 0.5, 1, 0.375, 0, 0.5, 0)

	t[8].name = 'Bottom Right'
	t[8]:SetPoint('BOTTOMRIGHT', padding, -padding)
	t[8]:SetTexCoord(0.875, 0, 0.875, 1, 1, 0, 1, 1)

	self.BorderTextures = t
end

local function SetBorderColor(self, r,g,b)
	if not self.BorderTextures then return end

	if type(r) == 'table' then
		if r.r then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end

	--// If no color set, then grab the default
	if not r or not g or not b then
		r,g,b = unpack(config.border.colors.normal)
	end

	--// Set the border color
	for _, tex in ipairs(self.BorderTextures) do
		tex:SetVertexColor(r, g, b)
	end
end

local function UpdateUnitBorderColor(self, r,g,b)
	if not self.BorderTextures then return end

	local t

	if self.unit then
		local c = UnitClassification(self.unit)
		if c == 'worldboss' then c = 'boss' end
		if c == 'rareelite' then c = 'rare' end
		t = config.border.colors[c]
	end

	--// Threat coloring could also be put in here

	SetBorderColor(self, t)
end


--// Mouseover and Target Highlighting
local function HighlightShouldShow(self)

	--// Frame is curently mouse focused
	if ns.Mouse_Focus == self then
		return true
	end

	--// Frame is not the current target
	if not UnitIsUnit(self.unit, 'target') then
		return false
	end

	--// We dont want to show target highlighting for these frames
	if self.unit == 'player' or strsub(self.unit, 1, 6) == 'target' then
		return false
	end

	return true
end

local function HighlightUpdate(self)
	local highlight = self.Highlight

	if not HighlightShouldShow(self) then
		if highlight then highlight:Hide() end
		return false
	end

	if not self.Highlight then

		--// Create the highlight
		local hl = CreateFrame('Frame', '$parentHighlight', self)
		hl:SetAllPoints(self)
		hl:SetFrameLevel(15)
		hl:Hide()

		local tex = hl:CreateTexture(nil, 'OVERLAY')
		tex:SetTexture(config.highlight.texture)
		tex:SetBlendMode('ADD')
		tex:SetAllPoints(hl)
		tex:SetVertexColor(unpack(config.highlight.color))
		tex:SetAlpha(config.highlight.alpha)

		self.Highlight = hl
		self.Highlight.tex = tex

	end

	self.Highlight:Show()

	return false
end

local function HighlightEnable(self)

	--// Mouseover Events
	self:HookScript('OnEnter', HighlightUpdate)
	self:HookScript('OnLeave', HighlightUpdate)

	--// Target Events
	self:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate)
	table.insert(self.__elements, HighlightUpdate)
end


--// Health and Power, mostly for setting color
local function PostUpdateHealth(Health, unit, min, max)
	local r,g,b,t

	--// Determin the color we want to use
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		t = colors.tapped
	elseif not UnitIsConnected(unit) then
		t = colors.disconnected
	else
		t = colors.health
	end

	if t then
		r, g, b = t[1], t[2], t[3]
	end

	if b then
		--// Set the health bar color
		Health:SetStatusBarColor(r, g, b)

		--// Set the background color
		Health.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)
	end
end

local function PostUpdatePower(Power, unit, min, max)
	local r,g,b,t

	--// Determin the color we want to use
	if UnitIsPlayer(unit) then
		local class = select(2, UnitClass(unit))
		t = colors.class[class]
	else
		local power = select(2, UnitPowerType(unit))
		t = colors.power[power]
	end

	if t then
		r, g, b = t[1], t[2], t[3]
	end

	if b then
		--// Set the power bar color
		Power:SetStatusBarColor(r, g, b)

		--// Set the background color
		Power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)
	end
end


--// Reputation bar update
local function ReputationPostUpdate(Reputation, unit, name, standing, min, max, value)
	local r,g,b = unpack(colors.reaction[standing])

	Reputation:SetStatusBarColor(r,g,b)
	Reputation.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)
end


--// Castbar Functions
local function PostCastStart(Castbar, unit, name, rank, castid)
	Castbar:SetAlpha(1.0)
	Castbar.Spark:Show()

	local r,g,b = unpack(colors.cast.normal)

	--// Set the Castbar color
	Castbar:SetStatusBarColor(r,g,b)

	--// Set the background color
	Castbar.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)
end

local function PostCastStop(Castbar, unit, name, rank, castid)
	Castbar:SetValue(Castbar.max)
	Castbar:Show()
end

local function PostChannelStop(Castbar, unit, name, rank, castid)
	Castbar:SetValue(0)
	Castbar:Show()
end

local function PostCastFailed(Castbar, unit, name, rank, castid)
	Castbar:SetValue(Castbar.max)
	Castbar:Show()

	local r,g,b = unpack(colors.cast.failed)

	--// Set the Castbar color
	Castbar:SetStatusBarColor(r,g,b)

	--// Set the background color
	Castbar.bg:SetVertexColor(r*0.4, g *0.4, b*0.4)
end

local function CastbarOnUpdate(Castbar, elapsed)
	if Castbar.casting or Castbar.channeling then
		local duration = Castbar.casting and Castbar.duration + elapsed or Castbar.duration - elapsed
		local remaining = (duration * -1 + Castbar.max) -- incase i want to use it :p
		if (Castbar.casting and duration >= Castbar.max) or (Castbar.channeling and duration <= 0) then
			Castbar.casting = nil
			Castbar.channeling = nil
			return
		end

		local latency = select(4, GetNetStats())

		if Castbar.SafeZone then
			local width = Castbar:GetWidth() * (latency / 1e3) / Castbar.max
			if width < 1 then width = 1 end
			if width > Castbar:GetWidth() then width = Castbar:GetWidth() end
			Castbar.SafeZone:SetWidth(width)
		end

		if Castbar.Lag then
			Castbar.Lag:SetFormattedText('%d ms', latency)
		end

		if Castbar.Time then
			if Castbar.delay ~= 0 then
				Castbar.Time:SetFormattedText('|cffff0000-%.1f|r %.1f | %.1f', Castbar.delay, duration, Castbar.max)
			else
				Castbar.Time:SetFormattedText('%.1f | %.1f', duration, Castbar.max)
			end
		end

		Castbar.duration = duration
		Castbar:SetValue(duration)
		if Castbar.Spark then
			Castbar.Spark:SetPoint('CENTER', Castbar, 'LEFT', (duration / Castbar.max) * Castbar:GetWidth(), 0)
		end
	else
		Castbar.Spark:Hide()
		local alpha = Castbar:GetAlpha() - 0.08
		if alpha > 0 then
			Castbar:SetAlpha(alpha)
		else
			Castbar:Hide()
		end

	end
end


--// Aura Function
local function PostCreateAuraIcon(iconframe, button)
	button.cd:SetReverse(true)
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	CreateBorder(button)
end

local function PostUpdateAuraIcon(iconframe, unit, button, index, offset)
	local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, button.filter)

	local playerUnits = { player = true, pet = true, vehicle = true }
	if playerUnits[caster] then
		button.icon:SetDesaturated(false)
	else
		button.icon:SetDesaturated(true)
	end

	if unit == 'player' or button.debuff then
		button:SetScript('OnMouseUp', function(self, mouseButton)
			if mouseButton ~= 'RightButton'
			or InCombatLockdown()
			then return end

			CancelUnitBuff(unit, index)
		end)
	end
end


--// Other Functions
local dropdown = CreateFrame("Frame", "ZoeyUnitDropDownMenu", UIParent, "UIDropDownMenuTemplate")

UIDropDownMenu_Initialize(dropdown, function(self)
	local unit = self:GetParent().unit
	if not unit then return end

	local menu, name, id
	if UnitIsUnit(unit, "player") then
		menu = "SELF"
	elseif UnitIsUnit(unit, "vehicle") then
		menu = "VEHICLE"
	elseif UnitIsUnit(unit, "pet") then
		menu = "PET"
	elseif UnitIsPlayer(unit) then
		id = UnitInRaid(unit)
		if id then
			menu = "RAID_PLAYER"
			name = GetRaidRosterInfo(id)
		elseif UnitInParty(unit) then
			menu = "PARTY"
		else
			menu = "PLAYER"
		end
	else
		menu = "TARGET"
		name = RAID_TARGET_ICON
	end
	if menu then
		UnitPopup_ShowMenu(self, menu, unit, name, id)
	end
end, "MENU")

local Menu = function(self)
	dropdown:SetParent(self)
	ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

ns.Mouse_Focus = nil
local function OnEnter(self)
	ns.Mouse_Focus = self
	UnitFrame_OnEnter(self)

	for _, fs in ipairs( self.__tags ) do fs:UpdateTag() end
end

local function OnLeave(self)
	ns.Mouse_Focus = nil
	UnitFrame_OnLeave(self)

	for _, fs in ipairs( self.__tags ) do fs:UpdateTag() end
end

local function BarOnHide(bar)
	local parent = bar:GetParent()
	parent:SetHeight(parent:GetHeight() - bar:GetHeight() - 1)
end

local function BarOnShow(bar)
	local parent = bar:GetParent()
	parent:SetHeight(parent:GetHeight() + bar:GetHeight() + 1)
end

local function CreateText(parent, size, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFont(config.font, size or 16)
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0,0,0,1)

	return fs
end

local function CreateStatusBar(parent, name)
	local sb = CreateFrame("StatusBar", (name and '$parent'..name or nil), parent)
	sb:SetStatusBarTexture(config.statusbar)

	sb.bg = sb:CreateTexture(nil, "BACKGROUND")
	sb.bg:SetTexture(config.statusbar)
	sb.bg:SetAllPoints(true)

	return sb
end

--//----------------------------
--// STYLE FUNCTION
--//----------------------------
oUF:RegisterStyle('Zoey', function(self, unit)

	--// Rightclick Menu
	self.menu = Menu
	self:RegisterForClicks('AnyUp')

	--// Hover Effects
	self:SetScript('OnEnter', OnEnter)
	self:SetScript('OnLeave', OnLeave)

	--// Range Fading
	self.SpellRange = {
		insideAlpha = 1,
		outsideAlpha = 0.5
	}

	--// Background
	local Background = self:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(self)
	Background:SetTexture(0, 0, 0, 1)

	--// Border
	CreateBorder(self)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
	table.insert(self.__elements, UpdateUnitBorderColor)

	--// Highlight
	HighlightEnable(self)

	-- // Frame Width. Height will be set after bars are created
	if unit == 'player' or unit == 'target' then
		self:SetWidth(285)
	else
		self:SetWidth(139)
	end

	--// Bar Position
	local offset = 1

	--//----------------------------
	--// Portrait
	--//----------------------------
	if unit == 'target' or unit == 'party' then
		self.Portrait = CreateFrame('PlayerModel', '$parentPortrait', self)
		self.Portrait:SetHeight(53)
		self.Portrait:SetPoint('TOP', 0, -offset)
		self.Portrait:SetPoint('LEFT', 1,0)
		self.Portrait:SetPoint('RIGHT',-1,0)

		--// Darken up the Portrait just a bit
		self.Portrait.Overlay = self.Portrait:CreateTexture(nil, 'OVERLAY')
		self.Portrait.Overlay:SetTexture(0,0,0,0.4)
		self.Portrait.Overlay:SetAllPoints(self.Portrait)

		--// Up The Offset Value
		offset = offset + self.Portrait:GetHeight() + 1
	end

	--//----------------------------
	--// Health Bar
	--//----------------------------
	self.Health = CreateStatusBar(self, 'HealthBar')
	self.Health:SetHeight(31)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.PostUpdate = PostUpdateHealth

	--// Up The Offset Value
	offset = offset + self.Health:GetHeight() + 1

	--//----------------------------
	--// Power Bar
	--//----------------------------
	self.Power = CreateStatusBar(self,'PowerBar')
	self.Power:SetHeight(5)
	self.Power:SetPoint('TOP', 0, -offset)
	self.Power:SetPoint('LEFT', 1,0)
	self.Power:SetPoint('RIGHT',-1,0)
	self.Power.PostUpdate = PostUpdatePower

	--// Up The Offset Value
	offset = offset + self.Power:GetHeight() + 1

	--//----------------------------
	--// Class Bars
	--//----------------------------
	if unit == 'player' then
		local playerClass = select(2, UnitClass('player'))

		--//----------------------------
		--// Death Knight Runes
		--//----------------------------
		if playerClass == 'DEATHKNIGHT' then

			self.Runes = CreateFrame('Frame', '$parentRunebar', self)
			self.Runes:SetHeight(5)
			self.Runes:SetPoint('TOP', 0, -offset)
			self.Runes:SetPoint('LEFT', 1,0)
			self.Runes:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 6) - ((6 - 1) / 6)

			for i = 1, 6 do
				local rune = CreateStatusBar(self.Runes, 'Rune'..i)
				rune:SetSize(width, self.Runes:GetHeight())
				rune.bg.multiplier = 0.4

				if i == 1 then
					rune:SetPoint('LEFT')
				else
					rune:SetPoint('LEFT', self.Runes[i-1], 'RIGHT', 1, 0)
				end

				self.Runes[i] = rune
			end

			--// Up The Offset Value
			offset = offset + self.Runes:GetHeight() + 1

		end

		--//----------------------------
		--// Druid Eclipse
		--//----------------------------
		if playerClass == 'DRUID' then



		end

		--//----------------------------
		--// Paladin Holy Power
		--//----------------------------
		if playerClass == 'PALADIN' then

			self.HolyPower = CreateFrame('Frame', '$parentHolyPowerBar', self)
			self.HolyPower:SetHeight(5)
			self.HolyPower:SetPoint('TOP', 0, -offset)
			self.HolyPower:SetPoint('LEFT', 1,0)
			self.HolyPower:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

			for i = 1, 3 do
				local power = self.HolyPower:CreateTexture(nil, 'ARTWORK')
				power:SetTexture(config.statusbar)
				power:SetSize(width, self.HolyPower:GetHeight())

				if i == 1 then
					power:SetPoint('LEFT', self.HolyPower, 0, 0)
				else
					power:SetPoint('LEFT', self.HolyPower[i-1], 'RIGHT', 1, 0)
				end

				power.bg = self.HolyPower:CreateTexture(nil, 'BACKGROUND')
				power.bg:SetTexture(config.statusbar)
				power.bg:SetAllPoints(power)

				-- // Color
				local r,g,b = unpack(colors.power.HOLY_POWER)

				power:SetVertexColor(r,g,b)
				power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.HolyPower[i] = power
			end

			--// Up The Offset Value
			offset = offset + self.HolyPower:GetHeight() + 1

		end

		--//----------------------------
		--// Shaman Totems
		--//----------------------------
		if playerClass == 'SHAMAN' then



		end

		--//----------------------------
		--// Warlock Soul Shards
		--//----------------------------
		if playerClass == 'WARLOCK' then

			self.SoulShards = CreateFrame('Frame', '$parentSoulShardsBar', self)
			self.SoulShards:SetHeight(5)
			self.SoulShards:SetPoint('TOP', 0, -offset)
			self.SoulShards:SetPoint('LEFT', 1,0)
			self.SoulShards:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

			for i = 1, 3 do
				local shard = self.SoulShards:CreateTexture(nil, 'ARTWORK')
				shard:SetTexture(config.statusbar)
				shard:SetSize(width, self.SoulShards:GetHeight())

				if i == 1 then
					shard:SetPoint('LEFT', self.SoulShards, 0, 0)
				else
					shard:SetPoint('LEFT', self.SoulShards[i-1], 'RIGHT', 1, 0)
				end

				shard.bg = self.SoulShards:CreateTexture(nil, 'BACKGROUND')
				shard.bg:SetTexture(config.statusbar)
				shard.bg:SetAllPoints(shard)

				-- // Color
				local r,g,b = unpack(colors.power.SOUL_SHARDS)

				shard:SetVertexColor(r,g,b)
				shard.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.SoulShards[i] = shard
			end

			--// Up The Offset Value
			offset = offset + self.SoulShards:GetHeight() + 1

		end

	elseif unit == 'target' then
		local playerClass = select(2, UnitClass('player'))

		--//----------------------------
		--// Combo Points
		--//----------------------------
		if playerClass == 'ROGUE' or playerClass == 'DRUID' then

			--// Combo points float above the healthbar
			--// so they can be hidden if the druid isnt in cat form

			self.CPoints = CreateFrame('Frame', '$parentCPointsFrame', self)
			self.CPoints:SetHeight(5)
			self.CPoints:SetPoint('BOTTOMLEFT', self.Health, 'TOPLEFT', 0, 1)
			self.CPoints:SetPoint('BOTTOMRIGHT', self.Health, 'TOPRIGHT', 0, 1)

			self.CPoints:SetFrameLevel(3) --// Push it above the portrait

			--// Background
			local Background = self.CPoints:CreateTexture(nil, 'BACKGROUND')
			Background:SetPoint('TOPLEFT', -1, 1)
			Background:SetPoint('BOTTOMRIGHT', 1, -1)
			Background:SetTexture(0, 0, 0, 1)

			local width = ((self:GetWidth() - 2) / 5) - ((5 - 1) / 5)

			for i = 1, 5 do
				local point = self.CPoints:CreateTexture(nil, 'ARTWORK')
				point:SetTexture(config.statusbar)
				point:SetSize(width, self.CPoints:GetHeight())

				if i == 1 then
					point:SetPoint('LEFT', self.CPoints, 0, 0)
				else
					point:SetPoint('LEFT', self.CPoints[i-1], 'RIGHT', 1, 0)
				end

				point.bg = self.CPoints:CreateTexture(nil, 'BACKGROUND')
				point.bg:SetTexture(config.statusbar)
				point.bg:SetAllPoints(point)

				-- // Color
				local r,g,b = unpack(colors.comboPoints.normal)

				point:SetVertexColor(r,g,b)
				point.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.CPoints[i] = point
			end

			--// Last combo point should be red, but not the bg
			self.CPoints[5]:SetVertexColor(unpack(colors.comboPoints.last))

			--// Toggle the frame when the Druid enters/leaves Cat Form
			if playerClass == 'DRUID' then
				local f = CreateFrame('Frame', nil, self)
				f:RegisterEvent('PLAYER_LOGIN')
				f:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
				f:SetScript('OnEvent', function()
					if GetShapeshiftFormID() == CAT_FORM then
						self.CPoints:Show()
					else
						self.CPoints:Hide()
					end
				end)
			end
		end
	end

	--//----------------------------
	--// Experience Bar
	--//----------------------------
	if unit == 'player' and IsAddOnLoaded('oUF_Experience') and UnitLevel(unit) ~= MAX_PLAYER_LEVEL then
		self.Experience = CreateStatusbar(self, 'Experience')
		self.Experience:SetHeight(5)
		self.Experience:SetPoint('TOP', 0, -offset)
		self.Experience:SetPoint('LEFT', 1,0)
		self.Experience:SetPoint('RIGHT',-1,0)

		self.Experience.Rested = CreateStatusBar(self.Experience, 'Rested')
		self.Experience.Rested:SetAllPoints(self.Experience)

		--// Resize the main frame when this frame Hides or Shows
		self.Experience:SetScript('OnShow', BarOnShow)
		self.Experience:SetScript('OnHide', BarOnHide)

		--// Main Color
		local r,g,b = unpack(colors.experience.main)

		self.Experience:SetStatusBarColor(r,g,b)
		self.Experience.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

		--// Rested Color
		self.Experience.Rested:SetStatusBarColor(unpack(colors.experience.rested))

		--// Up The Offset Value
		offset = offset + self.Experience:GetHeight() + 1
	end

	--//----------------------------
	--// Reputation Bar
	--//----------------------------
	if unit == 'player' and IsAddOnLoaded('oUF_Reputation') then
		self.Reputation = CreateStatusBar(self, 'Reputation')
		self.Reputation:SetHeight(5)
		self.Reputation:SetPoint('TOP', 0, -offset)
		self.Reputation:SetPoint('LEFT', 1,0)
		self.Reputation:SetPoint('RIGHT',-1,0)

		--// Resize the main frame when this frame Hides or Shows
		self.Reputation:SetScript('OnShow', BarOnShow)
		self.Reputation:SetScript('OnHide', BarOnHide)

		self.Reputation.PostUpdate = ReputationPostUpdate

		--// Up The Offset Value
		offset = offset + self.Reputation:GetHeight() + 1
	end


	--// Frame Height
	self:SetHeight(offset)

	--// Overlay Frame -- used to attach icons/text to
	local Overlay = CreateFrame('Frame', '$parentOverlay', self)
	Overlay:SetAllPoints(self)
	Overlay:SetFrameLevel(10)

	--//----------------------------
	--// Texts
	--//----------------------------
	--// Name Text
	local Name = CreateText(Overlay, 16)
	self:Tag(Name, '[Zoey:Level< ][Zoey:Name]')

	if unit == 'target' or unit == 'party' then
		Name:SetPoint('TOPLEFT', 3, -2)
		Name:SetPoint('TOPRIGHT', -3, -2)
	else
		Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
		Name:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)
	end

	--// Health Text
	if unit == 'target' then
		--[[
			Target uses two health texts to make the
			final 20% big and red for Execute and Kill Shot
		]]
		local HealthText = CreateText(Overlay, 22)
		self:Tag(HealthText, '[Zoey:TargetHealth]')
		HealthText:SetPoint('RIGHT', self.Health, -1, -1)

		local HealthText2 = CreateText(Overlay, 29)
		self:Tag(HealthText2, '[Zoey:TargetHealth2]')
		HealthText2:SetPoint('RIGHT', self.Health, -1, -1)
	else
		local HealthText = CreateText(Overlay, 22)
		self:Tag(HealthText, '[Zoey:Health]')
		HealthText:SetPoint('RIGHT', self.Health, -1, -1)
	end

	--// Power Text
	local PowerText = CreateText(Overlay, 12)
	self:Tag(PowerText, '[Zoey:Power]')
	PowerText:SetPoint('RIGHT', self.Power, -1, -1)

	-- // Guild and Realm Indicator
	if unit == 'target' or unit == 'party' then
		local GuildAndRealm = CreateText(Overlay, 12)

		if UnitInParty(unit) then
			self:Tag(GuildAndRealm, '[Zoey:RealmIndicator][Zoey:Guild]')
		else
			self:Tag(GuildAndRealm, '[Zoey:Guild]')
		end

		GuildAndRealm:SetPoint('TOP', Name, 'BOTTOM', 0, -1)
		GuildAndRealm:SetPoint('LEFT',  Name)
		GuildAndRealm:SetPoint('RIGHT', Name)
	end

	--// Experience Text
	if self.Experience then
		local Experience = CreateText(Overlay, 10)
		self:Tag(Experience, '[Zoey:Exp]')
		Experience:SetPoint('CENTER', self.Experience, 'BOTTOM', 0, -5)
	end

	--// Reputation Text
	if self.Reputation then
		local Reputation = CreateText(Overlay, 10, 'CENTER')
		self:Tag(Reputation, '[Zoey:Rep]')
		Reputation:SetPoint('CENTER', self.Reputation, 'BOTTOM', 0, -8)
	end

	--//----------------------------
	--// Icons
	--//----------------------------
	if unit == 'player' then
		--// Resting Icon
		self.Resting = Overlay:CreateTexture(nil, 'OVERLAY')
		self.Resting:SetSize(25,25)
		self.Resting:SetPoint('LEFT', Overlay, 'BOTTOMLEFT', 0, -2)

		--// Combat Icon
		self.Combat = Overlay:CreateTexture(nil, 'OVERLAY')
		self.Combat:SetSize(25,25)
		self.Combat:SetPoint('RIGHT', Overlay, 'BOTTOMRIGHT', 0, -2)
	end

	if unit == 'target' then
		--// Quest Mob Icon
		self.QuestIcon = Overlay:CreateTexture(nil, 'OVERLAY')
		self.QuestIcon:SetSize(32,32)
		self.QuestIcon:SetPoint('CENTER', Overlay, 'LEFT', 0, 0)
	end

	if unit == 'player' or unit == 'party' or unit == 'raid' then
		--// Ready Check icon
		self.ReadyCheck = Overlay:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheck:SetSize(20,20)
		self.ReadyCheck:SetPoint('CENTER', Overlay, 'CENTER', 0, 0)

	end

	--// LFD Role Icon
	self.LFDRole = Overlay:CreateTexture(nil, 'OVERLAY')
	self.LFDRole:SetSize(15,15)
	self.LFDRole:SetPoint('CENTER', Overlay, 'TOPRIGHT', 1, 0)

	--// Leader Icon
	self.Leader = Overlay:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetSize(15,15)
	self.Leader:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 3)

	--// Assistant Icon
	self.Assistant = Overlay:CreateTexture(nil, "OVERLAY")
	self.Assistant:SetSize(15,15)
	self.Assistant:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 3)

	--// Raid Icon (Skull, Cross, Square ...)
	self.RaidIcon = Overlay:CreateTexture(nil, 'OVERLAY')

	if unit == 'target' then
		self.RaidIcon:SetSize(30,30)
		self.RaidIcon:SetPoint('CENTER', Overlay, 'TOP', 0, 0)
	else
		self.RaidIcon:SetSize(23,23)
		self.RaidIcon:SetPoint('LEFT', Overlay, 3, 0)
	end

	--// PvP Icon -- The img used isnt perfect, it sucks
	self.PvP = Overlay:CreateTexture(nil, 'OVERLAY')
	self.PvP:SetSize(21,21)
	self.PvP:SetPoint('CENTER', Overlay, 'LEFT', 0,0)

	local faction = UnitFactionGroup(unit)
	if faction == 'Horde' then
		self.PvP:SetTexCoord(0.08, 0.58, 0.045, 0.545)
	elseif faction == 'Alliance' then
		self.PvP:SetTexCoord(0.07, 0.58, 0.06, 0.57)
	else
		self.PvP:SetTexCoord(0.05, 0.605, 0.015, 0.57)
	end

	--//----------------------------
	--// Cast Bars
	--//----------------------------
	if unit == 'player' or unit == 'target' then

		--// The Castbar its self
		self.Castbar = CreateStatusBar(self, '$parentCastbar')
		self.Castbar:SetSize(591,38)

		if unit == 'player' then
			self.Castbar:SetPoint('TOP', self, 'BOTTOM', 0, -39)
		elseif unit == 'target' then
			self.Castbar:SetPoint('BOTTOM', self, 'TOP', 0, 85)
		end

		--// Add a spark
		self.Castbar.Spark = self.Castbar:CreateTexture(nil, 'OVERLAY')
		self.Castbar.Spark:SetHeight(self.Castbar:GetHeight()*2.5)
		self.Castbar.Spark:SetBlendMode('ADD')
		self.Castbar.Spark:SetAlpha(0.5)

		--// Player only Latency
		if unit == 'player' then
			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.SafeZone:SetTexture(config.statusbar)
			self.Castbar.SafeZone:SetVertexColor(unpack(colors.cast.safezone))

			self.Castbar.Lag = CreateText(self.Castbar, 10)
			self.Castbar.Lag:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -7)
		end

		--// Castbar Texts
		self.Castbar.Text = CreateText(self.Castbar, 20)
		self.Castbar.Text:SetPoint('LEFT', 10, 0)

		self.Castbar.Time = CreateText(self.Castbar, 16)
		self.Castbar.Time:SetPoint('RIGHT', -10, 0)

		--// Castbar Function Hooks
		self.Castbar.OnUpdate = CastbarOnUpdate
		self.Castbar.PostCastStart = PostCastStart
		self.Castbar.PostChannelStart = PostCastStart
		self.Castbar.PostCastStop = PostCastStop
		self.Castbar.PostChannelStop = PostChannelStop
		self.Castbar.PostCastFailed = PostCastFailed
		self.Castbar.PostCastInterrupted = PostCastFailed

		--// Castbar Frame
		local CastbarFrame = CreateFrame('Frame', '$parentFrame', self.Castbar)
		CastbarFrame:SetPoint('TOPLEFT', -1, 1)
		CastbarFrame:SetPoint('BOTTOMRIGHT', 1, -1)
		CastbarFrame:SetFrameLevel(self.Castbar:GetFrameLevel()-1)

		--// Castbar Frame Border
		CreateBorder(CastbarFrame)
	end

	--//----------------------------
	--// Auras
	--//----------------------------
	if unit == 'player' or unit == 'target' then

		--// Buffs
		self.Buffs = CreateFrame('Frame', nil, self)

		self.Buffs:SetHeight(25)
		self.Buffs:SetPoint('LEFT', 0, 0)
		self.Buffs:SetPoint('RIGHT', 0, 0)

		self.Buffs['growth-x'] = 'RIGHT'
		self.Buffs['spacing'] = 7
		self.Buffs['size'] = 25
		self.Buffs['num'] = 9

		if unit == 'player' then
			self.Buffs:SetPoint('TOP', self, 'BOTTOM', 0, -7)
			self.Buffs['initialAnchor'] = 'TOPLEFT'
			self.Buffs['growth-y'] = 'DOWN'

		elseif unit == 'target' then
			self.Buffs:SetPoint('BOTTOM', self, 'TOP', 0, 7)
			self.Buffs['initialAnchor'] = 'BOTTOMLEFT'
			self.Buffs['growth-y'] = 'UP'
		end

		self.Buffs.CustomFilter   = ns.CustomAuraFilters[unit]
		self.Buffs.PostCreateIcon = PostCreateAuraIcon
		self.Buffs.PostUpdateIcon = PostUpdateAuraIcon
	end

	if unit == 'player' or unit == 'target' or unit == 'party' then

		--// Debuffs
		self.Debuffs = CreateFrame('Frame', nil, self)

		self.Debuffs['growth-x'] = 'RIGHT'
		self.Debuffs['growth-y'] = 'UP'
		self.Debuffs['spacing'] = 7
		self.Debuffs['size'] = 34

		if unit == 'player' or unit == 'party' then
			self.Debuffs:SetSize(139, 34)
			self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 13, 0)
			self.Debuffs['initialAnchor'] = 'LEFT'
			self.Debuffs['num'] = 4

		elseif unit == 'target' then
			self.Debuffs:SetSize(285,75)
			self.Debuffs:SetPoint('BOTTOM', self.Buffs, 'TOP', 0, 8)
			self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
			self.Debuffs['num'] = 14
		end

		self.Debuffs.CustomFilter   = ns.CustomAuraFilters[unit]
		self.Debuffs.PostCreateIcon = PostCreateAuraIcon
		self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
	end
end)

oUF:RegisterStyle('ZoeyThin', function(self, unit)

	--// Rightclick Menu
	self.menu = Menu
	self:RegisterForClicks('AnyUp')

	--// Hover Effects
	self:SetScript('OnEnter', OnEnter)
	self:SetScript('OnLeave', OnLeave)

	--// Range Fading
	self.SpellRange = {
		insideAlpha = 1,
		outsideAlpha = 0.3
	}

	--// Background
	local Background = self:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(self)
	Background:SetTexture(0, 0, 0, 1)

	--// Border
	CreateBorder(self)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
	table.insert(self.__elements, UpdateUnitBorderColor)

	--// Highlight
	HighlightEnable(self)

	-- // Frame Width. Height will be set after bars are created
	self:SetWidth(139)

	--// Bar Position
	local offset = 1

	--//----------------------------
	--// Health Bar
	--//----------------------------
	self.Health = CreateStatusBar(self, 'HealthBar')
	self.Health:SetHeight(17)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.PostUpdate = PostUpdateHealth

	--// Up The Offset Value
	offset = offset + self.Health:GetHeight() + 1

	--//----------------------------
	--// Frame Size
	--//----------------------------
	self:SetHeight(offset)

	--// Overlay Frame -- used to attach icons/text to
	local Overlay = CreateFrame('Frame', '$parentOverlay', self)
	Overlay:SetAllPoints(self)
	Overlay:SetFrameLevel(10)

	--//----------------------------
	--// Texts
	--//----------------------------
	--// Name Text
	local Name = CreateText(Overlay, 12)
	self:Tag(Name, '[Zoey:Level< ][Zoey:Name]')
	Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
	Name:SetPoint('RIGHT', self, 'TOPRIGHT', -3, 1)

	--// Status Text
	local StatusText = CreateText(Overlay, 16)
	self:Tag(StatusText, '[Zoey:Status]')
	StatusText:SetPoint('RIGHT', self.Health, -1, 0)

	--//----------------------------
	--// Icons
	--//----------------------------
	--// Leader Icon
	self.Leader = Overlay:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetSize(13,13)
	self.Leader:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 0)

	--// Assistant Icon
	self.Assistant = Overlay:CreateTexture(nil, "OVERLAY")
	self.Assistant:SetSize(13,13)
	self.Assistant:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 0)

	--// Ready Check icon
	self.ReadyCheck = Overlay:CreateTexture(nil, 'OVERLAY')
	self.ReadyCheck:SetSize(16,16)
	self.ReadyCheck:SetPoint('CENTER', Overlay, 'BOTTOM', 0, 0)

	--// Raid Icon (Skull, Cross, Square ...)
	self.RaidIcon = Overlay:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetSize(16,16)
	self.RaidIcon:SetPoint('CENTER', Overlay, 'LEFT', 0, 0)

	--// LFD Role Icon
	self.LFDRole = Overlay:CreateTexture(nil, 'OVERLAY')
	self.LFDRole:SetSize(13,13)
	self.LFDRole:SetPoint('CENTER', Overlay, 'TOPRIGHT', 0, 0)

end)

oUF:RegisterStyle('ZoeySquare', function(self, unit)

	--// Rightclick Menu
	self.menu = Menu
	self:RegisterForClicks('AnyUp')

	--// Hover Effects
	self:SetScript('OnEnter', OnEnter)
	self:SetScript('OnLeave', OnLeave)

	--// Range Fading
	self.SpellRange = {
		insideAlpha = 1,
		outsideAlpha = 0.3
	}

	--// Background
	local Background = self:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(self)
	Background:SetTexture(0, 0, 0, 1)

	--// Border
	CreateBorder(self)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateUnitBorderColor)
	table.insert(self.__elements, UpdateUnitBorderColor)

	--// Highlight
	HighlightEnable(self)

	-- // Frame Width. Height will be set after bars are created
	self:SetWidth(53)

	--// Bar Position
	local offset = 1

	--//----------------------------
	--// Health Bar
	--//----------------------------
	self.Health = CreateStatusBar(self, 'HealthBar')
	self.Health:SetHeight(25)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.PostUpdate = PostUpdateHealth

	--// Up The Offset Value
	offset = offset + self.Health:GetHeight() + 1

	--//----------------------------
	--// Power Bar
	--//----------------------------
	self.Power = CreateStatusBar(self, 'PowerBar')
	self.Power:SetHeight(5)
	self.Power:SetPoint('TOP', 0, -offset)
	self.Power:SetPoint('LEFT', 1,0)
	self.Power:SetPoint('RIGHT',-1,0)
	self.Power.PostUpdate = PostUpdatePower

	--// Up The Offset Value
	offset = offset + self.Power:GetHeight() + 1

	--//----------------------------
	--// Frame Size
	--//----------------------------
	self:SetHeight(offset)

	--// Overlay Frame -- used to attach icons/text to
	local Overlay = CreateFrame('Frame', '$parentOverlay', self)
	Overlay:SetAllPoints(self)
	Overlay:SetFrameLevel(10)

	--//----------------------------
	--// Texts
	--//----------------------------
	--// Name Text
	local Name = CreateText(Overlay, 10, 'center')
	self:Tag(Name, '[Zoey:Name]')
	Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 1, -1)
	Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -1, -1)

	--// Status Text
	local StatusText = CreateText(Overlay, 12, 'center')
	self:Tag(StatusText, '[Zoey:Status]')
	StatusText:SetPoint('BOTTOM',  self)

	--//----------------------------
	--// Icons
	--//----------------------------
	--// Leader Icon
	self.Leader = Overlay:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetSize(10,10)
	self.Leader:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 0)

	--// Ready Check icon
	self.ReadyCheck = Overlay:CreateTexture(nil, 'OVERLAY')
	self.ReadyCheck:SetSize(14, 14)
	self.ReadyCheck:SetPoint('CENTER', Overlay, 'BOTTOM', 0, 0)

	--// Raid Icon (Skull, Cross, Square ...)
	self.RaidIcon = Overlay:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetSize(16,16)
	self.RaidIcon:SetPoint('CENTER', Overlay, 'LEFT', 0, 0)

end)

--//----------------------------
--// SPAWN UNITS
--//----------------------------
local u = {}
local Spawn = function(unit)
	local object = oUF:Spawn(unit)
	u[unit:lower()] = object
	return object
end

oUF:Factory(function(self)

	local offset = 15

	--// Player
	Spawn('Player'				):SetPoint('TOP', UIParent, 'CENTER', 0, -302)

	--// Player Pet
	Spawn('Pet'					):SetPoint('TOPRIGHT', u.player, 'TOPLEFT', -offset, 0)
	Spawn('PetTarget'			):SetPoint('BOTTOM', u.pet, 'TOP', 0, offset)
	Spawn('PetTargetTarget'		):SetPoint('BOTTOM', u.pettarget, 'TOP', 0, offset)

	--// Targets
	Spawn('Target'				):SetPoint('BOTTOM', u.player, 'TOP', 0, offset)
	Spawn('TargetTarget'		):SetPoint('TOPLEFT', u.target, 'TOPRIGHT', offset, 0)
	Spawn('TargetTargetTarget'	):SetPoint('TOP', u.targettarget, 'BOTTOM', 0, -offset)

	--// Focus
	Spawn('Focus'				):SetPoint('TOPRIGHT', u.pet, 'TOPLEFT', -offset, 0)
	Spawn('FocusTarget'			):SetPoint('BOTTOM', u.focus, 'TOP', 0, offset)
	Spawn('FocusTargetTarget'	):SetPoint('BOTTOM', u.focustarget, 'TOP', 0, offset)

	--//----------------------------
	--// Party
	--//----------------------------
	self:SpawnHeader('oUF_ZoeyParty', nil, 'party',
		'showParty', true,
		'yOffset', 47,

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -341)

	--//----------------------------
	--// Party Targets
	--//----------------------------
	self:SpawnHeader('oUF_ZoeyPartyTargets', nil, 'party',
		'showParty', true,
		'yOffset', 101,
		'oUF-initialConfigFunction', [[
			self:SetAttribute('unitsuffix', 'target')
			self:SetWidth( 139 )
			self:SetHeight( 93 )
		]],

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 'BOTTOMRIGHT', 15, 0)

	--//----------------------------
	--// Party Pets
	--//----------------------------
	self:SetActiveStyle('ZoeyThin')
	self:SpawnHeader('oUF_ZoeyPartyPets', nil, 'party',
		'showParty', true,
		'yOffset', 121,
		'oUF-initialConfigFunction', [[
			self:SetAttribute('unitsuffix', 'pet')
			self:SetWidth( 139 )
			self:SetHeight( 19 )
		]],

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 0, -28)

end)

--//----------------------------
--// SPAWN RAIDS
--//----------------------------
oUF:Factory(function(self)

	--//----------------------------
	--// Raid Size 1 - 10
	--//----------------------------
	self:SetActiveStyle('Zoey')
	local Raid = {}
	for i = 1, 2 do
		local group = self:SpawnHeader('oUF_ZoeyRaid10_g'..i, nil,
			'custom [@raid11,exists] hide; [@raid1,exists] show; hide',

			'showRaid', true,
			'yOffset', 10.2,
			'groupFilter', tostring(i),

			'oUF-initialConfigFunction', [[
				self:SetWidth( 139 )
				self:SetHeight( 39 )
			]],

			'point', 'BOTTOM'
		)

		if i == 1 then
			group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -341)
		else
			group:SetPoint('BOTTOMLEFT', Raid[i - 1], 'BOTTOMRIGHT', 16, 0)
		end

		Raid[i] = group
	end


	--//----------------------------
	--// Raid Size 11 - 25
	--//----------------------------
	self:SetActiveStyle('ZoeyThin')
	local Raid = {}
	for i = 1, 5 do
		local group = self:SpawnHeader('oUF_ZoeyRaid25_g'..i, nil,
			'custom [@raid26,exists] hide; [@raid11,exists] show; hide ',

			'showRaid', true,
			'yOffset', 7.1,
			'groupFilter', tostring(i),
			'sortDir', 'DESC',

			'oUF-initialConfigFunction', [[
				self:SetWidth( 139 )
				self:SetHeight( 19 )
			]],

			'point', 'BOTTOM'
		)

		if i == 1 then
			group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -341)
		else
			group:SetPoint('BOTTOM', Raid[i - 1], 'TOP', 0, 15)
		end

		Raid[i] = group
	end

	--//----------------------------
	--// Raid Size 26 - 40
	--//----------------------------
	self:SetActiveStyle('ZoeySquare')
	local Raid = {}
	for i = 1, 8 do
		local group = self:SpawnHeader('oUF_ZoeyRaid40_g'..i, nil,
			'custom [@raid26,exists] show; hide',

			'showRaid', true,
			'xOffset', 10,
			'groupFilter', tostring(i),

			'oUF-initialConfigFunction', [[
				self:SetWidth( 53 )
				self:SetHeight( 33 )
			]],

			'point', 'LEFT'
		)

		if i == 1 then
			group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -341)
		else
			group:SetPoint('BOTTOMLEFT', Raid[i - 1], 'TOPLEFT', 0, 10)
		end

		Raid[i] = group
	end

end)

--//----------------------------
--// Extra Stuff for the UI
--//----------------------------
oUF:Factory(function(self)

	--// Hide the Blizzard Buffs
	BuffFrame:Hide()
	BuffFrame:UnregisterAllEvents()
	TemporaryEnchantFrame:Hide()
	ConsolidatedBuffs:Hide()

	--// Hide the Compact Raid Frame Manager and Container
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager.Show = CompactRaidFrameManager.Hide
	CompactRaidFrameManager:Hide()

	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer.Show = CompactRaidFrameContainer.Hide
	CompactRaidFrameContainer:Hide()

	--// Skin the Mirror Timers
	for i = 1, 3 do
		local barname = 'MirrorTimer' .. i
		local bar = _G[ barname ]

		for i, region in pairs( { bar:GetRegions() } ) do
			if region.GetTexture and region:GetTexture() == 'SolidTexture' then
				region:Hide()
			end
		end

		CreateBorder( bar )

		bar:SetParent( UIParent )
		bar:SetSize(285, 28)

		if i > 1 then
			local p1, p2, p3, p4, p5 = bar:GetPoint()
			bar:SetPoint(p1, p2, p3, p4, p5 - 15)
		end

		bar.bg = bar:GetRegions()
		bar.bg:ClearAllPoints()
		bar.bg:SetAllPoints( bar )
		bar.bg:SetTexture( config.statusbar )
		bar.bg:SetVertexColor( 0.2, 0.2, 0.2, 1 )

		bar.text = _G[ barname .. 'Text' ]
		bar.text:ClearAllPoints()
		bar.text:SetPoint( 'LEFT', bar, 4, 1 )
		bar.text:SetFont( config.font, 16)

		bar.border = _G[ barname .. 'Border' ]
		bar.border:Hide()

		bar.bar = _G[ barname .. 'StatusBar' ]
		bar.bar:SetPoint('TOPLEFT', bar, 1, -1)
		bar.bar:SetPoint('BOTTOMRIGHT', bar, -1, 1)
		bar.bar:SetStatusBarTexture( config.statusbar )
		bar.bar:SetAlpha( 0.8 )
	end

	--// Disable Blizzard options that are rendered useless by having this unit frame addon
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
		'FrameCategoriesButton11',
		'FrameCategoriesButton12',
	}) do
		_G['InterfaceOptions'..button]:SetAlpha(0.35)
		_G['InterfaceOptions'..button]:Disable()
		_G['InterfaceOptions'..button]:EnableMouse(false)
	end

	--// Remove Items from the Rightclick Menu
	for _, menu in pairs( UnitPopupMenus ) do
		for i = #menu, 1, -1 do
			local name = menu[ i ]
			if name == 'SET_FOCUS'
			or name == 'CLEAR_FOCUS'
			or name:match( '^LOCK_%u+_FRAME$' )
			or name:match( '^UNLOCK_%u+_FRAME$' )
			or name:match( '^MOVE_%u+_FRAME$' )
			or name:match( '^RESET_%u+_FRAME_POSITION' )
			then
				table.remove( menu, i )
			end
		end
	end


end)

--//----------------------------
--// THE END