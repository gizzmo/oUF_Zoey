--// Get the addon namespace
local addon, ns = ...

--//----------------------------
--// CONFIG
--//----------------------------
local config = {

	border = {
		texture = [[Interface\AddOns\oUF_Zoey\media\ThinSquare]],
		colors = {
			normal = {113/255, 113/255, 113/255},
			rare = {1, 1, 1},
			elite = {185/255, 185/255, 80/255},
			boss = {150/255, 80/255, 200/255}
		},
		size = 12,
		padding = 4
	},

	highlight = {
		texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
		color = {1,1,1, .2},
	},

	bars = {
		texture = [[Interface\AddOns\oUF_Zoey\media\Armory]],

		portrait = {
			height = 53
		},
		health = {
			height = 31,
			color = {89/255, 89/255, 89/255}
		},
		power = {
			height = 5
		},
		class = {
			height = 5
		},
		experience = {
			height = 5
		},
		cast = {
			size = {591, 38},
			colors = {
				normal = {89/255, 89/255, 89/255},
				success = {20/255, 208/255, 0/255},
				failed = {255/255, 12/255, 0/255},
				safezone = {255/255, 25/255, 0/255, 0.5}
			}
		}
	},

	font = [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]],

	aura = {
		texture = [[Interface\AddOns\oUF_Zoey\media\AuraBorder]],
		rules = {
			my_buffs = {		friend = 'caster',	enemy = 'type'},
			my_debuffs = {		friend = 'type',	enemy = 'caster'},
			other_buffs = {		friend = 'caster',	enemy = 'type'},
			other_debuffs = {	friend = 'type',	enemy = 'caster'},
		},
		colors = {
			caster = {
				my = {0, 1, 0, 1},
				other = {1, 0, 0, 1}
			},
			type = {
				Poison = {0, 1, 0, 1},
				Magic = {0, 0, 1, 1},
				Disease = {.55, .15, 0, 1},
				Curse = {5, 0, 5, 1},
				Enrage = {1, .55, 0, 1},
				['nil'] = {1, 0, 0, 1}
			},
		}
	}
}

--//----------------------------
--// FUNCTIONS
--//----------------------------

--// Mouse hovering
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

local function Menu(self)
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



--// Border Creation
local function CreateBorder(self)

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
		tex:SetAlpha(0.5)
		tex:SetAllPoints(hl)
		tex:SetVertexColor(unpack(config.highlight.color))

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
		t = oUF.colors.tapped
	elseif not UnitIsConnected(unit) then
		t = oUF.colors.disconnected
	else
		t = config.bars.health.color
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
		t = oUF.colors.class[class]
	else
		local power = select(2, UnitPowerType(unit))
		t = oUF.colors.power[power]
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


--// Experience bar functions
local function PostUpdateExperience(Experience, unit)
	if not Experience:IsShown() then
		local parent = Experience:GetParent()
		local ExperienceHeight = Experience:GetHeight()

		parent:SetHeight(parent:GetHeight() - ExperienceHeight - 1)
	end
end


--// Castbar Functions
local function OnCastSent(self, event, unit, spell, rank, target)
	if self.unit ~= unit then return end
	self.Castbar.sentTime = GetTime()
end

local function PostCastStart(Castbar, unit, name, rank, castid)
	Castbar:SetAlpha(1.0)
	Castbar.Spark:Show()
	Castbar:SetStatusBarColor(unpack(config.bars.cast.colors.normal))

	if (Castbar.sentTime) then
		Castbar.latency = GetTime() - Castbar.sentTime
	else
		Castbar.latency = 0
	end
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
end

local function CastbarOnUpdate(Castbar, elapsed)
	if Castbar.casting or Castbar.channeling then
		local duration = Castbar.casting and Castbar.duration + elapsed or Castbar.duration - elapsed
		local remaining = (duration - (duration *2) + Castbar.max) -- incase i want to use it :p
		if (Castbar.casting and duration >= Castbar.max) or (Castbar.channeling and duration <= 0) then
			Castbar.casting = nil
			Castbar.channeling = nil
			return
		end

		if Castbar.SafeZone then
			local width = Castbar:GetWidth() * Castbar.latency / Castbar.max
			if (width < 1) then width = 1 end
			Castbar.SafeZone:SetWidth(width);
		end

		if Castbar.Lag then
			Castbar.Lag:SetFormattedText('%d ms', Castbar.latency * 1000)
		end

		if(Castbar.Time) then
			if Castbar.delay ~= 0 then
				Castbar.Time:SetFormattedText('|cffff0000-%.1f|r %.1f | %.1f', Castbar.delay, duration, Castbar.max)
			else
				Castbar.Time:SetFormattedText('%.1f | %.1f', duration, Castbar.max)
			end
		end

		Castbar.duration = duration
		Castbar:SetValue(duration)
		if(Castbar.Spark) then
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

	button.border = button:CreateTexture(nil, 'OVERLAY')
	button.border:SetTexture(config.aura.texture)
	button.border:SetAllPoints(button)
end

local function PostUpdateAuraIcon(iconframe, unit, button, index, offset)
	local name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, button.filter)

	local border = button.border
	border:Show()

	local is_mine = caster == 'player' or caster == 'pet'
	local who = is_mine and 'my' or 'other'

	local rule = who .. '_' .. (iconframe.isDebuff and 'debuffs' or 'buffs')

	local is_friend = UnitIsFriend('player', unit)
	local color_type  = config.aura.rules[rule][is_friend and 'friend' or 'enemy']

	if color_type == 'type' then
		local color = config.aura.colors.type[tostring(dtype)]
		if not color then color = config.aura.colors.type['nil'] end
		border:SetVertexColor(unpack(color))
	elseif color_type == 'caster' then
		border:SetVertexColor(unpack(config.aura.colors.caster[who]))
	else
		-- Unknown color type just set it to red,
		-- shouldn't actually ever get to this code
		border:SetVertexColor(1,0,0)
	end
end



--// Other Functions
local function CreateText(parent, size, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFont(config.font, size or 16)
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0,0,0,1)

	return fs
end

local function StyleHeader(self)

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

end

--//----------------------------
--// STYLE FUNCTION
--//----------------------------
oUF:RegisterStyle('Zoey', function(self, unit)

	-- // Style Header
	StyleHeader(self)

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
		self.Portrait:SetHeight(config.bars.portrait.height)
		self.Portrait:SetPoint('TOP', 0, -offset)
		self.Portrait:SetPoint('LEFT', 1,0)
		self.Portrait:SetPoint('RIGHT',-1,0)

		--// offset the health bar's position
		offset = offset + self.Portrait:GetHeight() +1
	end

	--//----------------------------
	--// Combo Points
	--//----------------------------
	if unit == 'target' then
		local playerClass = select(2, UnitClass('player'))

		if playerClass == 'ROGUE' then

			self.CPoints = CreateFrame('Frame', '$parentCPointsFrame', self)
			self.CPoints:SetHeight(config.bars.class.height)
			self.CPoints:SetPoint('TOP', 0, -offset)
			self.CPoints:SetPoint('LEFT', 1,0)
			self.CPoints:SetPoint('RIGHT', -1,0)

			local width = (self:GetWidth() / 5) - ((5 - 1) / 5)

			for i = 1, 5 do
				local point = self.CPoints:CreateTexture(nil, 'ARTWORK')
				point:SetTexture(config.bars.texture)
				point:SetSize(width, self.CPoints:GetHeight())

				if (i == 1) then
					point:SetPoint('LEFT', self.CPoints, 0, 0)
				else
					point:SetPoint('LEFT', self.CPoints[i-1], 'RIGHT', 1, 0)
				end

				point.bg = self.CPoints:CreateTexture(nil, 'BACKGROUND')
				point.bg:SetTexture(config.bars.texture)
				point.bg:SetAllPoints(point)

				-- // Color
				local r,g,b = 232/255, 214/255, 12/255

				point:SetVertexColor(r,g,b)
				point.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.CPoints[i] = point
			end

			--// Last combo point should be red, but not the bg
			self.CPoints[5]:SetVertexColor(240/255, 60/255, 60/255)

			--// offset the health bar's position
			offset = offset + self.CPoints:GetHeight() + 1

		end
	end

	--//----------------------------
	--// Health Bar
	--//----------------------------
	self.Health = CreateFrame('StatusBar', '$parentHealthBar', self)
	self.Health:SetStatusBarTexture(config.bars.texture)
	self.Health:SetHeight(config.bars.health.height)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.frequentUpdates = .2
	self.Health.PostUpdate = PostUpdateHealth

	--// Healthbar Background
	self.Health.bg = self.Health:CreateTexture(nil, 'BACKGROUND')
	self.Health.bg:SetTexture(config.bars.texture)
	self.Health.bg:SetAllPoints(self.Health)

	--// offset the power bar's position
	offset = offset + self.Health:GetHeight() + 1

	--//----------------------------
	--// Power Bar
	--//----------------------------
	self.Power = CreateFrame('StatusBar', '$parentPowerBar', self)
	self.Power:SetStatusBarTexture(config.bars.texture)
	self.Power:SetHeight(config.bars.power.height)
	self.Power:SetPoint('TOP', 0, -offset)
	self.Power:SetPoint('LEFT', 1,0)
	self.Power:SetPoint('RIGHT',-1,0)
	self.Power.frequentUpdates = .2
	self.Power.PostUpdate = PostUpdatePower

	--// Powerbar Background
	self.Power.bg = self.Power:CreateTexture(nil, 'BACKGROUND')
	self.Power.bg:SetTexture(config.bars.texture)
	self.Power.bg:SetAllPoints(self.Power)

	--// Offset the class bars' position
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
			self.Runes:SetHeight(config.bars.class.height)
			self.Runes:SetPoint('TOP', 0, -offset)
			self.Runes:SetPoint('LEFT', 1,0)
			self.Runes:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 6) - ((6 - 1) / 6)

			for i = 1, 6 do
				local rune = CreateFrame('StatusBar', '$parentRune'..i, self.Runes)
				rune:SetStatusBarTexture(config.bars.texture)
				rune:SetSize(width, self.Runes:GetHeight())

				if i == 1 then
					rune:SetPoint('LEFT')
				else
					rune:SetPoint('LEFT', self.Runes[i-1], 'RIGHT', 1, 0)
				end

				rune.bg = rune:CreateTexture(nil, 'BACKGROUND')
				rune.bg:SetTexture(config.bars.texture)
				rune.bg:SetAllPoints(rune)
				rune.bg.multiplier = 0.4

				self.Runes[i] = rune
			end

			-- // Offset the next class bar? Or Frame Height
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
			self.HolyPower:SetHeight(config.bars.class.height)
			self.HolyPower:SetPoint('TOP', 0, -offset)
			self.HolyPower:SetPoint('LEFT', 1,0)
			self.HolyPower:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

			for i = 1, 3 do
				local power = self.HolyPower:CreateTexture(nil, 'ARTWORK')
				power:SetTexture(config.bars.texture)
				power:SetSize(width, self.HolyPower:GetHeight())

				if (i == 1) then
					power:SetPoint('LEFT', self.HolyPower, 0, 0)
				else
					power:SetPoint('LEFT', self.HolyPower[i-1], 'RIGHT', 1, 0)
				end

				power.bg = self.HolyPower:CreateTexture(nil, 'BACKGROUND')
				power.bg:SetTexture(config.bars.texture)
				power.bg:SetAllPoints(power)

				-- // Color
				local r,g,b = 230/255, 242/255, 84/255

				power:SetVertexColor(r,g,b)
				power.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.HolyPower[i] = power
			end

			-- // Offset the next class bar? Or Frame Height
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
			self.SoulShards:SetHeight(config.bars.class.height)
			self.SoulShards:SetPoint('TOP', 0, -offset)
			self.SoulShards:SetPoint('LEFT', 1,0)
			self.SoulShards:SetPoint('RIGHT', -1,0)

			local width = ((self:GetWidth() - 2) / 3) - ((3 - 1) / 3)

			for i = 1, 3 do
				local shard = self.SoulShards:CreateTexture(nil, 'ARTWORK')
				shard:SetTexture(config.bars.texture)
				shard:SetSize(width, self.SoulShards:GetHeight())

				if (i == 1) then
					shard:SetPoint('LEFT', self.SoulShards, 0, 0)
				else
					shard:SetPoint('LEFT', self.SoulShards[i-1], 'RIGHT', 1, 0)
				end

				shard.bg = self.SoulShards:CreateTexture(nil, 'BACKGROUND')
				shard.bg:SetTexture(config.bars.texture)
				shard.bg:SetAllPoints(shard)

				-- // Color
				local r,g,b = 209/255, 61/255, 189/255

				shard:SetVertexColor(r,g,b)
				shard.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

				self.SoulShards[i] = shard
			end

			-- // Offset the next class bar? Or Frame Height
			offset = offset + self.SoulShards:GetHeight() + 1

		end

	end

	--//----------------------------
	--// Experience Bar
	--//----------------------------
	if unit == 'player' and IsAddOnLoaded('oUF_Experience') and UnitLevel(unit) ~= MAX_PLAYER_LEVEL then
		self.Experience = CreateFrame('Statusbar', '$parentExperience', self)
		self.Experience:SetStatusBarTexture(config.bars.texture)
		self.Experience:SetHeight(config.bars.experience.height)
		self.Experience:SetPoint('TOP', 0, -offset)
		self.Experience:SetPoint('LEFT', 1,0)
		self.Experience:SetPoint('RIGHT',-1,0)

		self.Experience.Rested = CreateFrame('StatusBar', '$parentRested', self.Experience)
		self.Experience.Rested:SetStatusBarTexture(config.bars.texture)
		self.Experience.Rested:SetAllPoints(self.Experience)

		self.Experience.bg = self.Experience.Rested:CreateTexture(nil, 'BACKGROUND')
		self.Experience.bg:SetAllPoints(self.Experience)
		self.Experience.bg:SetTexture(config.bars.texture)

		self.Experience.PostUpdate = PostUpdateExperience

		--// Main Color
		local r,g,b = 200/255, 0, 200/255

		self.Experience:SetStatusBarColor(r,g,b)
		self.Experience.bg:SetVertexColor(r*0.4, g*0.4, b*0.4)

		--// Rested Color
		self.Experience.Rested:SetStatusBarColor(60/255, 60/255, 255/255)

		offset = offset + self.Experience:GetHeight() + 1
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
	self:Tag(Name, '[Zoey:Name]')

	if unit == 'target' or unit == 'party' then
		Name:SetPoint('TOPLEFT', 3, -2)
	else
		Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)
	end

	--// Health Text
	local HealthText = CreateText(Overlay, 22)
	self:Tag(HealthText, '[Zoey:Health]')
	HealthText:SetPoint('RIGHT', self.Health, -1, -1)

	--// Power Text
	local PowerText = CreateText(Overlay, 12)
	self:Tag(PowerText, '[Zoey:Power]')
	PowerText:SetPoint('RIGHT', self.Power, -1, -1)

	--// Experience Text
	if self.Experience then
		local Experience = CreateText(Overlay, 10)
		self:Tag(Experience, '[Zoey:Exp]')
		Experience:SetPoint('CENTER', self.Experience, 'BOTTOM', 0, -5)
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

	if unit == 'party' or unit == 'target' or unit == 'focus' then
		--// Phase Icon
		self.PhaseIcon = Overlay:CreateTexture( nil, 'OVERLAY' )
		self.PhaseIcon:SetPoint( 'CENTER', self, 0, 0)
		self.PhaseIcon:SetSize( 50, 50 )
		self.PhaseIcon:SetTexture( [[Interface\Icons\Spell_Frost_Stun]] )
		self.PhaseIcon:SetTexCoord( 0.06, 0.94, 0.06 , 0.94 )
		self.PhaseIcon:SetDesaturated( true )
		self.PhaseIcon:SetBlendMode( 'ADD' )
	end

	if unit == 'player' or unit == 'party' then
		--// LFD Role Icon
		self.LFDRole = Overlay:CreateTexture(nil, 'OVERLAY')
		self.LFDRole:SetSize(18,18)
		self.LFDRole:SetPoint('CENTER', Overlay, 'TOPLEFT', 1, 0)

		--// Ready Check icon
		self.ReadyCheck = Overlay:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheck:SetSize(14, 14)
		self.ReadyCheck:SetPoint('CENTER', Overlay, 'BOTTOM', 0, 0)
	end

	--// Leader Icon
	self.Leader = Overlay:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetSize(16,16)
	self.Leader:SetPoint('CENTER', Overlay, 'TOPLEFT', 0, 0)

	--// Raid Icon (Skull, Cross, Square ...)
	self.RaidIcon = Overlay:CreateTexture(nil, 'OVERLAY')

	if unit == 'target' then
		self.RaidIcon:SetSize(30,30)
		self.RaidIcon:SetPoint('CENTER', Overlay, 'TOP', 0, 0)
	else
		self.RaidIcon:SetSize(21,21)
		self.RaidIcon:SetPoint('CENTER', Overlay, 'LEFT', 0, 0)
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
		self.Castbar = CreateFrame('StatusBar', '$parentCastbar', self)
		self.Castbar:SetStatusBarTexture(config.bars.texture)
		self.Castbar:SetStatusBarColor(unpack(config.bars.cast.colors.normal))

		self.Castbar:SetSize(unpack(config.bars.cast.size))

		if unit == 'player' then
			self.Castbar:SetPoint('TOP', oUF.units.player, 'BOTTOM', 0, -76)
		elseif unit == 'target' then
			self.Castbar:SetPoint('BOTTOM', oUF.units.target, 'TOP', 0, 76)
		end

		--// Add a spark
		self.Castbar.Spark = self.Castbar:CreateTexture(nil, 'OVERLAY')
		self.Castbar.Spark:SetHeight(self.Castbar:GetHeight()*2.5)
		self.Castbar.Spark:SetBlendMode('ADD')
		self.Castbar.Spark:SetAlpha(0.5)

		--// Player only Latency
		if unit == 'player' then
			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.SafeZone:SetTexture(config.bars.texture)
			self.Castbar.SafeZone:SetVertexColor(unpack(config.bars.cast.colors.safezone))

			self.Castbar.Lag = CreateText(self.Castbar, 10)
			self.Castbar.Lag:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -7)

			self:RegisterEvent('UNIT_SPELLCAST_SENT', OnCastSent)
		end

		--// Castbar Texts
		self.Castbar.Text = CreateText(self.Castbar, 20)
		self.Castbar.Text:SetPoint('LEFT', 10, 0)

		self.Castbar.Time = CreateText(self.Castbar, 16)
		self.Castbar.Time:SetPoint('RIGHT', -10, 0)


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

		--// Castbar Frame Background
		local CastbarFrameBackground = CastbarFrame:CreateTexture(nil, 'BACKGROUND')
		CastbarFrameBackground:SetAllPoints(CastbarFrame)
		CastbarFrameBackground:SetTexture(config.bars.texture)
		CastbarFrameBackground:SetVertexColor(25/255, 25/255, 25/255)

		--// Castbar Frame Border
		CreateBorder(CastbarFrame)
	end

	--//----------------------------
	--// Auras
	--//----------------------------
	if unit == 'player' or unit == 'target' then

		--// Buffs
		self.Buffs = CreateFrame('Frame', nil, self)

		if unit == 'player' then
			self.Buffs:SetSize(285, 64)
			self.Buffs:SetPoint('TOP', self, 'BOTTOM', 0, -7)

			self.Buffs['initialAnchor'] = 'TOPLEFT'
			self.Buffs['growth-x'] = 'RIGHT'
			self.Buffs['growth-y'] = 'DOWN'
			self.Buffs['num'] = 18

		elseif unit == 'target' then
			self.Buffs:SetSize(285, 26)
			self.Buffs:SetPoint('BOTTOM', self, 'TOP', 0, 7)

			self.Buffs['initialAnchor'] = 'BOTTOMLEFT'
			self.Buffs['growth-x'] = 'RIGHT'
			self.Buffs['growth-y'] = 'UP'
			self.Buffs['num'] = 9
		end

		self.Buffs['spacing'] = 2
		self.Buffs['size'] = 30

		self.Buffs.CustomFilter   = ns.CustomAuraFilters[unit]
		self.Buffs.PostCreateIcon = PostCreateAuraIcon
		self.Buffs.PostUpdateIcon = PostUpdateAuraIcon

		--// Debuffs
		self.Debuffs = CreateFrame('Frame', nil, self)

		if unit == 'player' then
			self.Debuffs:SetSize(139, 38)
			self.Debuffs:SetPoint('LEFT', self, 'RIGHT', 13, 0)

			self.Debuffs['initialAnchor'] = 'TOPLEFT'
			self.Debuffs['growth-x'] = 'RIGHT'
			self.Debuffs['growth-y'] = 'DOWN'
			self.Debuffs['num'] = 4

		elseif unit == 'target' then
			self.Debuffs:SetSize(285, 100)
			self.Debuffs:SetPoint('BOTTOM', self.Buffs, 'TOP', 0, 8)

			self.Debuffs['initialAnchor'] = 'BOTTOMLEFT'
			self.Debuffs['growth-x'] = 'RIGHT'
			self.Debuffs['growth-y'] = 'UP'
			self.Debuffs['num'] = 16
		end

		self.Debuffs['spacing'] = 2
		self.Debuffs['size'] = 34

		self.Debuffs.CustomFilter   = ns.CustomAuraFilters[unit]
		self.Debuffs.PostCreateIcon = PostCreateAuraIcon
		self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
	end

	if unit == 'party' then
		--// Debuffs
		self.Debuffs = CreateFrame('Frame', nil, self)
		self.Debuffs:SetSize(139, 38)
		self.Debuffs:SetPoint('TOPLEFT', self, 'TOPRIGHT', 13, 0)

		self.Debuffs['initialAnchor'] = 'TOPLEFT'
		self.Debuffs['growth-x'] = 'RIGHT'
		self.Debuffs['growth-y'] = 'DOWN'
		self.Debuffs['num'] = 4
		self.Debuffs['spacing'] = 2
		self.Debuffs['size'] = 34

		self.Debuffs.CustomFilter   = ns.CustomAuraFilters[unit]
		self.Debuffs.PostCreateIcon = PostCreateAuraIcon
		self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
	end

end)

oUF:RegisterStyle('ZoeyThin', function(self, unit)

	--// StyleHeader
	StyleHeader(self)

	-- // Frame Width. Height will be set after bars are created
	self:SetWidth(139)

	--// Bar Position
	local offset = 1

	--//----------------------------
	--// Health Bar
	--//----------------------------
	self.Health = CreateFrame('StatusBar', '$parentHealthBar', self)
	self.Health:SetStatusBarTexture(config.bars.texture)
	self.Health:SetHeight(17)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.frequentUpdates = .2
	self.Health.PostUpdate = PostUpdateHealth

	--// Healthbar Background
	self.Health.bg = self.Health:CreateTexture(nil, 'BACKGROUND')
	self.Health.bg:SetTexture(config.bars.texture)
	self.Health.bg:SetAllPoints(self.Health)

	--// Offset the Power bar, or this is the frame height
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
	local Name = CreateText(Overlay, 16)
	self:Tag(Name, '[Zoey:Name]')
	Name:SetPoint('LEFT', self, 'TOPLEFT', 3, 1)

	--// Status Text
	local StatusText = CreateText(Overlay, 16)
	self:Tag(StatusText, '[Zoey:Status]')
	StatusText:SetPoint('RIGHT', self.Health, -1, 0)

end)

--//----------------------------
--// SPAWN UNITS
--//----------------------------
oUF:Factory(function(self)

	local u = self.units
	local offset = 15

	--// Player
	self:Spawn('Player'				):SetPoint('TOP', UIParent, 'CENTER', 0, -302)

	--// Player Pet
	self:Spawn('Pet'				):SetPoint('TOPRIGHT', u.player, 'TOPLEFT', -offset, 0)
	self:Spawn('PetTarget'			):SetPoint('BOTTOM', u.pet, 'TOP', 0, offset)
	self:Spawn('PetTargetTarget'	):SetPoint('BOTTOM', u.pettarget, 'TOP', 0, offset)

	--// Targets
	self:Spawn('Target'				):SetPoint('BOTTOM', u.player, 'TOP', 0, offset)
	self:Spawn('TargetTarget'		):SetPoint('TOPLEFT', u.target, 'TOPRIGHT', offset, 0)
	self:Spawn('TargetTargetTarget'	):SetPoint('TOP', u.targettarget, 'BOTTOM', 0, -offset)

	--// Focus
	self:Spawn('Focus'				):SetPoint('TOPRIGHT', u.pet, 'TOPLEFT', -offset, 0)
	self:Spawn('FocusTarget'		):SetPoint('BOTTOM', u.focus, 'TOP', 0, offset)
	self:Spawn('FocusTargetTarget'	):SetPoint('BOTTOM', u.focustarget, 'TOP', 0, offset)

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
		'yOffset', 107,
		'oUF-initialConfigFunction', [[
			self:SetAttribute('unitsuffix', 'target')
		]],

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 'BOTTOMRIGHT', 15, 0)

	--//----------------------------
	--// Party Pets
	--//----------------------------
	self:SetActiveStyle('ZoeyThin')
	self:SpawnHeader('oUF_ZoeyPartyPets', nil, 'party',
		'showParty', true,
		'yOffset', 127,
		'oUF-initialConfigFunction', [[
			self:SetAttribute('unitsuffix', 'pet')
		]],

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 0, -31)


	--//----------------------------
	--// Raid Groups
	--//----------------------------
	local Raid = {}
	for i = 1, 5 do
		local group = oUF:SpawnHeader('oUF_ZoeyRaidGroup'..i, nil, 'raid',
			'showRaid', true,
			'yOffset', 7,
			'groupFilter', tostring(i),
			'sortDir', 'DESC',
			'point', 'BOTTOM'
		)

		if i == 1 then
			group:SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -341)
		else
			group:SetPoint('BOTTOM', Raid[i - 1], 'TOP', 0, 15)
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

		if (i > 1) then
			local p1, p2, p3, p4, p5 = bar:GetPoint()
			bar:SetPoint(p1, p2, p3, p4, p5 - 15)
		end

		bar.bg = bar:GetRegions()
		bar.bg:ClearAllPoints()
		bar.bg:SetAllPoints( bar )
		bar.bg:SetTexture( config.bars.texture )
		bar.bg:SetVertexColor( 0.2, 0.2, 0.2, 1 )

		bar.text = _G[ barname .. 'Text' ]
		bar.text:ClearAllPoints()
		bar.text:SetPoint( 'LEFT', bar, 4, 1 )
		bar.text:SetFont( config.font, 16)

		bar.border = _G[ barname .. 'Border' ]
		bar.border:Hide()

		bar.bar = _G[ barname .. 'StatusBar' ]
		bar.bar:SetAllPoints( bar )
		bar.bar:SetStatusBarTexture( config.bars.texture )
		bar.bar:SetAlpha( 0.8 )
	end

	--// Disable Blizzard options that are rendered useless by having this unit frame addon
	for _, button in pairs({
		'UnitFramePanelPartyBackground',
		'UnitFramePanelPartyPets',
		'UnitFramePanelFullSizeFocusFrame',
		'UnitFramePanelRaidStylePartyFrames',

		'CombatPanelTargetOfTarget',
		'CombatPanelTOTDropDown',
		'CombatPanelTOTDropDownButton',
		'CombatPanelEnemyCastBarsOnPortrait',

		'DisplayPanelShowAggroPercentage',

		'FrameCategoriesButton9',
		'FrameCategoriesButton12',
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


end)

--//----------------------------
--// THE END