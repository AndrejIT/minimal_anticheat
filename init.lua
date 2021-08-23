-- Minetest 0.4.13+ mod: minimal_anticheat
-- Make cheating harder as possible without sacraficing too much performance
--
-- See README.txt for licensing and other information.

minimal_anticheat = {}
minimal_anticheat.clip_nodes = {
    ["default:stone"]=1, ["default:cobble"]=1, ["default:stonebrick"]=1, ["default:obsidian"]=1, ["default:obsidianbrick"]=1,
    ["default:dirt"]=1, ["default:dirt_with_grass"]=1,
    -- ["ignore"]=1,
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
			local pos1 = player:get_pos()
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

        local is near_teleport_or_spawn = false
        if _G["teleports"] and teleports.teleports then
            for i, EachTeleport in ipairs(teleports.teleports) do
                if vector.distance(EachTeleport.pos, pos) < 5 then
                    near_teleport_or_spawn = true
                end
            end
        end

        local is_near_block_mover = false
        -- for now only support "electricity" mod piston.
        local positions = minetest.find_nodes_in_area(
            {x=pos.x-2, y=pos.y-2, z=pos.z-2},
            {x=pos.x+2, y=pos.y+2, z=pos.z+2},
            {"electricity:piston_pusher_sticky"})
        if #positions > 0 then
            is_near_block_mover = true
        end

        if is_near_block_mover then
            minetest.chat_send_all("Player "..name.." is crushed");
            minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." not suspected in noclip cheat - inwall");
        elseif near_teleport_or_spawn then
            minetest.chat_send_all("Player "..name.." had teleportation accident");
            minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." not suspected in noclip cheat - inwall");
        else
            minetest.chat_send_all("Player "..name.." suspected in noclip cheat");
            minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." suspected in noclip cheat - inwall");
        end
    end
end

minimal_anticheat.check_cheater_in_wall = function ()
	for _,player in pairs(minetest.get_connected_players()) do
		if math.random(1, 100) > 50 and player and player:is_player() then
			local pos1 = player:get_pos()
            local pos2 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
			if player:get_hp() > 0 then	--check noclip cheaters
				local n1 = minetest.get_node(pos1)
                local n2 = minetest.get_node(pos2)
				if minimal_anticheat.clip_nodes[n1.name] == 1 and minimal_anticheat.clip_nodes[n2.name] == 1 then
                    local info = minetest.get_player_information(player:get_player_name())
                    if info['connection_uptime'] > 16 then
                        --after some delay check again, may-be that was just lag while digging
    					minetest.after(4.0, minimal_anticheat.secondary_check_cheater_in_wall, player, pos2)
                    else
                        --maybe somebody just built where player was located before
                        player:set_pos({x=0, y=3, z=0})
                    end
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
			local pos = player:get_pos()
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

                    -- area may be just legitimately not loaded yet
                    local is near_teleport_or_spawn = false
                    if _G["teleports"] and teleports.teleports then
                        for i, EachTeleport in ipairs(teleports.teleports) do
                            if vector.distance(EachTeleport.pos, pos) < 3 then
                                near_teleport_or_spawn = true
                            end
                        end
                    end

                    if near_teleport_or_spawn then
                        minetest.chat_send_all("Player "..name.." had teleportation accident");
                        minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." not suspected in fly cheat");
                    else
                        minetest.chat_send_all("Player "..name.." suspected in fly cheat");
                        minetest.log("action", "Player "..name.." at "..minetest.pos_to_string(vector.round(pos)).." suspected in fly cheat");
                    end
				end
			end
		end
	end
	minetest.after(16.0, minimal_anticheat.check_cheater_on_air)
end
minetest.after(16.0, minimal_anticheat.check_cheater_on_air)

-- Count how many times engine triggered for player
minimal_anticheat.count_engine = {}

--testing built-in anticheat engine...
minimal_anticheat.check_cheater_by_engine = function (player, cheat)
    if player:is_player() then
        local name = player:get_player_name()
        local pos = player:get_pos()
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
            end
        elseif cheat.type == "interacted_too_far" then
            --it happens to regular players too, so don't be too harsh...
            if minimal_anticheat.count_engine[name] ~= nil and (minimal_anticheat.count_engine[name]) % 10 == 0 then
                if player:get_hp() > 0 then
                    player:punch(player, 1.0,  {
                            full_punch_interval=1.0,
                            damage_groups = {fleshy=4}
                        }, {x=0, y=-1, z=0})
                    minetest.chat_send_all("Player "..name.." suspected in too far cheat (maybe) "..minimal_anticheat.count_engine[name]);
                end
            end
        elseif cheat.type == "moved_too_fast" then
            --it happens to regular players too, so don't be too harsh...
            if minimal_anticheat.count_engine[name] ~= nil and (minimal_anticheat.count_engine[name]) % 10 == 0 then
                if player:get_hp() > 0 then
                    player:punch(player, 1.0,  {
                            full_punch_interval=1.0,
                            damage_groups = {fleshy=4}
                        }, {x=0, y=-1, z=0})
                    minetest.chat_send_all("Player "..name.." suspected in too fast cheat (maybe) "..minimal_anticheat.count_engine[name]);
                end
            end
        elseif cheat.type == "dug_unbreakable" then
            --it happens to regular players too?
            if minimal_anticheat.count_engine[name] ~= nil and (minimal_anticheat.count_engine[name]) % 10 == 0 then
                if player:get_hp() > 0 then
                    player:punch(player, 1.0,  {
                            full_punch_interval=1.0,
                            damage_groups = {fleshy=4}
                        }, {x=0, y=-1, z=0})
                    minetest.chat_send_all("Player "..name.." suspected in dug unbreakable cheat (maybe) "..minimal_anticheat.count_engine[name]);
                end
            end
        elseif cheat.type == "interacted_while_dead" then
            --it happens to regular players too?
            if minimal_anticheat.count_engine[name] ~= nil and (minimal_anticheat.count_engine[name]) % 10 == 0 then
                if player:is_player() then
                    -- no point to punching dead, so kick him.
                    minetest.after(math.random(0,30)/10, function(name)
                        local player = minetest.get_player_by_name(name)
                        if player == nil then
                            minetest.log("warning", "Dead cheater is not present for kick")
                        end
                        minetest.kick_player(name, "Player "..name.." suspected in dead cheat (maybe)")
                    end, name)
                    minetest.chat_send_all("Player "..name.." suspected in dead cheat (maybe) "..minimal_anticheat.count_engine[name]);
                end
            end
        elseif 1 then
          --nothing
        end

        if minimal_anticheat.count_engine[name] == nil then
            minimal_anticheat.count_engine[name] = 1
        else
            minimal_anticheat.count_engine[name] = minimal_anticheat.count_engine[name] + 1
        end
    end
end
minetest.register_on_cheat(minimal_anticheat.check_cheater_by_engine)
