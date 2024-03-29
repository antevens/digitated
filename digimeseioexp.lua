-- Digilines IO Expander that can be stacked up/down and connects
-- to Mese/Digimese blocks above and below it
-- Borrows heavily from Digistuff IO Expander and Digimese

local explode_port_states = function(state)
	local port = {}
	port.a = state%2  == 1
	port.b = state%4  >= 2
	port.c = state%8  >= 4
	port.d = state%16 >= 8
	return port
end

local implode_port_states = function(port)
	local state = 0
	if port.a then state = state + 1 end
	if port.b then state = state + 2 end
	if port.c then state = state + 4 end
	if port.d then state = state + 8 end
	return state
end

local gettiles = function(state)
	local tiles = {
		"digitated_digimeseexp_top.png",
		"digistuff_digimese.png",
                "digitated_digimeseexp_sides.png",
		"digitated_digimeseexp_sides.png",
                "digitated_digimeseexp_sides.png",
                "digitated_digimeseexp_sides.png"
	}
	local port = explode_port_states(state)
	for p,v in pairs(port) do
		if v then
			tiles[1] = tiles[1].."^jeija_luacontroller_LED_"..string.upper(p)..".png"
		end
	end
	return tiles
end

local ioexp_get_on_rules = function(state)
	local port = explode_port_states(state)
	local rules = {}
	if port.a then table.insert(rules,vector.new(-1,0,0)) end
	if port.b then table.insert(rules,vector.new(0,0,1)) end
	if port.c then table.insert(rules,vector.new(1,0,0)) end
	if port.d then table.insert(rules,vector.new(0,0,-1)) end
	return rules
end

local ioexp_get_off_rules = function(state)
	local port = explode_port_states(state)
	local rules = {}
	if not port.a then table.insert(rules,vector.new(-1,0,0)) end
	if not port.b then table.insert(rules,vector.new(0,0,1)) end
	if not port.c then table.insert(rules,vector.new(1,0,0)) end
	if not port.d then table.insert(rules,vector.new(0,0,-1)) end
	return rules
end

local ioexp_digiline_send = function(pos)
	local meta = minetest.get_meta(pos)
	local channel = meta:get_string("channel")
	local port = {
		a = meta:get_int("aon") == 1,
		b = meta:get_int("bon") == 1,
		c = meta:get_int("con") == 1,
		d = meta:get_int("don") == 1,
	}
	local outstate = explode_port_states(meta:get_int("outstate"))
	for k,v in pairs(outstate) do port[k] = port[k] or v end
	digiline:receptor_send(pos,digiline.rules.default,channel,port)
end

local ioexp_handle_digilines = function(pos,node,channel,msg)
	local meta = minetest.get_meta(pos)
	if channel ~= meta:get_string("channel") then return end
	if msg == "GET" then
		ioexp_digiline_send(pos)
		return
	end
	if type(msg) ~= "table" then return end
	local state = implode_port_states(msg)
	node.name = "digitated:digimeseioexp_"..state
	meta:set_int("outstate",state)
	minetest.swap_node(pos,node)
	for _,i in ipairs(ioexp_get_on_rules(state)) do
		mesecon.receptor_on(pos,{i})
	end
	for _,i in ipairs(ioexp_get_off_rules(state)) do
		mesecon.receptor_off(pos,{i})
	end
end

local ioexp_rule_to_port = function(rule)
	if     rule.x < 0 then return "a"
	elseif rule.z > 0 then return "b"
	elseif rule.x > 0 then return "c"
	elseif rule.z < 0 then return "d" end
end

local ioexp_handle_mesecons = function(pos,_,rule,state)
	local meta = minetest.get_meta(pos)
	local port = ioexp_rule_to_port(rule)
	if not port then return end
	local meta = minetest.get_meta(pos)
	meta:set_int(port.."on",state == "on" and 1 or 0)
	ioexp_digiline_send(pos)
end

for i=0,15,1 do
	local offstate = i == 0
	minetest.register_node("digitated:digimeseioexp_"..i, {
		description = offstate and "Digitated Digimese I/O Expander" or string.format("Dititated Digimese I/O Expander (state: %X )",i),
		groups = offstate and {cracky = 3,} or {cracky = 3,not_in_creative_inventory = 1,},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec","field[channel;Channel;${channel}")
			meta:set_int("aon",0)
			meta:set_int("bon",0)
			meta:set_int("con",0)
			meta:set_int("don",0)
			meta:set_int("outstate",i)
		end,
		_digitated_channelcopier_fieldname = "channel",
		tiles = gettiles(i),
		inventory_image = "digitated_digimeseexp_top.png",
		drawtype = "nodebox",
		drop = "digitated:digimeseioexp_0",
		selection_box = {
			--From luacontroller
			type = "fixed",
			fixed = { -8/16, -8/16, -8/16, 8/16, 8/16, 8/16 },
		},
		node_box = {
			--From Luacontroller
			type = "fixed",
			fixed = {
				{-8/16, 0/16, -8/16, 8/16, 1/16, 8/16}, -- Center Board
				{-5/16, 1/16, -5/16, 5/16, 2/16, 5/16}, -- Circuit board
				{-3/16, 2/16, -3/16, 3/16, 3/16, 3/16}, -- IC

                                -- Corner Pilons
				{-8/16, -8/16, -8/16, -6/16, 8/16, -6/16 },
				{ 6/16, -8/16,  6/16,  8/16, 8/16,  8/16 },
				{-8/16, -8/16,  6/16, -6/16, 8/16,  8/16},
				{ 6/16, -8/16,  -8/16,  8/16, 8/16, -6/16},

                                -- Bottom Frame
				{-6/16, -8/16, -8/16,  6/16, -7/16, -5/16},
				{-8/16, -8/16, -6/16, -5/16, -7/16, 6/16},
				{ 6/16, -8/16,  8/16, -6/16, -7/16,  5/16},
				{ 8/16, -8/16,  6/16,  5/16, -7/16, -6/16},

                                -- Top Frame
				{-6/16, 8/16, -8/16,  6/16, 7/16, -5/16},
				{-8/16, 8/16, -6/16, -5/16, 7/16, 6/16},
				{ 6/16, 8/16,  8/16, -6/16, 7/16,  5/16},
				{ 8/16, 8/16,  6/16,  5/16, 7/16, -6/16}

			}
		},
                after_place_node = digitated.autoconnect,
                after_destruct = digitated.disconnect,
		paramtype = "light",
		sunlight_propagates = true,
		on_receive_fields = function(pos, formname, fields, sender)
			local name = sender:get_player_name()
			if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
				minetest.record_protection_violation(pos,name)
				return
			end
			local meta = minetest.get_meta(pos)
			if fields.channel then meta:set_string("channel",fields.channel) end
		end,
		mesecons = {
			effector = {
				rules = ioexp_get_off_rules(i),
				action_change = ioexp_handle_mesecons,
			},
			receptor = {
				state = mesecon.state.on,
				rules = ioexp_get_on_rules(i),
			},
		},
		digiline = {
			receptor = {},
			effector = {
				action = ioexp_handle_digilines,
			},

                        wire = { rules = {
                            {x = 1, y = 0, z = 0},
                            {x =-1, y = 0, z = 0},
                            {x = 0, y = 1, z = 0},
                            {x = 0, y =-1, z = 0},
                            {x = 0, y = 0, z = 1},
                            {x = 0, y = 0, z =-1}}
                        }
		},
	})
end

minetest.register_craft({
	output = "digitated:digimeseioexp_0 ",
	recipe = {
		{"","digistuff:digimese","",},
		{"","digistuff:ioexpander_0","",},
		{"","","",},
	}
})
