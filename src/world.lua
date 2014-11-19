--[[

TAGET - The 'Text Adventure Game Engine Thingy', used for the creation of simple text adventures
Copyright (C) 2013-2014 Robert Cochran

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

local w = {};

w.pathfinder = require("pathfinder");

-- {{{
-- Note : ensure 'wall' is always the last entry,
-- otherwise pathfinder logic will be broken.

w.room = table.setReadOnly{
	standard = 1,
	chest = 2,
	shop = 3,
	boss = 4,
	ladder = 5,
	wall = 6,
};

w.direction = table.setReadOnly{
	north = 1,
	east = 2,
	south = 3,
	west = 4,
};

-- }}}

function w.generateDungeon(floors, width, length, suppressMessages)
	if type(floors) ~= "number" then
		error("floors - expected number, got "..type(floors), 2);
	end
	
	if type(width) ~= "number" then
		error("width - expected number, got "..type(floors), 2);
	end
	
	if type(length) ~= "number" then
		error("length - expected number, got "..type(floors), 2);
	end

	local start_time = os.clock();

	dungeon = {};
	specials = {};

	local idCount = 1;
	
	for a = 1, floors do
		dungeon[a] = {};
		specials[a] = {};

		for b = 1, width do
			dungeon[a][b] = {};
			specials[a][b] = {};

			for c = 1, length do
				dungeon[a][b][c] = {
					type = w.room.standard,
					explored = false,
					id = idCount,
				};

				idCount = idCount + 1;
				
				specials[a][b][c] = 1;
			end
		end
	end

	-- Change the spawnpoint to 'explored'
	dungeon[1][math.ceil(width / 2)][math.ceil(length / 2)].explored = true;

	if not suppressMessages then print("Generating ladders...") end
	
	for i = 1, (floors - 1) do
		while true do
			math.randomseed(os.time() * math.random());

			local j = math.random(width);
			local k = math.random(length);

			if i == 1 and (j == math.ceil(width / 2) and
				       k == math.ceil(length / 2)) then
				-- The spawnpoint is here, avoid it
				goto ladder_continue;
			elseif dungeon[i][j][k].type == w.room.ladder then
				-- Already occupied, avoid here too
				goto ladder_continue;
			else
				dungeon[i][j][k].type = w.room.ladder;
				w.pathfinder.createEndpoint(i, j, k);

				dungeon[i + 1][j][k].type = w.room.ladder;
				break;
			end

			::ladder_continue::;
		end
	end

	-- TODO : Add a proper inventory system, then finish
	-- implementing shops and loot chests.

	--[[if not suppressMessages then print("Generating shops...") end

	for i = 1, floors, 5 do
		while true do
			math.randomseed(os.time() * math.random());

			local j = math.random(width);
			local k = math.random(length);

			local random2 = math.random(5);

			if (i + random2) == 0 and (j == math.ceil(width / 2) and k == math.ceil(length / 2)) then
				-- Spawnpoint here
				goto shop_continue;
			elseif (i + random2) <= floors and dungeon[i + random2][j][k].type == w.room.standard then
				dungeon[i + random2][j][k].type = w.room.shop;
				w.pathfinder.createEndpoint(i + random2, j, k);
				break;
			end

			::shop_continue::;
		end
	end ]]

	--[[ if not suppressMessages then print("Generating loot chests...") end

	math.randomseed(os.time() * math.random());

	for i = 1, floors, math.random(9) do
		if i > floors then break end

		while true do
			local j = math.random(width);
			local k = math.random(length);

			if i == 1 and (j == math.ceil(width / 2) and k == math.ceil(length / 2)) then
				-- Spawnpoint
				goto loot_continue;
			elseif dungeon[i][j][k].type == w.room.standard then
				dungeon[i][j][k].type = w.room.chest;
				w.pathfinder.createEndpoint(i, j, k);
				break;
			end

			::loot_continue::;
		end
	end ]]

	if not suppressMessages then print("Generating dungeon boss...") end

	while true do
		math.randomseed(os.time() * math.random());

		local j = math.random(width);
		local k = math.random(length);

		if dungeon[floors][j][k].type == w.room.standard then
			dungeon[floors][j][k].type = w.room.boss;
			w.pathfinder.createEndpoint(floors, j, k);
			break;
		end
	end

	if not suppressMessages then print("Generating walls...") end

	for i = 1, floors do
		for a = 1, math.floor((width * length) * 0.25) do
			while true do
				local j = math.random(width);
				local k = math.random(length);

				if i == 1 and (j == math.ceil(width / 2) and k == math.ceil(length / 2)) then
					-- Spawnpoint
					goto wall_continue;
				elseif dungeon[i][j][k].type ==
						w.room.standard then
					dungeon[i][j][k].type = w.room.wall;
					specials[i][j][k] = 0;

					if w.pathfinder.wallIsOk(dungeon, specials, i) then
						break;
					else
						dungeon[i][j][k].type =
							w.room.standard;
						specials[i][j][k] = 1;
					end
				end

				::wall_continue::;
			end
		end
	end

	if not suppressMessages then
		print("Complete! Took "..os.clock() - start_time.." seconds.\n");
	end

	return dungeon;
end

local floorSymbols = table.setReadOnly{
	[w.room.standard] = ".",
	[w.room.wall] = "@",
	[w.room.chest] = "C",
	[w.room.shop] = "$",
	[w.room.boss] = "B",
	[w.room.ladder] = "#",
};

function w.displayFloorMap(d, f, p, showAll)
	for j = 1, #d[f][1] do
		for i = 1, #d[f] do
			if f == p.z and (i == p.x and j == p.y) then
				io.write("X");
			elseif showAll or d[f][i][j].explored then
				io.write(floorSymbols[d[f][i][j].type]);
			else
				io.write("?");
			end
		end
		
		io.write("\n");
	end
end

local typeText = table.setReadOnly{
	[w.room.standard] = "standard",
	[w.room.wall] = "wall",
	[w.room.chest] = "chest",
	[w.room.shop] = "shop",
	[w.room.boss] = "boss",
	[w.room.ladder] = "ladder",
};

function w.getTileType(dungeon, x, y, z)
	if dungeon[z][x] then
		if dungeon[z][x][y] then
			return typeText[dungeon[z][x][y].type];
		end
	end

	return "wall";
end

local typeTextPrint = table.setReadOnly{
	[w.room.standard] = "empty room",
	[w.room.wall] = "wall",
	[w.room.chest] = "chest room",
	[w.room.shop] = "shop",
	[w.room.boss] = "boss room",
	[w.room.ladder] = "ladder room",
};

function w.getTileTypePrint(dungeon, x, y, z)
	if dungeon[z][x] then
		if dungeon[z][x][y] then
			if dungeon[z][x][y].explored then
				return typeTextPrint[dungeon[z][x][y].type];
			end

			return "unknown room";
		end
	end
	
	return "wall";
end

return w;
