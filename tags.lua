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
			t[#t+1] = ('%03d'):format(math.floor(int / 1000^i) % 1000)
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
	local name = UnitName(unit)
	local _, class = UnitClass(unit)
	local classColor = Hex(UnitIsPlayer(unit) and _COLORS.class[class] or {1,1,1})

	-- Show Player on mouse over, all others just show
	if name and ((unit == 'player' and IsMouseOver(unit)) or unit ~= 'player') then
		return classColor..name
	end
end
oUF.TagEvents['Zoey:Name'] = 'UNIT_NAME_UPDATE'


oUF.Tags['Zoey:Level'] = function(unit)
	local level = UnitLevel(unit)
	local levelColor = Hex(GetQuestDifficultyColor(level <= 0 and 99 or level))

	if UnitIsPlayer(unit) then
		if level == MAX_PLAYER_LEVEL then
			level = ''
		end
	else
		if level == 1 or level == MAX_PLAYER_LEVEL then
			level = nil
		elseif level < 1 then
			level = '??'
		end
	end

	-- Show Player on mouse over, all others just show
	if level and ((unit == 'player' and IsMouseOver(unit)) or unit ~= 'player') then
		return levelColor..level
	end

end
oUF.TagEvents['Zoey:Level'] = 'UNIT_LEVEL PLAYER_LEVEL_UP'

oUF.Tags['Zoey:Status'] = function(unit)
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
end
oUF.TagEvents['Zoey:Status'] = 'UNIT_HEALTH UNIT_CONNECTION'


oUF.Tags['Zoey:Health'] = function(unit)
	local status = _TAGS['Zoey:Status'](unit)
	if status then return status end

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
oUF.TagEvents['Zoey:Health'] = 'UNIT_HEALTH UNIT_MAXHEALTH'


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


oUF.Tags['Zoey:Exp'] = function(unit)
	local cur, max, rest = UnitXP(unit), UnitXPMax(unit), GetXPExhaustion(unit)

	if IsMouseOver(unit) then
		if rest then
			return ('%s/%s (%s%%) R: %s%%'):format(Short(cur), Short(max), Percent(cur,max), Percent(rest,max))
		else
			return ('%s/%s (%s%%)'):format(Short(cur), Short(max), Percent(cur,max))
		end
	end
end
oUF.TagEvents['Zoey:Exp'] = 'PLAYER_XP_UPDATE'



