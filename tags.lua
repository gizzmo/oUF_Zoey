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

local function Percent(x, y)
	if y ~= 0 then
		return math.floor(x/y*100+.5)
	else
		return 0
	end
end


oUF.Tags['Zoey:Name'] = function(unit)
	local name = UnitName(unit)
	local _, class = UnitClass(unit)
	local classColor = Hex(UnitIsPlayer(unit) and _COLORS.class[class] or {1,1,1})

	local level = UnitLevel(unit)
	local levelColor = Hex(GetQuestDifficultyColor(level <= 0 and 99 or level))

	-- only show levels 2 though 84
	if level < 2 or level == 85 then
		if level < 0 then
			level = '??'
		else
			level = ''
		end
	end

	-- trim the length of name to fit the frame
	local length = 13

	if unit == 'player' or unit == 'target' then
		length = 25
	end

	if strlen(name..' '..level) > length then
		local len = length - strlen(' '..level)
		name = strsub(name,1,len)..'…'
	end

	return ('%s %s'):format(classColor..name, levelColor..level)
end
oUF.TagEvents['Zoey:Name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP'


oUF.Tags['Zoey:Health'] = function(unit)

	local cur = UnitHealth(unit)
	local max = UnitHealthMax(unit)

	if cur ~= max then
		return ('%s%%'):format(Percent(cur,max))
	end


end
oUF.TagEvents['Zoey:Health'] = 'UNIT_HEALTH UNIT_MAXHEALTH'

oUF.Tags['Zoey:Health_Hover'] = function(unit)

	local cur = UnitHealth(unit)
	local max = UnitHealthMax(unit)

	if cur == max then
		return ('%s'):format(Short(max))
	else
		return ('|cffff7f7f-%s'):format(Short(max - cur))
	end

end
oUF.TagEvents['Zoey:Health_Hover'] = 'UNIT_HEALTH UNIT_MAXHEALTH'


--[[

oUF.Tags['Zoey:Power'] = function(unit) -- Normal and Party
-- ====================================================================

	local cur = Power(unit)
	local max = MaxPower(unit)

	if not UnitIsDead(unit) and UnitPowerType(unit) == 0 then
		if IsMouseOver() then
			if unit == 'player' or unit == 'target' then
				if cur == max then
					return '%s',SeparateDigits(max)
				else
					return '|cffff7f7f-%s|r / |cff00ff00%s|r / %s',SeparateDigits(max - cur),SeparateDigits(cur),SeparateDigits(max)
				end
			else
				if cur == max then
					return '%s',Short(max,true)
				else
					return '|cffff7f7f-%s|r / %s',Short(max - cur,true),Short(max,true)
				end
			end
		end
	end

-- ====================================================================
end
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