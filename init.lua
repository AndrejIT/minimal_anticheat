-- Minetest 0.4.13+ mod: minimal_anticheat
-- Make cheating harder as possible without sacraficing too much performance
--
-- See README.txt for licensing and other information.

minimal_anticheat = {}
minimal_anticheat.clip_nodes = {
    ["default:stone"]=1, ["default:cobble"]=1, ["default:stonebrick"]=1, ["default:obsidian"]=1, ["default:obsidianbrick"]=1,
    ["default:dirt"]=1, ["default:dirt_with_grass"]=1, ["ignore"]=1
}
minimal_anticheat.sureclip_nodes = {
    ["default:stone_with_coal"]=1, ["default:default:stone_with_iron"]=1, ["default:stone_with_copper"]=1,
    ["default:stone_with_gold"]=1, ["default:stone_with_mese"]=1, ["default:stone_with_diamond"]=1
}

minimal_anticheat.secondary_check_cheater_on_coal = function(player, pos)
    if player and player:is_player() and player:get_hp() > 0 and
        (minimal_anticheat.sureclip_nodes[minetest.get_node(pos).name] == 1 or
         minimal_anticheat.clip_nodes[minetest.get_node(pos).name] == 1)  then
        player:punch(player, 1.0,  {
                full_punch_interval=1.0,
                damage_groups = {fleshy=20}
            }, {x=0, y=1, z=0})
        local name = player:get_player_name()
        minetest.chat_send_all("Player "..name.." suspected in noclip cheat");
        minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." suspected in noclip cheat - oncoal");
    end
end
minimal_anticheat.check_cheater_on_coal = function ()
	for _,player in pairs(minetest.get_connected_players()) do
		if math.random(1, 100) > 50 and player and player:is_player() then
			local pos1 = player:getpos()
            local pos2 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
			if player:get_hp() > 0 and pos1.y < -50 then	--check noclip miners
				local n1 = minetest.get_node(pos1)
                local n2 = minetest.get_node(pos2)
				if minimal_anticheat.sureclip_nodes[n1.name] == 1 or minimal_anticheat.sureclip_nodes[n2.name] == 1 then
                    --after some delay check again, may-be that was just lag while digging
					minetest.after(5.0, minimal_anticheat.secondary_check_cheater_on_coal, player, pos2)
				end
			end
		end
	end
	minetest.after(8.0, minimal_anticheat.check_cheater_on_coal)
end
minetest.after(8.0, minimal_anticheat.check_cheater_on_coal)

minimal_anticheat.secondary_check_cheater_in_wall = function(player, pos)
    if player and player:is_player() and player:get_hp() > 0 and
        minimal_anticheat.clip_nodes[minetest.get_node(pos).name] == 1 then
        player:punch(player, 1.0,  {
                full_punch_interval=1.0,
                damage_groups = {fleshy=10}
            }, {x=0, y=1, z=0})
        local name = player:get_player_name()
        minetest.chat_send_all("Player "..name.." suspected in noclip cheat");
        minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." suspected in noclip cheat - inwall");
    end
end
minimal_anticheat.check_cheater_in_wall = function ()
	for _,player in pairs(minetest.get_connected_players()) do
		if math.random(1, 100) > 50 and player and player:is_player() then
			local pos1 = player:getpos()
            local pos2 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
			if player:get_hp() > 0 then	--check noclip cheaters
				local n1 = minetest.get_node(pos1)
                local n2 = minetest.get_node(pos2)
				if minimal_anticheat.clip_nodes[n1.name] == 1 and minimal_anticheat.clip_nodes[n2.name] == 1 then
                    --after some delay check again, may-be that was just lag while digging
					minetest.after(4.0, minimal_anticheat.secondary_check_cheater_in_wall, player, pos2)
				end
			end
		end
	end
	minetest.after(8.0, minimal_anticheat.check_cheater_in_wall)
end
minetest.after(8.0, minimal_anticheat.check_cheater_in_wall)

minimal_anticheat.check_cheater_on_air = function ()
	for _,player in pairs(minetest.get_connected_players()) do
		if math.random(1, 100) > 50 and player and player:is_player() then
			local pos = player:getpos()
			if player:get_hp() > 0 and pos.y > 10 then	--check on air
				local positions = minetest.find_nodes_in_area(
						{x=pos.x-3, y=pos.y-3, z=pos.z-3},
						{x=pos.x+3, y=pos.y+3, z=pos.z+3},
						{"air", "ignore"})
				if #positions == 343 then   --only air around
					player:punch(player, 1.0,  {
							full_punch_interval=1.0,
							damage_groups = {fleshy=18}
						}, {x=0, y=-1, z=0})
                    local name = player:get_player_name()
                    minetest.chat_send_all("Player "..name.." suspected in fly cheat");
                    minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." suspected in fly cheat");
				end
			end
		end
	end
	minetest.after(16.0, minimal_anticheat.check_cheater_on_air)
end
minetest.after(16.0, minimal_anticheat.check_cheater_on_air)

--testing built-in anticheat engine...
minimal_anticheat.check_cheater_by_engine = function (player, cheat)
    if player:is_player() then
        local name = player:get_player_name()
        local pos = player:getpos()
        local text_pos = minetest.pos_to_string(vector.round(pos))
        minetest.log("action", "Player "..name.." at "..text_pos.." suspected in some cheat: "..cheat.type);
        if cheat.type == "dug_too_fast" then
            -- looks like this one has almost no false-positives, punish him hard.
            if player:get_hp() > 0 then
                player:punch(player, 1.0,  {
                        full_punch_interval=1.0,
                        damage_groups = {fleshy=4}
                    }, {x=0, y=-1, z=0})
                minetest.chat_send_all("Player "..name.." suspected in dig cheat");
                minetest.log("action", "Player "..name.." at "..text_pos.." suspected in dig cheat");
            end
        elseif cheat.type == "interacted_too_far" then
            --it happens to regular players too, so don't be too harsh...
            if math.random(1, 100) > 80 then
                if player:get_hp() > 0 then
                    player:punch(player, 1.0,  {
                            full_punch_interval=1.0,
                            damage_groups = {fleshy=4}
                        }, {x=0, y=-1, z=0})
                    minetest.chat_send_all("Player "..name.." suspected in too far cheat (maybe)");
                    minetest.log("action", "Player "..name.." at "..text_pos.." suspected in too far cheat");
                end
            end
        elseif cheat.type == "moved_too_fast" then
            --it happens to regular players too, so don't be too harsh...
            if math.random(1, 100) > 90 then
                if player:get_hp() > 0 then
                    player:punch(player, 1.0,  {
                            full_punch_interval=1.0,
                            damage_groups = {fleshy=4}
                        }, {x=0, y=-1, z=0})
                    minetest.chat_send_all("Player "..name.." suspected in too fast cheat (maybe)");
                    minetest.log("action", "Player "..name.." at "..text_pos.." suspected in too fast cheat");
                end
            end
        elseif 1 then
          --nothing
        end
    end
end
minetest.register_on_cheat(minimal_anticheat.check_cheater_by_engine)
