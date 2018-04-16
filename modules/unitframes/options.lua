local ADDON_NAME, Addon = ...
local L = Addon.L

--------------------------------------------------------------------- Options --
function Module.get_module_options()
    return {
        type = 'group',
        name = L['Unitframes'],
        args = {

        }
    }
end
