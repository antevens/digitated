digitated = {}

local components = {
	"digimeseioexp"
}

if minetest.get_modpath("mesecons_luacontroller") then table.insert(components,"digimeseioexp") end

for _,name in ipairs(components) do
	dofile(string.format("%s%s%s.lua",minetest.get_modpath(minetest.get_current_modname()),DIR_DELIM,name))
end
