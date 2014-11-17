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

print("Loading monster data...");
m.list = dofile("data/monsters.txt");

local function createEncounter()
	math.randomseed(os.time());
	local encounterChance = math.random(1, 100);
	local monsterNum = math.random(1, #m.list);

	if m.list[monsterNum].startFloor <= taget.player.z
	and encounterChance <= m.list[monsterNum].rarity then
		taget.encounter = table.copy(m.list[monsterNum]);

		taget.encounter.baseHealth = (taget.player.z == 1) and
			taget.encounter.baseHealth or
			math.floor(taget.encounter.baseHealth *
				((taget.player.z + 1) / 2));

		taget.encounter.baseAttack = (taget.player.z == 1) and
			taget.encounter.baseAttack or
			math.floor(taget.encounter.baseAttack *
				((taget.player.z + 1) / 2));

		taget.encounter.baseDefense = (taget.player.z == 1) and
			taget.encounter.baseDefense or
			math.floor(taget.encounter.baseDefense *
				((taget.player.z + 1) / 2));

		taget.encounter.baseExp = (taget.player.z == 1) and
			taget.encounter.baseExp or
			math.floor(taget.encounter.baseExp *
				((taget.player.z + 1) / 2));

		taget.encounter.x = taget.player.x;
		taget.encounter.y = taget.player.y;
		taget.encounter.z = taget.player.z;
	
		print("A random "..taget.encounter.name.." has appeared!\n");
	end
end

function m.processEncounter()
	local t = taget;
	local e = t.encounter;
	local p = t.player;

	if not e then
		if t.world.getTileType(t.dungeon, p.x, p.y, p.z) == "boss" then
			e = table.copy(m.list.boss);

			e.x = p.x;
			e.y = p.y;
			e.z = p.z;

			print("The dungeon boss "..e.name.." has appeared!\n");
		else
			createEncounter();
		end
	else
		if e.x ~= p.x or e.y ~= p.y or e.z ~= p.z then
			e = nil;
			return;
		end

		if e.baseHealth <= 0 then
			print("Defeated the "..e.name.."!");
			
			if e.name == m.list.boss.name then
				print("You win!");
				os.exit();
			end

			p.experience = p.experience + e.baseExp;
			print("Got "..e.baseExp.." experience points!\n");

			e = nil;

			if p.experience >= p.nextLevel then
				p.level = p.level + 1;
				print("Got to level "..p.level.."!");
				p.nextLevel = p.nextLevel + (25 * p.level);
				t.input.chooseLevelUp();
			end

			print("Next level : "..(p.nextLevel - p.experience)..
				" more experience points\n");
			return;
		end

		local strength = math.random(e.baseAttack);
		local defense = math.random(p.defense);

		if strength - defense > -1 then
			p.health = p.health - (strength - defense);
		else
			-- Set strength and defense to dummy values
			-- that come out to 0, to prevent the high
			-- defense value from /adding/ health
			strength = 1; defense = 1;
		end

		print("The "..e.name.." hit you for "..
			(strength - defense).." damage!");
		print("You have "..p.health.." hit points left!\n");

		if p.health <= 0 then
			print("Game over! You died!");
			os.exit();
		end
	end
end

return m;
