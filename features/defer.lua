-- Get the addon namespace
local addonName, ns = ...

local deferframe = CreateFrame('Frame')
deferframe.queue = {}

local function runDeferred(thing)
    local thing_t = type(thing)
    if thing_t == 'string' and ns[thing] then
        ns[thing](ns)
    elseif thing_t == 'function' then
        thing(ns)
    end
end

-- This method will defer the execution of a method or function until the
-- player has exited combat. If they are already out of combat, it will
-- execute the function immediately.
function ns:Defer(...)
    for i = 1, select('#', ...) do
        local thing = select(i, ...)
        local thing_t = type(thing)
        if thing_t == 'string' or thing_t == 'function' then
            if InCombatLockdown() then
                deferframe.queue[#deferframe.queue + 1] = thing
            else
                runDeferred(thing)
            end
        else
            error('Invalid object passed to \'Defer\'')
        end
    end
end

deferframe:RegisterEvent('PLAYER_REGEN_ENABLED')
deferframe:SetScript('OnEvent', function(self, event, ...)
    for idx, thing in ipairs(deferframe.queue) do
        runDeferred(thing)
    end
    table.wipe(deferframe.queue)
end)
