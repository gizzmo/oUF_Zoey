--// Get the addon namespace
local addon, ns = ...

local function IsMouseOver(unit)
	if ns.Mouse_Focus and ns.Mouse_Focus['unit'] == unit then
		return true
	end

	return false
end

local function Short(value)
	if value >= 1e7 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e6 then
		return ('%.2fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e5 then
		return ('%.0fk'):format(value / 1e3)
	elseif value >= 1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

local function SeparateDigits(number, thousands, decimal)
	if not thousands then thousands = ',' end
	if not decimal then decimal = '.' end

	local t = {}

	local int = math.floor(number)
	local rest = number % 1
	if int == 0 then
		t[#t+1] = 0
	else
		local digits = math.log10(int)
		local segments = math.floor(digits / 3)
		t[#t+1] = math.floor(int / 1000^segments)
		for i = segments-1, 0, -1 do
			t[#t+1] = thousands
			t[#t+1] = ("%03d"):format(math.floor(int / 1000^i) % 1000)
		end
	end
	if rest ~= 0 then
		t[#t+1] = decimal
		rest = math.floor(rest * 10^6)
		while rest % 10 == 0 do
			rest = rest / 10
		end
		t[#t+1] = rest
	end
	local s = table.concat(t)

	return s
end

local function Round(num, digits)
	if not digits then
		digits = 0
	end
	local power = 10^digits

	return math.floor(num*power+.5) / power
end

local function Percent(cur, max)
	if max ~= 0 then
		return Round(cur/max*100,1)
	else
		return 0
	end
end

oUF.Tags['Zoey:Name'] = function(unit)
	local name = UnitName(unit) or ''
	local _, class = UnitClass(unit)
	local classColor = Hex(UnitIsPlayer(unit) and _COLORS.class[class] or {1,1,1})

	local level = UnitLevel(unit)
	local levelColor = Hex(GetQuestDifficultyColor(level <= 0 and 99 or level))

	-- only show
	if UnitIsPlayer(unit) then
		if level == 85 then
			level = ''
		end
	else
		if level == 1 or level == 85 then
			level = ''
		elseif level < 1 then
			level = '??'
		end
	end

	-- trim the length of name to fit the frame
	local length = 13

	if unit == 'player' or unit == 'target' then
		length = 30
	end

	if strlen(name..' '..level) > length then
		local len = length - strlen(' '..level)
		name = strsub(name,1,len)..'…'
	end

	-- Show Player on mouse over, all others just show
	if (unit == 'player' and IsMouseOver(unit)) or unit ~= 'player' then
		return ('%s %s'):format(classColor..name, levelColor..level)
	end
end
oUF.TagEvents['Zoey:Name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP'


oUF.Tags['Zoey:Health'] = function(unit)
	--// Status
	if not UnitIsConnected(unit)  then
		return 'Offline'
	elseif UnitIsFeignDeath(unit) then
		return 'Feign Death'
	elseif UnitIsDead(unit) then
		return 'Dead'
	elseif UnitIsGhost(unit) then
		return 'Ghost'
	end

	local cur = UnitHealth(unit)
	local max = UnitHealthMax(unit)

	local SepSh = Short
	if unit == 'target' or unit == 'player' then
		SepSh = SeparateDigits
	end

	if IsMouseOver(unit) then
		if cur ~= max then
			return ('|cffff7f7f-%s'):format(SepSh(max - cur))
		else
			return ('%s'):format(SepSh(max))
		end
	else
		if cur ~= max then
			return ('%s%%'):format(Percent(cur,max))
		end
	end
end
oUF.TagEvents['Zoey:Health'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION'


oUF.Tags['Zoey:Power'] = function(unit)

	local cur = UnitPower(unit)
	local max = UnitPowerMax(unit)

	local SepSh = Short
	if unit == 'target' or unit == 'player' then
		SepSh = SeparateDigits
	end

	if not UnitIsDead(unit) and UnitPowerType(unit) == 0 and IsMouseOver(unit) then
		if cur ~= max then
			return ('|cffff7f7f-%s'):format(SepSh(max - cur))
		else
			return ('%s'):format(SepSh(max))
		end
	end

end
oUF.TagEvents['Zoey:Power'] = 'UNIT_POWER UNIT_MAXPOWER'


oUF.Tags["leadericon"] = function(unit)
	if (UnitInParty(unit) or UnitInRaid(unit)) and UnitIsPartyLeader(unit) then
		return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]]
	elseif UnitInRaid(unit) and UnitIsRaidOfficer(unit) then
		return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0|t]]
	end
end
oUF.TagEvents["leadericon"] = "PARTY_LEADER_CHANGED PARTY_MEMBERS_CHANGED"
oUF.UnitlessTagEvents["PARTY_LEADER_CHANGED"] = true
oUF.UnitlessTagEvents["PARTY_MEMBERS_CHANGED"] = true


oUF.Tags["mastericon"] = function(unit)
	local method, pid, rid = GetLootMethod()
	if method == "master" then
		local munit
		if pid then
			if pid == 0 then
				munit = "player"
			else
				munit = "party" .. pid
			end
		elseif rid then
			munit = "raid" .. rid
		end
		if munit and UnitIsUnit(munit, unit) then
			return [[|TInterface\GroupFrame\UI-Group-MasterLooter:0:0:0:2|t]]
		end
	end
end
oUF.TagEvents["mastericon"] = "PARTY_LOOT_METHOD_CHANGED PARTY_MEMBERS_CHANGED"
oUF.UnitlessTagEvents["PARTY_LOOT_METHOD_CHANGED"] = true
oUF.UnitlessTagEvents["PARTY_MEMBERS_CHANGED"] = true


--[[
oUF.Tags['Zoey:PlayerHealth'] = function(unit)
-- ====================================================================

	local cur = HP(unit)
	local max = MaxHP(unit)
	local status = Status(unit)

	if status then
		return status
	elseif IsMouseOver() then
		if cur == max then
			return '%s',SeparateDigits(max)
		else
			return '|cffff7f7f-%s|r / |cff00ff00%s|r / %s',SeparateDigits(max - cur),SeparateDigits(cur),SeparateDigits(max)
		end
	else
		if cur ~= max then
			return '%s%%',Percent(cur,max)
		end
	end

-- ====================================================================
end
oUF.Tags['Zoey:TargetHealth'] = function(unit)
-- ====================================================================

	local cur = HP(unit)
	local max = MaxHP(unit)
	local status = Status(unit)
	local class = UnitClass('player')

	local perc = 0
	if class == 'Hunter' or class == 'Warrior' then
		perc = 20
	elseif class == 'Warlock' then
		perc = 35
	end

	if status then
		return status
	elseif IsMouseOver() then
		if cur == max then
			return '%s',SeparateDigits(max)
		else
			return '|cffff7f7f-%s|r / |cff00ff00%s|r / %s',SeparateDigits(max - cur),SeparateDigits(cur),SeparateDigits(max)
		end
	else
		if cur ~= max then
			local percent = Percent(cur,max)
			if percent < perc then
				return '|cffe80000%s%%',percent
			end
		end
	end

-- ====================================================================
end
oUF.Tags['Zoey:TargetHealth2'] = function(unit)
-- ====================================================================

	local cur = HP(unit)
	local max = MaxHP(unit)
	local class = UnitClass('player')

	local perc = 0
	if class == 'Hunter' or class == 'Warrior' then
		perc = 20
	elseif class == 'Warlock' then
		perc = 35
	end

	if not IsMouseOver() and cur ~= max then
		local percent = Percent(cur,max)
		if percent < perc then
			return '|cffe80000%s%%',percent
		end
	end

-- ====================================================================
end
oUF.Tags['Zoey:AfkTimer'] = function(unit) -- Player and Target
-- ====================================================================

	return ' %s',AFK(unit) or DND(unit) or ''

-- ====================================================================
end
oUF.Tags['Zoey:PvpTimer'] = function(unit) -- Player
-- ====================================================================

	local pvp = PVPDuration()
	if pvp then
		return '  PVP: |cffff0000%s|r',FormatDuration(pvp)
	end

-- ====================================================================
end
oUF.Tags['Zoey:RealmIndicator'] = function(unit)
-- ====================================================================

	local _, realm = UnitName(unit)
	local r,g,b = 225,225,225

	if realm == nil then
		if UnitIsInMyGuild(unit) then
			r,g,b = 195,27,255
		end

		return '|cff%02x%02x%02x!',r,g,b
	end

-- ====================================================================
end
oUF.Tags['Zoey:Guild'] = function(unit)
-- ====================================================================

	if IsInGuild(unit) then
		local GuildName = GetGuildInfo(unit)or''
		local r,g,b = 255,255,255

		if GuildName ~= '' then
			if UnitIsInMyGuild(unit) then
				r,g,b = 195,27,255
			end

			return '|cff%02x%02x%02x<%s>',r,g,b,GuildName
		end
	end

-- ====================================================================
end

oUF.Tags['Zoey:DruidDots'] = function(unit)
-- ====================================================================

	if UnitClass("player") == 'Druid' then

		local strings = {}

		for i, name in pairs({'Regrowth', 'Rejuvenation', 'Lifebloom'}) do
			local name, _, _, count, _, _, expirationTime, _, _, _, id = UnitBuff(unit, name, nil, "PLAYER")


			strings[i] = ('[%s%s]'):format(FormatDuration(expirationTime),'')


		end


		UpdateIn(0.25)

		return table.concat(strings)

			-- [if HasAura('Regrowth') then
			-- AuraDuration('Regrowth'):Floor:Green:Bracket
			-- end] [if HasAura('Rejuvenation') then
			-- AuraDuration('Rejuvenation'):Floor:Fuchsia:Bracket
			-- end] [if hasAura('Lifebloom') then
			-- AuraDuration('Lifebloom'):Floor:Cyan:append('•':repeat(NumAura('Lifebloom'))):bracket
			-- end]

		-- return 'I am a druid, Yay'
	end
-- ====================================================================
end
--]]