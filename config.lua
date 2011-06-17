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
		normal = {113/255, 113/255, 113/255}, -- Dark Grey
		rare   = {1, 1, 1},                   -- White
		elite  = {185/255, 185/255, 80/255},  -- Yellow
		boss   = {150/255, 80/255, 200/255}   -- Purple
	},
	size    = 12,
	padding = 4
}

--// Highlight
config.highlight = {
	texture = [[Interface\QuestFrame\UI-QuestLogTitleHighlight]],
	color = {1, 1, 1}, -- White
	alpha = 0.3
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
			my    = {0, 1, 0},       -- Green
			other = {1, 0, 0}        -- Red
		},
		type = {
			Poison  = {0, 1, 0},     -- Green
			Magic   = {0, 0, 1},     -- Blue
			Disease = {.55, .15, 0}, -- Brown
			Curse   = {5, 0, 5},     -- Purple
			Enrage  = {1, .55, 0},   -- Orange
			['nil'] = {1, 0, 0}      -- Red
		},
	}
}


--//-------------------------
--// COLORS
--//-------------------------

--// Health bar color
oUF.colors.health = {89/255, 89/255, 89/255} -- dark grey

--// Combo points colors
oUF.colors.comboPoints = {
	normal = {232/255, 214/255, 12/255}, -- yellow
	last   = {240/255, 60/255, 60/255}   -- red
}

--// Experience bar colors
oUF.colors.experience = {
	main = {176/255, 72/255, 176/255}, -- purple
	rested = {80/255, 80/255, 222/255} -- blue
}

--// Cast bar colors
oUF.colors.cast =  {
	normal = {89/255, 89/255, 89/255},          -- dark gray
	success = {20/255, 208/255, 0/255},         -- green
	failed = {255/255, 12/255, 0/255},          -- dark red
	safezone = {255/255, 25/255, 0/255, 0.5},   -- transparent red
	uninterruptible = {89/255, 89/255, 89/255}, -- ligh gray
}


--// Handover
ns.config = config