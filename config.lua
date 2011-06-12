--// Get the addon namespace
local addon, ns = ...

--//----------------------------
--// CONFIG
--//----------------------------
local config = {}

--// Status bar
config.statusbar = [[Interface\AddOns\oUF_Zoey\media\Armory]]

--// Font
config.font = [[Interface\AddOns\oUF_Zoey\media\DORISPP.TTF]]

--// Border
config.border = {
	texture = [[Interface\AddOns\oUF_Zoey\media\ThinSquare]],
	colors = {
		normal = {113/255, 113/255, 113/255},
		rare   = {1, 1, 1},
		elite  = {185/255, 185/255, 80/255},
		boss   = {150/255, 80/255, 200/255}
	},
	size    = 12,
	padding = 4
}

--// Highlight
config.highlight = {
	texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
	color = {1,1,1, 0.2}
}

--// Aura
config.aura = {
	texture = [[Interface\AddOns\oUF_Zoey\media\AuraBorder]],
	rules = {
		my_buffs      = { friend = 'caster', enemy = 'type'},
		my_debuffs    = { friend = 'type',   enemy = 'caster'},
		other_buffs   = { friend = 'caster', enemy = 'type'},
		other_debuffs = { friend = 'type',   enemy = 'caster'}
	},
	colors = {
		caster = {
			my    = {0, 1, 0, 1},
			other = {1, 0, 0, 1}
		},
		type = {
			Poison  = {0, 1, 0, 1},
			Magic   = {0, 0, 1, 1},
			Disease = {.55, .15, 0, 1},
			Curse   = {5, 0, 5, 1},
			Enrage  = {1, .55, 0, 1},
			['nil'] = {1, 0, 0, 1}
		},
	}
}


--//-------------------------
--// COLORS
--//-------------------------

--// Health bar color
oUF.colors.health = {89/255, 89/255, 89/255}	-- dark grey

--// Combo points colors
oUF.colors.comboPoints = {
	normal = {232/255, 214/255, 12/255},		-- yellow
	last   = {240/255, 60/255, 60/255}			-- red
}

--// Experience bar colors
oUF.colors.experience = {
	main = {176/255, 72/255, 176/255},			-- purple
	rested = {80/255, 80/255, 222/255}			-- blue
}

--// Cast bar colors
oUF.colors.cast =  {
	normal = {89/255, 89/255, 89/255},			-- dark gray
	success = {20/255, 208/255, 0/255},			-- green
	failed = {255/255, 12/255, 0/255},			-- dark red
	safezone = {255/255, 25/255, 0/255, 0.5},	-- transparent red
	shielded = {89/255, 89/255, 89/255},		-- ligh gray
}


--// Handover
ns.config = config