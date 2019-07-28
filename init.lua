xp = {}
xp.lvl = 20
xp.xp_hud = {}
xp.level_hud = {}
xp.custom_level_system = false

function xp.set_level_hud_text(player, str)
	player:hud_change(xp.level_hud[player:get_player_name()], "text", str)
end

function xp.getXp(player)
    local meta= player:get_meta()
    local xp = meta:get_int('xp')
	return xp
end

function xp.getLv(player)
    local meta= player:get_meta()
    local lv = meta:get_int('lv')
    return lv
	
end

function xp.get_xp(lvl, x)
	return (xp.lvl * lvl) / x
end

function xp.add_xp(player, num)
    local meta = player:get_meta()
    local oldXp = xp.getXp(player)
    meta:set_int('xp',oldXp + num)
    print(xp.getXp(player))
    

 	if xp.getXp(player) > xp.lvl * xp.getLv(player) then
 		meta:set_int('xp', xp.getXp(player) - (xp.lvl * xp.getLv(player)))
 		xp.add_lv(player)
 	end
 	print("[info] xp for player ".. player:get_player_name() .. " " .. xp.getXp(player).."/".. xp.lvl * xp.getLv(player).." = " .. xp.getXp(player) / ( xp.lvl * xp.getLv(player)))
 	player:hud_change(xp.xp_hud[player:get_player_name()], "number", 20 * ((xp.getXp(player)) / (xp.lvl * xp.getLv(player))))
end

function xp.add_lv(player)
    local meta = player:get_meta()
    local oldLv = xp.getLv(player)
    meta:set_int('lv',oldLv + 1)
    print(xp.getLv(player))
	if not(xp.custom_level_system) then
		player:hud_change(xp.level_hud[player:get_player_name()], "text", xp.getLv(player))
	end
end

function xp.JoinPlayer()
	minetest.register_on_joinplayer(function(player)
		if not player then
			return
		end
		if xp.getXp(player) and xp.getLv(player) then
			xp.xp_hud[player:get_player_name()] = player:hud_add({
				hud_elem_type = "statbar",
				position = {x=0.5,y=1.0},
				size = {x=16, y=16},
				offset = {x=-(32*8+16), y=-(48*2+16)},
				text = "xp_xp.png",
				number = 20*((xp.getXp(player))/(xp.lvl * xp.getLv(player))),
			})
			xp.level_hud[player:get_player_name()] = player:hud_add({
				hud_elem_type = "text",
				position = {x=0.5,y=1},
				text = xp.getLv(player),
				number = 0xFFFFFF,
				alignment = {x=0.5,y=1},
				offset = {x=0, y=-(48*2+16)},
			})
		else
			print(tostring('something, somewhere is going wrong'))
		end
	end)
end

function xp.NewPlayer()
	minetest.register_on_newplayer(function(ObjectRef)
        local meta = ObjectRef:get_meta()
        meta:set_int('xp',1)
        meta:set_int('lv',1)

        
	end)
end

function xp.explorer_xp()
	minetest.register_on_generated(function(minp, maxp, blockseed)
		local center={x=minp.x+math.abs(minp.x-maxp.x),y=minp.y+math.abs(minp.y-maxp.y),z=minp.z+math.abs(minp.z-maxp.z)}
		local player=nil
		local top = nil
		for i,v in pairs(minetest.get_connected_players()) do
			local pos =v:getpos()
			local dist=vector.distance(center, pos)
			if player==nil then
				player = v
				top = dist
				
			elseif dist  < top then  
				top = dist
				player = v			
			end
		end
		xp.add_xp(player, 1)	
	end) 
end

function xp.crafter_xp()
	minetest.register_on_craft(function(itemstack, player)
		local craft_xp = itemstack:get_definition().craft_xp
		if craft_xp then
			xp.add_xp(player, craft_xp)
		end
	end)
end

function xp.miner_xp()
	minetest.register_on_dignode(function(pos, oldnode, digger)
		local miner_xp = minetest.registered_nodes[oldnode.name].miner_xp
		local player = digger:get_player_name()
		local player_lvls = skills.lvls[player]
		if not miner_xp then
		elseif miner_xp.rm then
			if player_lvls then
				xp.add_xp(digger, (player_lvls["miner"]-1))
			end
		elseif miner_xp.lvls then
			if player_lvls and player_lvls["miner"] > 5 then
				xp.add_xp(digger,xp.getLv(digger), 14)
			end
		elseif miner_xp.rnd then
			if math.random(miner_xp.rnd) == miner_xp.rnd then
				xp.add_xp(digger, miner_xp.xp)	
			end
		elseif miner_xp.xp then 
			xp.add_xp(digger, miner_xp.xp)
		end
	end)
end

function xp.builder_xp()
	minetest.register_on_placenode(function(pos, newnode, placer)
		local builder_xp = minetest.registered_nodes[newnode.name].builder_xp
		if builder_xp then
			xp.add_xp(placer, builder_xp)
		end
	end)
end

xp.NewPlayer()
xp.JoinPlayer()

xp.miner_xp()
xp.crafter_xp()
xp.explorer_xp()
xp.builder_xp()
