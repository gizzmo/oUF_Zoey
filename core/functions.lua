local ADDON_NAME, Addon = ...

-- Miscellaneous functions

function Addon.Short(value, raw)
	if not value then return "" end
	local absvalue = abs(value)
	local str, val

	if absvalue >= 1e10 then
		str, val = "%.0fb", value / 1e9
	elseif absvalue >= 1e9 then
		str, val = "%.1fb", value / 1e9
	elseif absvalue >= 1e7 then
		str, val = "%.1fm", value / 1e6
	elseif absvalue >= 1e6 then
		str, val = "%.2fm", value / 1e6
	elseif absvalue >= 1e5 then
		str, val = "%.0fk", value / 1e3
	elseif absvalue >= 1e3 then
		str, val = "%.1fk", value / 1e3
	else
		str, val = "%d", value
	end

	if raw then
		return str, val
	else
		return format(str, val)
	end
end

function Addon.SeparateDigits(number, thousands, decimal)
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

function Addon.Round(num, digits)
    if not digits then
        digits = 0
    end
    local power = 10^digits

    return math.floor(num*power+.5) / power
end

function Addon.Percent(cur, max)
    if max ~= 0 then
        return Round(cur/max*100,1)
    else
        return 0
    end
end
