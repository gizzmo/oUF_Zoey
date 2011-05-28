--// Get the addon namespace
local addon, ns = ...

-----------------------------
--// CONFIG
-----------------------------
local config = {
	statusbar_texture = [[Interface\AddOns\oUF_Zoey\media\Armory]],

	healthbar_color = {89/255, 89/255, 89/255},

	castbar_colors = {
		normal = {89/255, 89/255, 89/255},
		success = {20/255, 208/255, 0/255},
		failed = {255/255, 12/255, 0/255}
	},

	portrait_size = 59,
	healthbar_size = 31,
	powerbar_size = 5,
	bar_spacing = 1,

	border_texture = [[Interface\AddOns\oUF_Zoey\media\ThinSquare]],
	border_colors = {
		normal = {113/255, 113/255, 113/255},
		rare = {1, 1, 1},
		elite = {1, 1, 0},
		boss = {1, .5, 1}
	},
	border_size = 12,
	border_padding = 4,

	font = [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]],

	highlight_texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
	highlight_color = {1,1,1, 60/255},

	auraborder_texture = [[Interface\AddOns\oUF_Zoey\media\AuraBorder]],
}

local Auras = {
	rules = {
		my_buffs = {
			friend = 'caster',
			enemy = 'type',
		},
		my_debuffs = {
			friend = 'type',
			enemy = 'caster',
		},
		other_buffs = {
			friend = 'caster',
			enemy = 'type',
		},
		other_debuffs = {
			friend = 'type',
			enemy = 'caster',
		},
	},
	colors = {
		caster = {
			my = {0, 1, 0, 1},
			other = {1, 0, 0, 1},
		},
		type = {
			Poison = {0, 1, 0, 1},
			Magic = {0, 0, 1, 1},
			Disease = {.55, .15, 0, 1},
			Curse = {5, 0, 5, 1},
			Enrage = {1, .55, 0, 1},
			["nil"] = {1, 0, 0, 1},
		},
	}
}

-----------------------------
--// FUNCTIONS
-----------------------------

--// Mouse hovering
ns.Mouse_Focus = nil
local function OnEnter(self)
	ns.Mouse_Focus = self
	UnitFrame_OnEnter(self)
end
local function OnLeave(self)
	ns.Mouse_Focus = nil
	UnitFrame_OnLeave(self)
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

	local size = config.border_size
	local padding = config.border_padding
	local texture = config.border_texture
	local color = config.border_colors.normal

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

local function UpdateBorderColor(self, r,g,b)
	if not self.BorderTextures then return end

	if self.unit then
		local c = UnitClassification(self.unit)
		if c == "worldboss" then c = "boss" end
		if c == "rareelite" then c = "rare" end
		r,g,b = unpack(config.border_colors[c])
	end

	if r and g and b then
		--// Set the border color
		for _, tex in ipairs(self.BorderTextures) do
			tex:SetVertexColor(r, g, b)
		end
	end
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
		local hl = CreateFrame("Frame", '$parentHighlight', self)
		hl:SetAllPoints(self)
		hl:SetFrameLevel(15)
		hl:Hide()

		local tex = hl:CreateTexture(nil, "OVERLAY")
		tex:SetTexture(config.highlight_texture)
		tex:SetBlendMode('ADD')
		tex:SetAlpha(0.5)
		tex:SetAllPoints(hl)
		tex:SetVertexColor(unpack(config.highlight_color))

		self.Highlight = hl
		self.Highlight.tex = tex

	end

	self.Highlight:Show()

	return false
end

local function HighlightEnable(self)

	--// Mouseover Events
	self:HookScript("OnEnter", HighlightUpdate)
	self:HookScript("OnLeave", HighlightUpdate)

	--// Target Events
	self:RegisterEvent('PLAYER_TARGET_CHANGED', HighlightUpdate)
	table.insert(self.__elements, HighlightUpdate)
end



--// Health and Power, mostly for setting color
local function PostUpdateHealth(Health, unit, min, max)
	local r,g,b

	--// Determin the color we want to use
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		r,g,b = unpack(oUF.colors.tapped)
	elseif not UnitIsConnected(unit) then
		r,g,b = unpack(oUF.colors.disconnected)
	else
		r,g,b = unpack(config.healthbar_color)
	end

	--// Set the health bar color
	Health:SetStatusBarColor(r, g, b)

	--// Set the background color
	Health.bg:SetVertexColor(25/255, 25/255, 25/255)
end

local function PostUpdatePower(Power, unit, min, max)
	local r,g,b

	--// Determin the color we want to use
	if UnitIsPlayer(unit) then
		r,g,b = unpack(oUF.colors.class[select(2, UnitClass(unit))])
	else
		local power = select(2, UnitPowerType(unit))
		if power == '' then power = 'UNUSED' end

		r,g,b = unpack(oUF.colors.power[power])
	end

	--// Set the power bar color
	Power:SetStatusBarColor(r, g, b)

	--// Set the background color
	Power.bg:SetVertexColor(r * 0.4, g * 0.4, b * 0.4)
end



--// Castbar Functions
local function OnCastSent(self, event, unit, spell, rank, target)
	if self.unit ~= unit then return end
	self.Castbar.sentTime = GetTime()
end

local function PostCastStart(self, unit, name, rank, castid)
	self:SetAlpha(1.0)
	self.Spark:Show()
	self:SetStatusBarColor(unpack(config.castbar_colors.normal))

	if (self.sentTime) then
		self.latency = GetTime() - self.sentTime
	else
		self.latency = 0
	end
end

local function PostCastStop(self, unit, name, rank, castid)
	self:SetValue(self.max)
	self:Show()
end

local function PostChannelStop(self, unit, name, rank, castid)
	self:SetValue(0)
	self:Show()
end

local function PostCastFailed(self, unit, name, rank, castid)
	self:SetValue(self.max)
	self:Show()
end

local function CastbarOnUpdate(self, elapsed)
	if self.casting or self.channeling then
		local duration = self.casting and self.duration + elapsed or self.duration - elapsed
		local remaining = (duration - (duration *2) + self.max) -- incase i want to use it :p
		if (self.casting and duration >= self.max) or (self.channeling and duration <= 0) then
			self.casting = nil
			self.channeling = nil
			return
		end

		if self.SafeZone then
			local width = self:GetWidth() * self.latency / self.max
			if (width < 1) then width = 1 end
			self.SafeZone:SetWidth(width);
		end

		if self.Lag then
			self.Lag:SetFormattedText("%d ms", self.latency * 1000)
		end

		if(self.Time) then
			if self.delay ~= 0 then
				self.Time:SetFormattedText('|cffff0000-%.1f|r %.1f | %.1f', self.delay, duration, self.max)
			else
				self.Time:SetFormattedText('%.1f | %.1f', duration, self.max)
			end
		end

		self.duration = duration
		self:SetValue(duration)
		if(self.Spark) then
			self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
		end
	else
		self.Spark:Hide()
		local alpha = self:GetAlpha() - 0.08
		if alpha > 0 then
			self:SetAlpha(alpha)
		else
			self:Hide()
		end

	end
end



--// Aura Function
local function PostCreateAuraIcon(iconframe, button)
	button.cd:SetReverse(true)
	button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	button.border = button:CreateTexture(nil, 'OVERLAY')
	button.border:SetTexture(config.auraborder_texture)
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
	local color_type  = Auras.rules[rule][is_friend and 'friend' or 'enemy']

	if color_type == "type" then
		local color = Auras.colors.type[tostring(dtype)]
		if not color then color = Auras.colors.type["nil"] end
		border:SetVertexColor(unpack(color))
	elseif color_type == "caster" then
		border:SetVertexColor(unpack(Auras.colors.caster[who]))
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


-----------------------------
--// STYLE FUNCTION
-----------------------------
oUF:RegisterStyle('Zoey', function(self, unit)

	--// Rightclick Menu
	self.menu = Menu
	self:SetAttribute("*type2", "menu")
	self:RegisterForClicks("AnyUp")

	--// Hover Effects
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	--// Range Fading
	self.SpellRange = {
		insideAlpha = 1,
		outsideAlpha = 0.5
	}

	--// Background
	local Background = self:CreateTexture(nil, "BACKGROUND")
	Background:SetAllPoints(self)
	Background:SetTexture(0, 0, 0, 1)

	--// Border
	CreateBorder(self)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateBorderColor)
	table.insert(self.__elements, UpdateBorderColor)

	--// Highlight
	HighlightEnable(self)

	--// Overlay Frame -- used to attach icons/text to
	local Overlay = CreateFrame('Frame', '$parentOverlay', self)
	Overlay:SetAllPoints(self)
	Overlay:SetFrameLevel(10)

	------------------------------
	--// Icons
	------------------------------

	if unit == 'player' then
		--// Resting Icon
		self.Resting = Overlay:CreateTexture(nil, "OVERLAY")
		self.Resting:SetSize(25,25)
		self.Resting:SetPoint("LEFT", Overlay, "BOTTOMLEFT", 0, -2)

		--// Combat Icon
		self.Combat = Overlay:CreateTexture(nil, 'OVERLAY')
		self.Combat:SetSize(25,25)
		self.Combat:SetPoint('RIGHT', Overlay, 'BOTTOMRIGHT', 0, -2)

	elseif unit == 'target' then
		--// Quest Mob Icon
		self.QuestIcon = Overlay:CreateTexture(nil, "OVERLAY")
		self.QuestIcon:SetSize(32,32)
		self.QuestIcon:SetPoint("CENTER", Overlay, "LEFT", 0, 0)
	end

	if unit == "party" or unit == "target" or unit == "focus" then
		--// Phase Icon
		self.PhaseIcon = Overlay:CreateTexture( nil, "OVERLAY" )
		self.PhaseIcon:SetPoint( "CENTER", self, 0, 0)
		self.PhaseIcon:SetSize( 50, 50 )
		self.PhaseIcon:SetTexture( [[Interface\Icons\Spell_Frost_Stun]] )
		self.PhaseIcon:SetTexCoord( 0.05, 0.95, 0.05 , 0.95 )
		self.PhaseIcon:SetDesaturated( true )
		self.PhaseIcon:SetBlendMode( "ADD" )
		self.PhaseIcon:SetAlpha( 0.8 )
	end

	--// Raid Icon (Skull, Cross, Square ...)
	self.RaidIcon = Overlay:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetSize(21,21)
	self.RaidIcon:SetPoint('CENTER', Overlay, 'LEFT', 0, 0)

	if unit == 'target' then
		self.RaidIcon:SetSize(30,30)
		self.RaidIcon:SetPoint('CENTER', Overlay, 'TOP', 0, 0)
	end

	--// PvP Icon -- The img used isnt perfect, it sucks
	self.PvP = Overlay:CreateTexture(nil, "OVERLAY")
	local faction = UnitFactionGroup(unit)
	if faction == "Horde" then
		self.PvP:SetTexCoord(0.08, 0.58, 0.045, 0.545)
	elseif faction == "Alliance" then
		self.PvP:SetTexCoord(0.07, 0.58, 0.06, 0.57)
	else
		self.PvP:SetTexCoord(0.05, 0.605, 0.015, 0.57)
	end
	self.PvP:SetSize(21,21)
	self.PvP:SetPoint("CENTER", Overlay, 'LEFT', 0,0)

	if unit == 'player' or unit == 'party' then
		--// LFD Role Icon
		self.LFDRole = Overlay:CreateTexture(nil, "OVERLAY")
		self.LFDRole:SetSize(18,18)
		self.LFDRole:SetPoint("CENTER", Overlay, "TOPLEFT", 1, 0)

		--// Ready Check icon
		self.ReadyCheck = Overlay:CreateTexture(nil, "OVERLAY")
		self.ReadyCheck:SetSize(14, 14)
		self.ReadyCheck:SetPoint("CENTER", Overlay, "BOTTOM", 0, 0)
	end


	------------------------------
	--// Name Text -- oh and leader and master icons ;)
	------------------------------
	local Name = CreateText(Overlay, 16)
	self:Tag(Name, '[leadericon][mastericon][Zoey:Name]')

	--// Default location
	Name:SetPoint("LEFT", self, "TOPLEFT", 3, 1)

	--// Reposistion for target frame
	if unit == 'target' or unit == 'party' then
		Name:SetPoint("TOPLEFT", 3, -2)
	end

	--// Bar Position
	local offset = config.bar_spacing

	------------------------------
	--// Portrait
	------------------------------
	if unit == 'target' or unit == 'party' then
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
	self.Health:SetStatusBarTexture(config.statusbar_texture)
	self.Health:SetHeight(config.healthbar_size)
	self.Health:SetPoint('TOP', 0, -offset)
	self.Health:SetPoint('LEFT', 1,0)
	self.Health:SetPoint('RIGHT',-1,0)
	self.Health.frequentUpdates = .2
	self.Health.PostUpdate = PostUpdateHealth

	--// Healthbar Background
	self.Health.bg = self:CreateTexture(nil, "BACKGROUND")
	self.Health.bg:SetTexture(config.statusbar_texture)
	self.Health.bg:SetAllPoints(self.Health)

	--// Text
	local HealthText = CreateText(self.Health, 22)
	self:Tag(HealthText, '[Zoey:Health]')

	HealthText:SetPoint('RIGHT', -1, -1)

	--// offset the power bar's position
	offset = offset + self.Health:GetHeight() + config.bar_spacing

	------------------------------
	--// Power Bar
	------------------------------
	self.Power = CreateFrame('StatusBar', '$parentPowerBar', self)
	self.Power:SetStatusBarTexture(config.statusbar_texture)
	self.Power:SetHeight(config.powerbar_size)
	self.Power:SetPoint('TOP', 0, -offset)
	self.Power:SetPoint('LEFT', 1,0)
	self.Power:SetPoint('RIGHT',-1,0)
	self.Power.frequentUpdates = .2
	self.Power.PostUpdate = PostUpdatePower

	--// Powerbar Background
	self.Power.bg = self:CreateTexture(nil, "BACKGROUND")
	self.Power.bg:SetTexture(config.statusbar_texture)
	self.Power.bg:SetAllPoints(self.Power)

	--// Text
	local PowerText = CreateText(self.Power, 12)
	self:Tag(PowerText, '[Zoey:Power]')

	PowerText:SetPoint('RIGHT', -1, -1)

	--// Offset the class bars' position
	offset = offset + self.Power:GetHeight() + config.bar_spacing

	--// -----------------------------
	--// Class Bars
	--// -----------------------------



	--// -----------------------------
	--// Frame Size
	--// -----------------------------
	self:SetHeight(offset)
	self:SetWidth(139)

	if unit == 'player' or unit == 'target' then
		self:SetWidth(285)
	end

	--// -----------------------------
	--// Enable mouse on all texts
	--// -----------------------------
	for _,fs in ipairs(self.__tags) do
		self:HookScript('OnEnter', function() fs:UpdateTag() end)
		self:HookScript('OnLeave', function() fs:UpdateTag() end)
	end



	--// -----------------------------
	--// Cast Bars
	--// -----------------------------
	if unit == 'player' or unit == 'target' then

		--// The Castbar its self
		self.Castbar = CreateFrame("StatusBar", "$parentCastbar", self)
		self.Castbar:SetStatusBarTexture(config.statusbar_texture)
		self.Castbar:SetStatusBarColor(unpack(config.castbar_colors.normal))

		self.Castbar:SetSize(585, 38)

		if unit == "player" then
			self.Castbar:SetPoint('TOP', oUF.units.player, 'BOTTOM', 0, -76)
		elseif unit == "target" then
			self.Castbar:SetPoint('BOTTOM', oUF.units.target, 'TOP', 0, 76)
		end

		--// Add a spark
		self.Castbar.Spark = self.Castbar:CreateTexture(nil, "OVERLAY")
		self.Castbar.Spark:SetHeight(self.Castbar:GetHeight()*2.5)
		self.Castbar.Spark:SetBlendMode("ADD")
		self.Castbar.Spark:SetAlpha(0.5)

		--// Player only Latency
		if unit == 'player' then
			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,"OVERLAY")
			self.Castbar.SafeZone:SetTexture(config.statusbar_texture)
			self.Castbar.SafeZone:SetVertexColor(1,0.1,0,.6)
			self.Castbar.SafeZone:SetPoint("TOPRIGHT")
			self.Castbar.SafeZone:SetPoint("BOTTOMRIGHT")

			self.Castbar.Lag = CreateText(self.Castbar, 10)
			self.Castbar.Lag:SetPoint("TOPRIGHT", self.Castbar, 'BOTTOMRIGHT', 0, -7)

			self:RegisterEvent("UNIT_SPELLCAST_SENT", OnCastSent)
		end

		--// Castbar Texts
		self.Castbar.Text = CreateText(self.Castbar, 20)
		self.Castbar.Text:SetPoint("LEFT", 10, 0)

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
		local CastbarFrame = CreateFrame('Frame', '$parentCastbarFrame', self.Castbar)
		CastbarFrame:SetPoint('TOPLEFT', -1, 1)
		CastbarFrame:SetPoint('BOTTOMRIGHT', 1, -1)
		CastbarFrame:SetFrameLevel(self.Castbar:GetFrameLevel()-1)

		--// Castbar Frame Background
		local CastbarFrameBackground = CastbarFrame:CreateTexture(nil, "BACKGROUND")
		CastbarFrameBackground:SetAllPoints(CastbarFrame)
		CastbarFrameBackground:SetTexture(config.statusbar_texture)
		CastbarFrameBackground:SetVertexColor(25/255, 25/255, 25/255)

		--// Castbar Frame Border
		CreateBorder(CastbarFrame)
	end



	--// -----------------------------
	--// Auras
	--// -----------------------------
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

		self.Buffs.CustomFilter   = ns.CustomAuraFilter
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

		self.Debuffs.CustomFilter   = ns.CustomAuraFilter
		self.Debuffs.PostCreateIcon = PostCreateAuraIcon
		self.Debuffs.PostUpdateIcon = PostUpdateAuraIcon
	end

end)

-----------------------------
--// SPAWN UNITS
-----------------------------
oUF:Factory(function(self)

	local u = self.units

	--// Player
	self:Spawn('Player'				):SetPoint('TOP', UIParent, 'CENTER', 0, -302)

	--// Player Pet
	self:Spawn('Pet'				):SetPoint('TOPRIGHT', u.player, 'TOPLEFT', -15, 0)
	self:Spawn('PetTarget'			):SetPoint('BOTTOM', u.pet, 'TOP', 0, 16)
	self:Spawn('PetTargetTarget'	):SetPoint('BOTTOM', u.pettarget, 'TOP', 0, 15)

	--// Targets
	self:Spawn('Target'				):SetPoint('BOTTOM', u.player, 'TOP', 0, 18)
	self:Spawn('TargetTarget'		):SetPoint('TOPLEFT', u.target, 'TOPRIGHT', 15, 0)
	self:Spawn('TargetTargetTarget'	):SetPoint('BOTTOMLEFT', u.target, 'BOTTOMRIGHT', 15, 0)

	--// Focus
	self:Spawn('Focus'				):SetPoint('TOPRIGHT', u.pet, 'TOPLEFT', -15, 0)
	self:Spawn('FocusTarget'		):SetPoint('BOTTOM', u.focus, 'TOP', 0, 16)
	self:Spawn('FocusTargetTarget'	):SetPoint('BOTTOM', u.focustarget, 'TOP', 0, 15)

	--// Party
	self:SpawnHeader(nil, nil, 'raid,party',
		-- http://wowprogramming.com/docs/secure_template/Group_Headers
		-- Set header attributes
		'showParty', true,
		'yOffset', 47,

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', UIParent, 'LEFT', 16, -304)

	--// Party Targets
	self:SpawnHeader(nil, nil, 'raid,party',
		'showParty', true,
		'yOffset', 107,
		'oUF-initialConfigFunction', [[
			self:SetAttribute('unitsuffix', 'target')
		]],

		'point', 'BOTTOM'
	):SetPoint('BOTTOMLEFT', oUF_ZoeyParty, 'BOTTOMRIGHT', 15, 0)

end)

-----------------------------
--// Extra Stuff for the UI
-----------------------------
oUF:Factory(function(self)

	--// Hide the Blizzard Buffs
	BuffFrame:Hide()
	BuffFrame:UnregisterAllEvents()
	TemporaryEnchantFrame:Hide()
	ConsolidatedBuffs:Hide()

	--// Skin the Mirror Timers
	for i = 1, 3 do
		local barname = "MirrorTimer" .. i
		local bar = _G[ barname ]

		for i, region in pairs( { bar:GetRegions() } ) do
			if region.GetTexture and region:GetTexture() == "SolidTexture" then
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
		bar.bg:SetTexture( config.statusbar_texture )
		bar.bg:SetVertexColor( 0.2, 0.2, 0.2, 1 )

		bar.text = _G[ barname .. "Text" ]
		bar.text:ClearAllPoints()
		bar.text:SetPoint( "LEFT", bar, 4, 1 )
		bar.text:SetFont( config.font, 16)

		bar.border = _G[ barname .. "Border" ]
		bar.border:Hide()

		bar.bar = _G[ barname .. "StatusBar" ]
		bar.bar:SetAllPoints( bar )
		bar.bar:SetStatusBarTexture( config.statusbar_texture )
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
-----------------------------
--// THE END