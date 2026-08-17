pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- tab 0: main loop

-- :::nb: load platform_engine_fork.p8  :::

function _init()

	player = {scrxpos=48, scrypos=48, mapxpos=0, mapypos=0, celx=0, cely=0, momentx=0, momenty=0, state=0, frame=2, animcount=1, animswitch = 1, health=2, inv_count=0, facing = 1, top_spd=2, ent_type='player', input_field=0}

	npc = {scrxpos=64, scrypos=48, mapxpos=0, mapypos=0, celx=0, cely=0, momentx=0, momenty=0, state=0, frame=2, animcount=1, animswitch = 1, health=1, inv_count=0, facing = 1, top_spd=1, ent_type='enemy', input_field=0}

	entities = {player, npc}

	jump_held = 0

	-- notes: mapxpos and ypos track which screen object is on
	-- facing = -1 if left, 1 if right, to simplify momentum code
	-- states: 0 = idle, 1 = moving (accelerating), 2 = jumping/falling,
	-- 3 = mantling, 4 = dead,  5 = climbing
	devtracker = 0

	-- flags 0 - 3 reserved for map functions, flags 4 - 7 generally for actors
	
	f_collide = 0b0001	-- flag 0 = collision
	f_mantle = 0b0010	-- flag 1 = mantle
	f_climb = 0b0100 -- flag 2 = climb

	left_fld = 0b0001
	right_fld = 0b0010
	up_fld = 0b0100
	down_fld = 0b1000

end




function _update()
	
	for entity in all(entities) do

    	construct_input_fields(entity)
		move_entities(entity)
		check_object_state(entity)
	
	end
	
	
	

end




function _draw()

	cls()
	
	map(0, 0, 0, 0, 128, 128, 0)
	
	for entity in all(entities) do
    	draw_objects(entity)
	end
--	print(devtracker, 0, 8)
	

end

function draw_objects(object)

	

	if flr(object.inv_count/4)%2 == 0 then		--animcount more than 12 on inv frames
		if object.facing == 1 then
			spr((object.state*3)+object.frame, object.scrxpos, object.scrypos)
			spr((object.state*3)+object.frame+16, object.scrxpos, object.scrypos+8)
		else
			spr((object.state*3)+object.frame, object.scrxpos, object.scrypos, 1, 1, true)
			spr((object.state*3)+object.frame+16, object.scrxpos, object.scrypos+8, 1, 1, true)
		end

		
		--x origin on map, y orig on map, xpos on screen, ypos on screen, x height, y height, flag
		--rect(object.celx*8, object.cely*8,(object.celx*8)+8,(object.cely*8)+16)
		if (object.ent_type == 'player') print(object.state, 0, 0)
		if (object.ent_type == 'player') print(object.health, 0, 8)
		if (object.ent_type == 'enemy') spr(33, object.scrxpos,object.scrypos)
	end
	

end
-->8

-- tab 1: check object state



function check_object_state(object)   

	if object.state == 0 then  --0 = idle
		object_idle(object)
	elseif object.state == 1 then	-- 1 = moving
		object_move(object)
	elseif object.state == 2 then	-- 2 = jumping
		object_jump(object)
	elseif object.state == 3 then	-- 3 = mantling
		object_mantle(object)
	elseif object.state == 4 then	-- 4 = climbing
		object_climb(object)
--	elseif object.state == 5 then	-- 5 = dead
--		object_dead(object)
	end

	if (object.inv_count == 24) object.inv_count = 0

end

function reset_state(object, new_state)

	object.animcount = 0
	object.frame = 2
	object.animswitch = 1
	object.state = new_state

end

function object_idle(object)

	object.momentx = 0
	object.momenty = 0

	if object.animcount < 3 then	-- checks ticks elapsed for frame
		object.animcount += 1

	else

		object.animcount = 0

		if object.frame == 2 then	-- oscillates back and forth over 2, between 1 and 3 inclusive
			object.frame += object.animswitch
		else
			object.animswitch = object.animswitch * -1
			object.frame += object.animswitch
		end

	end

	if (btn(2) and (check_map_collision(object, 'y') & f_climb) == f_climb) reset_state(object, 4)

	
	if (object.input_field & up_fld) == up_fld then				-- checks input to leave state
		object.cely -= 1		-- change cely to check collision
		object.momenty = -3.3		-- change momentum to check collision
		if ((check_map_collision(object, 'y') & f_collide) == f_collide) then		-- checks bitfield for flag 0 (0b0001)
			object.state = 0
			object.momenty = 0
		else
			reset_state(object, 2)		-- else: object has headroom, change state to jumping
		end								-- nb: this all needs doing out of order to avoid drawing while in state 2
	elseif (object.input_field & left_fld) == left_fld then
		object.facing = -1
		reset_state(object, 1)
		object_move(object)
	elseif (object.input_field & right_fld) == right_fld then
		object.facing = 1
		reset_state(object, 1)
		object_move(object)
	end

end

function object_move(object)


	if (object.facing == -1 and ((object.input_field & left_fld) == left_fld)) or (object.facing == 1 and ((object.input_field & right_fld) == right_fld)) then	-- checks if button pushed in direction of travel
		if (object.momentx == 0) object.momentx += (0.2*object.facing)	-- gives a little boost when starting off
		object.momentx += (0.5*object.facing)	-- accelerates
	else
		if abs(object.momentx) < 0.6 then		-- if within 0.6 of stopping, stops
			object.momentx = 0
			object.state = 0
		else									-- else: slows down
			object.momentx -= (0.5*object.facing)
			object.state = 1					-- (function object_slow moved here) 
		end							
	end

	if ((object.input_field & left_fld) == left_fld) object.facing = -1
	if ((object.input_field & right_fld) == right_fld) object.facing = 1

	if object.animcount < 4 then	-- checks ticks elapsed for frame
		object.animcount += 1

	else

		object.animcount = 0

		if object.frame == 2 then	-- oscillates back and forth over 2, between 1 and 3 inclusive
			object.frame += object.animswitch
		else
			object.animswitch = object.animswitch * -1
			object.frame += object.animswitch
		end

	end

	if (object.input_field & up_fld) == up_fld then			-- check if jump hit to exit state
		if (check_map_collision(object, 'y') & f_climb) == f_climb then
			reset_state(object, 4)
		else
			object.cely -= 1		-- change cely to check collision
			object.momenty = -3.3		-- change momentum to check collision
			if ((check_map_collision(object, 'y') & f_collide) == f_collide) then		-- checks bitfield for flag 0 (0b0001)
				object.state = 1
				object.momenty = 0
			else
				reset_state(object, 2)		-- else: object has headroom, change state to jumping
			end								-- nb: this all needs doing out of order to avoid drawing while in state 2
		end
	end

end


function object_jump(object)

	if object.inv_count == 0 then
        if ((collide_value & f_climb) == f_climb) and btn(2) then
            object.momentx = 0
            object.momenty = 0
            reset_state(object, 4)
        end
    end

	if object.inv_count != 0 then
		object.inv_count += 1
		object.frame = 3
	elseif object.momenty < -0.5 then
		object.frame = 1
	elseif object.momenty < 0.5 then
		object.frame = 2
	else
		object.frame = 3
	end

	if abs(object.momentx) < 2 and (object.inv_count == 0 or object.inv_count > 24) then	-- respond to input while jumping if in correct speed bound, and not injured
		if ((object.input_field & left_fld) == left_fld) object.momentx -= 0.1
		if ((object.input_field & right_fld) == right_fld) object.momentx += 0.1
		if ((abs(object.momentx) > 0.2) and object.inv_count == 0) object.facing = object.momentx / abs(object.momentx) -- cunning code: returns -1 if momentx negative, 1 if positive.
	end



end

function object_mantle(object)

	if abs(object.animswitch) == 1 then

		object.scrxpos = object.celx*8
		object.scrypos = object.cely*8

		if (object.input_field & 0b1111) == 8 then  -- checks if only down (just btn 3 = 0b1000) pressed
			reset_state(object, 2)
			object.momenty = -0.2
		end

		if (object.facing == -1 and ((object.input_field & right_fld) == right_fld)) or (object.facing == 1 and ((object.input_field & left_fld) == left_fld)) then -- drop if object pressed away from ledge
			object.facing *= -1
			reset_state(object, 2)
			object.momentx += 0.4 * object.facing
			object.momenty = -0.2
		elseif (object.input_field & up_fld) == 4 then -- if jump pressed, break breathing animation cycle
			object.animcount = 0
			object.animswitch = 2	
		end
	
		object.animcount += 1	-- roll on animation count

		if object.animcount > 8 then	-- check if animation cycle ended
			object.animcount = 0	-- reset animation count, 
			object.frame += object.animswitch	--add animswitch to frame
			object.animswitch *= -1		-- flip animswitch - flip-flops between frames
		end

	else

		object.frame = 3

		if object.animcount == 4 then	-- object spends 4 ticks on jumping frame, then jumps
			
			reset_state(object, 2)
			object.momentx = 1*object.facing
			object.momenty = -3.3

		else

			object.animcount += 1
		
		end

	end

end

function object_climb(object)



end
-->8
-- tab 2: move entities

function move_entities(object)

    object.momenty += 0.3
    if (object.momenty > 4.0) object.momenty = 4.0

    if (abs(object.momentx) > object.top_spd) object.momentx = object.top_spd*object.facing

    if object.ent_type == 'player' and (object.inv_count == 0) then
        if check_actor_collision(object) == 'enemy' then
            object.inv_count = 1
            reset_state(object, 2)
            object.momentx = -1*object.facing
            object.momenty = -2.5
            object.health -= 1
        end
    end
    
    object.celx = flr((object.scrxpos+object.momentx+4)/8)
    object.cely = flr((object.scrypos+object.momenty)/8)

    collide_value = check_map_collision(object, 'y')    -- check_object_collision returns bitfield, collide_value avoids calling the function over and over
    
--    if object.inv_count == 0 then
--        if ((collide_value & f_climb) == f_climb) and ((object.input_field & up_fld) == up_fld) then
--            object.momentx = 0
--            object.momenty = 0
--            reset_state(object, 4)
--        end
--    end

    if object.state != 3 and object.state != 4 then                   -- don't do collision check if object mantling
        if (collide_value%2) == 1 then  -- cunning code: checks if flag bitfield is even - only odd if flag 0 in field
            if object.inv_count == 0 then         -- if not injured, change state if on solid ground
                if object.momentx != 0 then          -- important: check if object has x momentum; if so, running.
                    object.state = 1                -- don't use reset_state, to preserve frame
                else
                    object.state = 0
                end
            end
            if object.momenty < 0 then
                object.scrypos = 8*(object.cely+1)
            else
                object.scrypos = 8*object.cely
            end
            object.momenty = 0
        else
            object.scrypos += object.momenty
            object.state = 2
        end
    end
                                                        -- nb for x collision: tracks one cel in front of object, by facing




    if object.state == 1 or object.state == 2 then      -- if object moving or jumping
        
        collide_check = check_map_collision(object, 'x')

        --collide, mantle = check_object_collision(object, 'x')
        devtracker = collide_check & f_collide
        if ((collide_check & f_collide) == f_collide) then      -- check if object should be colliding - bitfield checks for flag 0
            object.momentx = 0
            object.scrxpos = 8*(object.celx)
        else
            object.scrxpos += object.momentx
        end

        if object.state == 2 and object.inv_count == 0 and ((collide_check & f_mantle) == f_mantle) and ((object.input_field & 0b0011) != 0) then     -- check if object should be mantling - pressing left or right while hitting flag 1
            reset_state(object, 3)      -- mantle check done here for function order
            object.animswitch = -1
            object.momenty = 0
            object.scrypos = 8*object.cely
        end

    end

    



end

-->8
--tab 3: check collision

function check_map_collision(object, axis)       
    -- function returns a bitfield showingthe flags in target cel,
    --depending on object movement and specified axis to check

--    if object.ent_type == 'player' then
        if axis == 'y' then     -- are we checking y axis collision?
            if object.momenty >= 0 then         --check if object moving down
                return fget(mget(object.celx, object.cely+2))  -- check if object will hit platform while falling
            else        -- else: player moving up, or stationary
                return fget(mget(object.celx, object.cely))     -- check if object will "bump head", hit ladder
            end
        else        -- else: we're checking x axis collision
            if object.state != 3 and object.state !=4 then
                
                x_collide_field = fget(mget(object.celx+object.facing, object.cely))

                if x_collide_field != 0 then    -- has upper body hit smth?
                    return x_collide_field
                else    -- else: return code for lower body minus mantle (flag 1 = 0b0010) - no mantling with legs
                    return (fget(mget(object.celx+object.facing, object.cely+1)) & 0b1101)
                end

            end

        end
--    end

end

function check_actor_collision(object)

    for coll_target in all(entities) do
        if object != coll_target then
            if (object.scrxpos+object.momentx < coll_target.scrxpos+8) and (object.scrxpos+8+object.momentx > coll_target.scrxpos) then
                if (object.scrypos+object.momenty < coll_target.scrypos+8) and (object.scrypos+8+object.momenty > coll_target.scrypos) then
                    return coll_target.ent_type
                end
            end
        end
    end

end
-->8
-- tab 4: construct_input_fields


function construct_input_fields(object)

    if object.ent_type == 'player' then
        object.input_field = btn()
        if (jump_held > 2) object.input_field = (object.input_field & 0b1011) -- scrubs 4 (btn 2) out of bitfield if jump held
        if btn(2) then
            jump_held += 1
        else
            jump_held = 0
        end
    else
        object.celx += object.facing
        object.input_field = np_object_input(object)
        object.celx = flr((object.scrxpos+object.momentx+4)/8)
    end

end

function np_object_input(object)

    if object.facing == 1 then       -- this could be made more elegant, i feel
        if (check_map_collision(object, 'y') & f_collide) == f_collide then
            return right_fld
        else
            return left_fld
        end
    else
        if (check_map_collision(object, 'y') & f_collide) == f_collide then
            return left_fld
        else
            return right_fld
        end
    end

end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000660000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000606600000066000000000000000000000060660000000000000000000000000
00700700000660000000000000000000000000000000000000000000000660000006600000066000000660060000000600000000060660000006606000000000
00077000060660000606600000000000000060000000600000000600000660000000000000000000060660060606600600006600000660000006600000000000
00077000000000000006600006066000000006600000066000000066006000000066600000666600000000600006606000006066000000600600000000000000
00700700000660000000000000066000000006600000066000000066000660000606660006066060006660000000000000000000006660600006660000000000
00000000006660000006600000000000000060000000600000000600006660000606660060066060060660000006600000006600060660000066600000000000
00000000000666000066600000066000006066000006660000066660060066000006606000066000060660000606600000000060060660000006606000000000
00000000060666000006660000666000000066000066600000600660060660600000000000060000000060000600600000000060000600000000000000000000
00000000060660600606606000066600000006600000060006000006000600000006060000006600000000000000000000000006000000000060600000000000
00000000000600000006000006060060000600000006000000006000000606000000606000000060000606000006060000000000000060000060000000000000
00000000006000000060000000000000000606000000600000000600000606000000600000006000000060600000606000000000006060000000060000000000
00000000006006000060060000600600000600600000600000060060006006000000006000000006000006000000060000000000006060000060060000000000
00000000006006000060060000600600006000600060600000600060060000000006000000000000000000600000006000000000000000000000000000000000
00000000000006000000060000000600060000060000060000000006000006000000000000000000000000000000000000000000000060000000000000000000
00000000006000600060006000600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cddddddddddddddddddddddc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dd1d1d1d1d1d1d1d1d1d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd1d1d1d1d1d1d1d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06555560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003010300000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000000525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000000525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000000525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000004041420000525000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000040414266666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0066404141414141414141414141420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000066666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000066666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000006666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
