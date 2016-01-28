-- Get the addon namespace
local addonName, ns = ...

function dbGetValue(info)
	return ns.db.profile[info[#info]]
end
function dbSetValue(info, value)
	ns.db.profile[info[#info]] = value
end

local Media = LibStub("LibSharedMedia-3.0")

LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, {
    name = "oUF Zoey",
    type = 'group',
    args = {
        general = {
            type = 'group',
            name = 'General',
            inline = true,
            args = {
                statusbar = { order = 1,
                    name = 'Statusbar Texture',
                    desc = 'Set the statusbars texture.',
                    width = 'double',

                    type = 'select',
                    values = Media:HashTable('statusbar'),
                    dialogControl = 'LSM30_Statusbar',

                    set = function(i,v)
                        ns.db.profile.statusbar = v
                        ns.SetAllStatusBarTextures()
                    end
                },

                font = { order = 2,
                    name = 'Font',
                    desc = 'Set the font.',
                    width = 'double',

                    type = 'select',
                    values = Media:HashTable('font'),
                    dialogControl = 'LSM30_Font',

                    set = function(i,v)
                        ns.db.profile.statusbar = v
                        ns.SetAllFonts()
                    end
                },

                ptgap = { order = 3,
                    name = 'Player Target Gap',
                    desc = 'The gap between the player and target frames.',
                    width = 'double',

                    type = 'range', min = 12, max = 500, step = 2,

                    set = function(i,v)
                        ns.db.profile.ptgap = v
                        oUF_ZoeyUnitFrameAnchor:SetWidth(v)
                    end
                },

                frames_offset = { order = 4,
                    name = 'Frames Offset',
                    desc = 'The distance the frames are from the bottom of the screen.',
                    width = 'double',

                    type = 'range', min = 100, max = 500, step = 1,

                    set = function(i,v)
                        ns.db.profile.frames_offset = v
                        local p, r1, r2, x, y = oUF_ZoeyUnitFrameAnchor:GetPoint(1)
                        oUF_ZoeyUnitFrameAnchor:SetPoint(p, r1, r2, x, v)
                    end
                },
            }
        }
    },

    -- set the default getter and setter
    get = dbGetValue,
    set = dbSetValue,
})
