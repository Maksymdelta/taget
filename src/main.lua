#!/usr/bin/env lua

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

print("Welcome to TAGET 0.7.1, the Text Adventure Game Engine Thingy");
print("Copyright (c) 2013-2014 Robert Cochran and Niko Geil");
print("TAGET comes with ABSOLUTELY NO WARRANTY!");
print("This is free software, and you are welcome");
print("to redistribute and modify it under certain conditions.");
print("(See the LICENSE file for details)");

print("\nStarting up...");

-- Put the src/ directory into the package path,
-- so that require() will find them properly.
package.path = "./src/?.lua;" .. package.path;

require("extensions");

taget = {};

taget.world = require("world");
taget.monster = require("monster");
taget.item = require("item");
taget.input = require("input");

print("Loading monster data...");
taget.monster.initialize();

print("Loading item data...");
taget.item.initialize();

print("\nDungeon options (Leave blank to use default values) :");
io.write("How many floors? [15] ");
local input = tonumber(io.read());
local floors = (type(input) ~= "nil" and math.abs(input) > 0)
	and math.abs(input) or 15;

io.write("How many columns? [5] ");
input = tonumber(io.read());
local cols = (type(input) ~= "nil" and math.abs(input) > 0)
	and math.abs(input) or 5;

io.write("How many rows? [5] ");
input = tonumber(io.read());
local rows = (type(input) ~= "nil" and math.abs(input) > 0)
	and math.abs(input) or 5;

taget.player = {
	x = math.ceil(cols / 2),
	y = math.ceil(rows / 2),
	z = 1,
	maxHealth = 10,
	health = 5,
	attack = 5,
	defense = 5,
	level = 1,
	experience = 0,
	nextLevel = 25,
	inventory = {
		helmet = "worn_helmet",
		chestplate = "worn_chestplate",
		leggings = "worn_leggings",
		boots = "worn_boots",
		weapon = "soulthief",
		equipment = {
			limit = 3,
			"useless_ring", "none", "none",
		},
		"bread",
	},
};

--[[local pointsLeft = 10;

print("\nCharacter options : ");

io.write("Boost health [10] ("..pointsLeft.." points left) : ");
input = tonumber(io.read());
if input and (1 <= input and input <= pointsLeft) then
	taget.player.maxHealth = taget.player.maxHealth + input;
	taget.player.health = taget.player.maxHealth;
	pointsLeft = pointsLeft - input;
end

io.write("Boost attack [3] ("..pointsLeft.." points left) : ");
input = tonumber(io.read());
if input and (1 <= input and input <= pointsLeft) then
	taget.player.attack = taget.player.attack + input;
	pointsLeft = pointsLeft - input;
end

io.write("Boost defense [3] ("..pointsLeft.." points left) : ");
input = tonumber(io.read());
if input and (1 <= input and input <= pointsLeft) then
	taget.player.defense = taget.player.defense + input;
	-- Don't bother with the pointsLeft; we're done with it here
end]]

local turnsUntilHealth = -1;

print("\nStarting dungeon generation...");
taget.dungeon = taget.world.generateDungeon(floors, cols, rows);

print("Type 'help' for a list of verbs\n");

while true do
	io.write("> ");

	taget.input.processInput();
	taget.monster.processEncounter();

	local p = taget.player;

--[[	for k, id in pairs(p.inventory) do
		-- Objects whose key is a number are in the 'hold'
		-- area, not equipped, so don't count those.
		-- Having a value type of table means that it is
		-- the current equipment data, which does not point
		-- to a valid item id in and of itself.
		if type(k) == "number" or type(id) == "table" then
			goto turn_continue;
		end

		local item = taget.item.getItem(id);

		if item.onTurn then item.onTurn() end

		::turn_continue::;
	end

	for slot = 1, #p.inventory.equipment do
		local item = taget.item.getInvItem("equipment", slot);

		if item.onTurn then item.onTurn() end
	end
]]
	if turnsUntilHealth == 0 then
		if p.health < p.maxHealth then
			p.health = p.health + 1;
		end

		turnsUntilHealth = 5;
	else
		turnsUntilHealth = turnsUntilHealth - 1;
	end
end

return 0;
