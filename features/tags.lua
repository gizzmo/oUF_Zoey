-- Get the addon namespace
local addon, ns = ...

local function IsMouseOver(unit)
    if ns.Mouse_Focus and ns.Mouse_Focus['unit'] == unit then
        return true
    end

    return false
end

local function ShouldShow(unit)
    -- Show Player and pet on mouseover, all others just show
    if (unit == 'player' or unit == 'pet') and not IsMouseOver(unit) then
        return false
    end

    return true
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


local FigureNPCGuild
do
    local tt = CreateFrame('GameTooltip', 'ZoeyTooltip', UIParent, 'GameTooltipTemplate')
    tt:SetOwner(UIParent, 'ANCHOR_NONE')

    local nextTime, lastUnit, lastName = 0

    function FigureNPCGuild(unit)

        -- Update Tooltip
        local name = UnitName(unit)
        local time = GetTime()
        if lastUnit == unit and lastName == name and nextTime < time then
            return
        end
        lastUnit = unit
        lastName = name
        nextTime = time + 1
        tt:ClearLines()
        tt:SetUnit(unit)
        if not tt:IsOwned(UIParent) then
            tt:SetOwner(UIParent, 'ANCHOR_NONE')
        end


        local text = ZoeyTooltipTextLeft2:GetText()
        if not text or text:find(LEVEL) then
            return nil
        end
        return text
    end

end

oUF.Tags.Events['Zoey:Name'] = 'UNIT_NAME_UPDATE'
oUF.Tags.Methods['Zoey:Name'] = function(unit)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    local classColor = Hex(UnitIsPlayer(unit) and _COLORS.class[class] or {1,1,1})

    if name and ShouldShow(unit) then
        return classColor..name
    end
end


oUF.Tags.Events['Zoey:Level'] = 'UNIT_LEVEL PLAYER_LEVEL_UP'
oUF.Tags.Methods['Zoey:Level'] = function(unit)
    local level = UnitLevel(unit)
    local levelColor = Hex(GetQuestDifficultyColor(level <= 0 and 99 or level))

    -- Hide level for max level players
    if UnitIsPlayer(unit) and level == MAX_PLAYER_LEVEL then
        level = nil

    -- Battle pet level
    elseif UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        level = UnitBattlePetLevel(unit)

    -- Skull instead of double question marks
    elseif level < 1 then
        level = [[|TInterface/TARGETINGFRAME/UI-TargetingFrame-Skull:0:0:2|t]]
    end

    if level and ShouldShow(unit) then
        return levelColor..level
    end
end


oUF.Tags.Events['Zoey:Realm'] = 'UNIT_NAME_UPDATE'
oUF.Tags.Methods['Zoey:Realm'] = function(unit)
    local _, realm = UnitName(unit)

    if realm ~= nil then
        return realm
    end
end


oUF.Tags.Events['Zoey:Status'] = 'UNIT_HEALTH UNIT_CONNECTION'
oUF.Tags.Methods['Zoey:Status'] = function(unit)
    if not UnitIsConnected(unit) then
        return 'Offline'
    elseif UnitIsFeignDeath(unit) then
        return 'Feign Death'
    elseif UnitIsDead(unit) then
        return 'Dead'
    elseif UnitIsGhost(unit) then
        return 'Ghost'
    end
end


oUF.Tags.Events['Zoey:Health'] = 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION'
oUF.Tags.Methods['Zoey:Health'] = function(unit)
    local status = _TAGS['Zoey:Status'](unit)
    if status then return status end

    local cur = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    local SepSh = Short
    if unit == 'target' or unit == 'player' then
        SepSh = SeparateDigits
    end

    if IsMouseOver(unit) then
        if cur < max then
            return ('|cffff7f7f-%s'):format(SepSh(max - cur))
        else
            return ('%s'):format(SepSh(max))
        end
    elseif cur < max then
        return ('%s%%'):format(Percent(cur,max))
    end
end


oUF.Tags.Events['Zoey:TargetHealth'] = oUF.Tags.Events['Zoey:Health']
oUF.Tags.Methods['Zoey:TargetHealth'] = function(unit)
    local status = _TAGS['Zoey:Status'](unit)
    if status then return status end

    local cur = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    local SepSh = Short
    if unit == 'target' or unit == 'player' then
        SepSh = SeparateDigits
    end

    if IsMouseOver(unit) then
        if cur < max then
            return ('|cffff7f7f-%s'):format(SepSh(max - cur))
        else
            return ('%s'):format(SepSh(max))
        end
    elseif cur < max then
        if Percent(cur,max) > 20 then
            return ('%s%%'):format(Percent(cur,max))
        end
    end
end


oUF.Tags.Events['Zoey:TargetHealth2'] = oUF.Tags.Events['Zoey:Health']
oUF.Tags.Methods['Zoey:TargetHealth2'] = function(unit)
    local status = _TAGS['Zoey:Status'](unit)
    if status then return end

    local cur = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    if not IsMouseOver(unit) then
        if Percent(cur,max) < 20 then
            return ('|cffe80000%s%%'):format(Percent(cur,max))
        end
    end
end


oUF.Tags.Events['Zoey:Power'] = 'UNIT_POWER UNIT_MAXPOWER'
oUF.Tags.Methods['Zoey:Power'] = function(unit)
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


oUF.Tags.Events['Zoey:Exp'] = 'PLAYER_XP_UPDATE'
oUF.Tags.Methods['Zoey:Exp'] = function(unit)
    local cur, max, rest = UnitXP(unit), UnitXPMax(unit), GetXPExhaustion(unit)

    if IsMouseOver(unit) then
        if rest then
            return ('%s/%s (%s%%) R: %s%%'):format(Short(cur), Short(max), Percent(cur,max), Percent(rest,max))
        else
            return ('%s/%s (%s%%)'):format(Short(cur), Short(max), Percent(cur,max))
        end
    end
end

oUF.Tags.Events['Zoey:Guild'] = 'UNIT_NAME_UPDATE PARTY_MEMBER_ENABLE'
oUF.Tags.Methods['Zoey:Guild'] = function(unit)
    local r,g,b = 255,255,255

    local GuildName = UnitIsPlayer(unit) and
        GetGuildInfo(unit) or
        FigureNPCGuild(unit)

    if GuildName then
        if UnitIsInMyGuild(unit) then
            r,g,b = 195,27,255
        end

        return ('|cff%02x%02x%02x%s'):format(r,g,b, '<'..GuildName..'>')
    end
end