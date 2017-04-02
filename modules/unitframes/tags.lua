local ADDON_NAME, Addon = ...
local Module = Addon:GetModule('Unitframes')

local function IsMouseOver(unit)
    if Module.mousefocus and Module.mousefocus['unit'] == unit then
        return true
    end

    return false
end

local function ShouldShow(unit)
    -- Show Player and pet on mouseover, all others just show
    if unit == 'player' and not IsMouseOver(unit) then
        return false
    end

    return true
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


oUF.Tags.Events['Name'] = 'UNIT_NAME_UPDATE'
oUF.Tags.Methods['Name'] = function(unit)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    local classColor = Hex(UnitIsPlayer(unit) and _COLORS.class[class] or {1,1,1})

    if name and ShouldShow(unit) then
        return classColor..name..'|r'
    end
end


oUF.Tags.Events['Level'] = 'UNIT_LEVEL PLAYER_LEVEL_UP'
oUF.Tags.Methods['Level'] = function(unit)
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
        return levelColor..level..'|r'
    end
end


oUF.Tags.Events['Realm'] = 'UNIT_NAME_UPDATE'
oUF.Tags.Methods['Realm'] = function(unit)
    local _, realm = UnitName(unit)

    if realm ~= nil then
        return realm
    end
end


oUF.Tags.Events['Status'] = 'UNIT_HEALTH UNIT_CONNECTION'
oUF.Tags.Methods['Status'] = function(unit)
    return not UnitIsConnected(unit) and 'Offline'
            or UnitIsFeignDeath(unit) and 'Feign Death'
            or UnitIsDead(unit) and 'Dead'
            or UnitIsGhost(unit) and 'Ghost'
end


oUF.Tags.Events['Health'] = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION'
oUF.Tags.Methods['Health'] = function(unit)
    local cur = UnitHealth(unit)
    local max = UnitHealthMax(unit)

    local SepSh = Addon.Short
    if unit == 'target' or unit == 'player' then
        SepSh = Addon.SeparateDigits
    end

    local status = _TAGS['Status'](unit)
    if status then
        if IsMouseOver(unit) and max > 0 then -- max is 0 for offline units
            return SepSh(max)
        else
            return status
        end
    end

    if IsMouseOver(unit) then
        if cur < max then
            return SepSh(cur)
        else
            return SepSh(max)
        end
    elseif cur < max then
        return Addon.Percent(cur,max)..'%'
    end
end


oUF.Tags.Events['Power'] = 'UNIT_POWER_FREQUENT UNIT_MAXPOWER'
oUF.Tags.Methods['Power'] = function(unit)
    local cur = UnitPower(unit)
    local max = UnitPowerMax(unit)

    local SepSh = Addon.Short
    if unit == 'target' or unit == 'player' then
        SepSh = Addon.SeparateDigits
    end

    local status = _TAGS['Status'](unit)
    if not status and IsMouseOver(unit) then
        if cur < max then
            return SepSh(cur)
        else
            return SepSh(max)
        end
    end
end


oUF.Tags.Events['Guild'] = 'UNIT_NAME_UPDATE PARTY_MEMBER_ENABLE'
oUF.Tags.Methods['Guild'] = function(unit)
    local GuildName = UnitIsPlayer(unit) and
        GetGuildInfo(unit) or
        FigureNPCGuild(unit)

    if GuildName then
        local guildColor = Hex(UnitIsInMyGuild(unit) and {0.7,0.1,1} or {1,1,1})
        return guildColor..'<'..GuildName..'>|r'
    end
end


oUF.Tags.Events["leadericon"] = "PARTY_LEADER_CHANGED GROUP_ROSTER_UPDATE"
oUF.Tags.Methods["leadericon"] = function(unit)
    if UnitIsGroupLeader(unit) then
        return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]]
    elseif UnitInRaid(unit) and UnitIsGroupAssistant(unit) then
        return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0|t]]
    end
end
