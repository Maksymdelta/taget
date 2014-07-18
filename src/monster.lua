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

local m = {};

taget.encounter = nil;

function m.initialize()
	m.list = dofile("data/monsters.txt");
end

local function createEncounter()
	math.randomseed(os.time());
	local encounterChance = math.random(1, 100);
	local monsterNum = math.random(1, #m.list);

	if m.list[monsterNum].startFloor <= taget.player.z
			and encounterChance <= m.list[monsterNum].rarity then
		local e = table.copy(m.list[monsterNum]);

		e.baseHealth = (taget.player.z == 1) and e.baseHealth or
			math.floor(e.baseHealth * ((taget.player.z + 1) / 2));
		e.baseAttack = (taget.player.z == 1) and e.baseAttack or
			math.floor(e.baseAttack * ((taget.player.z + 1) / 2));
		e.baseDefense = (taget.player.z == 1) and e.baseDefense or
			math.floor(e.baseDefense * ((taget.player.z + 1) / 2));
		e.baseExp = (taget.player.z == 1) and e.baseExp
			or math.floor(e.baseExp * ((taget.player.z + 1) / 2));

		e.x = taget.player.x;
		e.y = taget.player.y;
		e.z = taget.player.z;

		taget.encounter = e;
	
		print("A random "..taget.encounter.name.." has appeared!\n");
	end
end

function m.processEncounter()
	local t = taget;

	if not taget.encounter then
		if t.world.getTileType(t.dungeon, t.player.x, t.player.y,
				t.player.z) == "boss" then
			t.encounter = table.copy(m.list.boss);

			t.encounter.x = taget.player.x;
			t.encounter.y = taget.player.y;
			t.encounter.z = taget.player.z;

			print("The dungeon boss "..
				t.encounter.name.." has appeared!\n");
		else
			createEncounter();
		end
	else
		if t.encounter.x ~= t.player.x or
				t.encounter.y ~= t.player.y or
				t.encounter.z ~= t.player.z then
			t.encounter = nil;
			return;
		end

		if t.encounter.baseHealth <= 0 then
			print("Defeated the "..t.encounter.name.."!");
			
			if t.encounter.name == m.list.boss.name then
				print("You win!");
				os.exit();
			end

			t.player.experience =
				t.player.experience + t.encounter.baseExp;
			print("Got "..
				t.encounter.baseExp.." experience points!\n");

			t.encounter = nil;

			if t.player.experience >= t.player.nextLevel then
				t.player.level = t.player.level + 1;
				print("Got to level "..t.player.level.."!");
				t.player.nextLevel =
					t.player.nextLevel +
					(25 * t.player.level);
				t.input.chooseLevelUp();
			end

			print("Next level : "
				..(t.player.nextLevel - t.player.experience)..
				" more experience points\n");
			return;
		end

		local strength = math.random(t.encounter.baseAttack);
		local defense = math.random(t.player.defense);

		if strength - defense > -1 then
			t.player.health =
				t.player.health - (strength - defense);
		else
			-- Set them to dummy values that come out to 0
			strength = 1; defense = 1;
		end

		print("The "..t.encounter.name.." hit you for "
			..(strength - defense).." damage!");
		print("You have "..t.player.health.." hit points left!\n");

		if t.player.health <= 0 then
			print("Game over! You died!");
			os.exit();
		end
	end
end

return m;
