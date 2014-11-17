--[[

TAGET - The 'Text Adventure Game Engine Thingy', used for the creation of simple text adventures
Copyright (C) 2013-2014 Robert Cochran and Niko Geil

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License in the LICENSE file for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

]]

local i = {};

local function splitIntoWords(str)
	if type(str) ~= "string" then
		error("str - expected string, got "..type(str), 2);
	end

	local words = {};

	for w in string.gmatch(str, "%g+") do
		words[#words + 1] = w;
	end

	return words;
end

local function handleExit()
	io.write("Are you sure you want to quit? Y/N ");
	local choice = io.read();
	
	if string.lower(tostring(choice)) == "y" then
		print("Thanks for playing!");
		os.exit();
	end
end

local function displayMap(table)
	local floor;
	
	if table[2] and tonumber(table[2]) ~= "nil" then
		floor = tonumber(table[2]);
	else
		floor = taget.player.z;
	end

	if not floor then
		io.write("\""..floor.."\" is not a valid number!\n");
		return;
	end
	
	if floor < 1 or floor > #taget.dungeon then
		io.write("There is no floor "..floor.."!\n");
		return;
	end
	
	print("Floor "..floor);
	print("--------");
	taget.world.displayFloorMap(taget.dungeon, floor, taget.player);
	io.write("\n");
end

local function status()
	print("Your stats");
	print("----------");
	print("Level : "..taget.player.level);
	print("Experience : "..taget.player.experience);
	print("Health : "..taget.player.health.."/"..taget.player.maxHealth);
	print("Attack : "..taget.player.attack);
	print("Defense : "..taget.player.defense);
	print("Next level : "..
		(taget.player.nextLevel - taget.player.experience));
	io.write("\n");
end

local keywords = {
	north = {
		n = true,
		north = true,
		f = true,
		fwd = true,
		forward = true,
	},
	
	east = {
		e = true,
		east = true,
		r = true,
		right = true,
	},
	
	south = {
		s = true,
		south = true,
		b = true,
		back = true,
		backward = true,
	},
	
	west = {
		w = true,
		west = true,
		l = true,
		left = true,
	},
};

-- TODO : Simplify move()'s internal logic some how...
-- maybe a movement delta table?

local function move(table)
	local direction = tostring(table[2]);
	local p = taget.player;
	local dungeon = taget.dungeon;
	
	if direction == "nil" then
		print("You didn't say where to go!");
		return;
	end
	
	if taget.world.getTileType(dungeon, p.x, p.y, p.z) == "ladder" then
		if direction == "u" or direction == "up" then
			if dungeon[p.z - 1] then
				if taget.world.getTileType(dungeon, p.x, p.y, p.z - 1) == "ladder" then
					p.z = p.z - 1;
					-- p.z is the new value, this is intentional
					dungeon[p.z][p.x][p.y].explored = true;
					print("Went up the ladder.\n");
				end
			else
				print("Can't move up on this ladder.\n");
			end
			
			return;
		elseif direction == "d" or direction == "down" then
			if dungeon[p.z + 1] then
				if taget.world.getTileType(dungeon, p.x, p.y, p.z + 1) == "ladder" then
					p.z = p.z + 1;
					-- See above
					dungeon[p.z][p.x][p.y].explored = true;
					print("Went down the ladder.\n");
				else
					print("Can't move down on this ladder.\n");
				end
			end
		
			return;
		end
		
	end
	
	if keywords.north[direction] then
		if dungeon[p.z][p.x][p.y - 1] then
			dungeon[p.z][p.x][p.y - 1].explored = true;
		end
	
		if taget.world.getTileType(dungeon, p.x, p.y - 1, p.z) ~= "wall" then
			if p.y > 1 then
				p.y = p.y - 1;
				print("You've moved into a "..taget.world.getTileTypePrint(dungeon, p.x, p.y, p.z).."\n");
			else
				print("Can't move into a wall!\n");
			end
		else
			print("Can't move into a wall!\n");
		end
		
		return;
	end
	
	if keywords.south[direction] then
		if dungeon[p.z][p.x][p.y + 1] then
			dungeon[p.z][p.x][p.y + 1].explored = true;
		end
		
		if taget.world.getTileType(dungeon, p.x, p.y + 1, p.z) ~= "wall" then
			if p.y < #dungeon[1][1] then
				p.y = p.y + 1;
				print("You've moved into a "..taget.world.getTileTypePrint(dungeon, p.x, p.y, p.z).."\n");
			else
				print("Can't move into a wall!\n");
			end
		else
			print("Can't move into a wall!\n");
		end
		
		return;
	end
	
	if keywords.east[direction] then
		if dungeon[p.z][p.x + 1] then
			dungeon[p.z][p.x + 1][p.y].explored = true;
		end
		
		if taget.world.getTileType(dungeon, p.x + 1, p.y, p.z) ~= "wall" then			
			if p.x < #dungeon[1] then
				p.x = p.x + 1;
				print("You've moved into a "..taget.world.getTileTypePrint(dungeon, p.x, p.y, p.z));
			else
				print("Can't move into a wall!\n");
			end
		else
			print("Can't move into a wall!\n");
		end
		
		return;
	end
	
	if keywords.west[direction] then
		if dungeon[p.z][p.x - 1] then
			dungeon[p.z][p.x - 1][p.y].explored = true;
		end
		
		if taget.world.getTileType(dungeon, p.x - 1, p.y, p.z) ~= "wall" then
			if p.x > 1 then
				p.x = p.x - 1;
				print("You've moved into a "..taget.world.getTileTypePrint(dungeon, p.x, p.y, p.z).."\n");
			else
				print("Can't move into a wall!\n");
			end
		else
			print("Can't move into a wall!\n");
		end
		
		return;
	end
	
	if direction == "u" or direction == "up" or direction == "d" or direction == "down" then
		print("You're not on a ladder!\n");
	else	
		print("Don't know of direction \""..direction.."\"!\n");
	end
end

local function look()
	local p = taget.player;
	local dungeon = taget.dungeon;

	print("You are currently in a "..
		taget.world.getTileTypePrint(dungeon, p.x, p.y, p.z));
	print("In front of you is a "..
		taget.world.getTileTypePrint(dungeon, p.x, p.y - 1, p.z));
	print("Behind you is a "..
		taget.world.getTileTypePrint(dungeon, p.x, p.y + 1, p.z));
	print("To your left is a "..
		taget.world.getTileTypePrint(dungeon, p.x - 1, p.y, p.z));
	print("To your right is a "..
		taget.world.getTileTypePrint(dungeon, p.x + 1, p.y, p.z).."\n");
end

local function attack(name)
	local e = taget.encounter;
	local p = taget.player;

	if e and e.x == p.x and e.y == p.y and e.z == p.z then
		math.randomseed(os.time());

		local defense = (e.baseDefense > 0) and
			math.random(e.baseDefense) or 0;
		
		local strength = math.random(p.attack);
		
		if strength - defense > -1 then
			e.baseHealth = e.baseHealth - (strength - defense);
		else
			-- Set strength and defense to dummy values
			-- that come out to 0, to prevent the high
			-- defense value from /adding/ health
			strength = 1; defense = 1;
		end

		print("Hit the "..e.name.." for "..
			(strength - defense).." damage!");
		print("The "..e.name.." has "..
			e.baseHealth.." hit points left!\n");
		return;
	end

	print("There's nothing to "..name[1].."!\n");
end

local function legend()
	print([[
Map Legend
----------
X - Your location
@ - A wall
# - A ladder room
. - An empty room
B - The boss room
]]);
end

local function saveGame()
	f, err = io.open("data/savefile.cfg", "w");

	if not f then
		print("Couldn't open the file for writing : "..err);
		return;
	end

	f:write("taget.player = {\n");

	for k,v in pairs(taget.player) do
		f:write("\t"..k.." = "..v..",\n");
	end

	f:write("};\n\n")
	f:write("taget.dungeon = {\n")

	for k,v in ipairs(taget.dungeon) do
		f:write("\t{\n");

		for k1,v1 in ipairs(v) do
			f:write("\t\t{\n");

			for k2,v2 in ipairs(v1) do
				f:write("\t\t\t{\n");

				for k3,v3 in pairs(v2) do
					f:write("\t\t\t\t"..k3.." = "
						..tostring(v3)..",\n");
				end

				f:write("\t\t\t},\n\n");
			end

			f:write("\t\t},\n\n");
		end

		f:write("\t},\n\n");
	end

	f:write("};\n")
	f:close()
	io.write("Game saved.\n")
end

local function restoreGame()
	local ok, err = pcall(dofile, "data/savefile.cfg");

	if not ok then
		print("Couldn't open file for reading : "..err);
		return;
	end

	io.write("Game restored!\n\n")
end

-- End normal functions

local function superAttack(input)
	taget.player.attack = taget.player.attack * 9001;
	attack(input);
	taget.player.attack = taget.player.attack / 9001;
end

local specialVerbToFunction = {
	greet_pleasently = superAttack,
	falcon_punch = superAttack,
};

local verbToFunction = {
	save = saveGame,
	restore = restoreGame,
	load = restoreGame,
	exit = handleExit,
	quit = handleExit,
	map = displayMap,
	stats = status,
	status = status,
	go = move,
	move = move,
	look = look,
	attack = attack,
	hit = attack,
	punch = attack,
	legend = legend,
};

function i.processInput()
	local input = splitIntoWords(io.read());
	
	if input[1] == "" or input[1] == nil then
		return;
	elseif input[1] == "help" then
		print("I know of these words : ");
		
		for k in pairs(verbToFunction) do
			print(k);
		end
		
		io.write("\n");
	elseif verbToFunction[input[1]] then
		verbToFunction[input[1]](input);
	elseif specialVerbToFunction[input[1]] then
		specialVerbToFunction[input[1]](input);
	else
		print("I don't know \""..input[1].."\"!");
	end
	
	return;
end

function i.chooseLevelUp()
	print("Your stats are currently : ");
	print("Max health : "..taget.player.maxHealth);
	print("Attack : "..taget.player.attack);
	print("Defense : "..taget.player.defense);
	
	print("Which would you like to upgrade?");
	
	local input = io.read();

	if input == "health" or input == "h" then
		taget.player.maxHealth = taget.player.maxHealth + 1;
		print("Your max health is now "..taget.player.maxHealth);
	elseif input == "attack" or input == "a" then
		taget.player.attack = taget.player.attack + 1;
		print("Your attack is now "..taget.player.attack);
	elseif input == "defense" or input == "d" then
		taget.player.defense = taget.player.defense + 1;
		print("Your defense is now "..taget.player.defense);
	end
end

return i;
