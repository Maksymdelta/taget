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

local p = {};

local endpoints = {};

function p.createEndpoint(floor, x, y)
	if type(floor) ~= "number" then
		error("floor - expected number, got "..type(x), 2);
	end

	if type(x) ~= "number" then
		error("x - expected number, got "..type(x), 2);
	end

	if type(y) ~= "number" then
		error("y - expected number, got "..type(y), 2);
	end

	if type(endpoints[floor]) ~= "table" then
		endpoints[floor] = {};
	end
	
	endpoints[floor][#endpoints[floor] + 1] = { x = x, y = y, };
end

--[[local function displaySpecialMap(floor)
	for j = 1, #floor[1] do
		for i = 1, #floor do
			io.write(floor[i][j]);
		end
		
		io.write("\n");
	end
end]]

local function addPathNode(path, directionWent)
	if type(path) ~= "table" then
		error("path - expected table, got "..type(path), 2);
	end
	
	if type(directionWent) ~= "number" then
		error("directionWent - expected number, got "..type(path), 2);
	end

	path[#path].hasGone[directionWent] = true;

	local x, y = path[#path].x, path[#path].y;

	if directionWent == taget.world.direction.north then
		y = y - 1;
	elseif directionWent == taget.world.direction.east then
		x = x + 1;
	elseif directionWent == taget.world.direction.south then
		y = y + 1;
	elseif directionWent == taget.world.direction.west then
		x = x - 1;
	end
	
	path[#path + 1] = {
		x = x,
		y = y,
		hasGone = {
			[taget.world.direction.north] = false,
			[taget.world.direction.east] = false,
			[taget.world.direction.south] = false,
			[taget.world.direction.west] = false,
		},
	};
end

local function findStartPoint(d, f)
	if f == 1 then
		return math.ceil(#d[1] / 2), math.ceil(#d[1][1] / 2);
	end

	for a = 1, #d[1] do
		for b = 1, #d[1][1] do
			if d[f][a][b].type == "ladder" and
					d[f - 1][a][b].type == "ladder" then
				return a, b;
			end
		end
	end

	return -1, -1;
end

function p.wallIsOk(dungeon, specials, f)
	local startX, startY = findStartPoint(dungeon, f);

	if startX == -1 or startY == -1 then
		error("Did not find starting locations for floor "..f.."!", 2);
	end

	-- Loop through all of the endpoints
	
	local didPass = true;

	local dir = taget.world.direction;
	
	for _, endpoint in pairs(endpoints[f]) do
		--[[
			Set up our path. Fill in the first step by hand so
			that the direction checking logic doesn't choke on
			values that don't exist
		]]
		
		local path = {
			[1] = {
				x = startX,
				y = startY,
				hasGone = {
					[dir.north] = false,
					[dir.east] = false,
					[dir.south] = false,
					[dir.west] = false,
				},
			}
		};

		local costF = {};

		local times = 0;

		while true do
			if path[#path].x == 1 then
				path[#path].hasGone[dir.west] = true;
			end

			if path[#path].y == 1 then
				path[#path].hasGone[dir.north] = true;
			end

			if path[#path].x == #specials[1] then
				path[#path].hasGone[dir.east] = true;
			end

			if path[#path].y == #specials[1][1] then
				path[#path].hasGone[dir.south] = true;
			end

			local lowestCost = math.huge;
			local lowestDirection = -1;

			if not path[#path].hasGone[dir.north] and (path[#path].y > 1 and specials[f][path[#path].x][path[#path].y - 1] ~= 0) then
				costF[dir.north] = #path + math.abs(path[#path].x - endpoint.x) + math.abs((path[#path].y - 1) - endpoint.y);
			else
				costF[dir.north] = math.huge;
			end

			if not path[#path].hasGone[dir.east] and (path[#path].x < #specials[1][1] and specials[f][path[#path].x + 1][path[#path].y] ~= 0) then
				costF[dir.east] = #path + math.abs((path[#path].x + 1) - endpoint.x) + math.abs(path[#path].y - endpoint.y);
			else
				costF[dir.east] = math.huge;
			end

			if not path[#path].hasGone[dir.south] and (path[#path].y < #specials[1] and specials[f][path[#path].x][path[#path].y + 1] ~= 0) then
				costF[dir.south] = #path + math.abs(path[#path].x - endpoint.x) + math.abs((path[#path].y + 1) - endpoint.y);
			else
				costF[dir.south] = math.huge;
			end

			if not path[#path].hasGone[dir.west] and (path[#path].x > 1 and specials[f][path[#path].x - 1][path[#path].y] ~= 0) then
				costF[dir.west] = #path + math.abs((path[#path].x - 1) - endpoint.x) + math.abs(path[#path].y - endpoint.y);
			else
				costF[dir.west] = math.huge;
			end
			
			for a = 1, 4 do
				for b = 1, 4 do
					if costF[a] < costF[b] then
						if costF[a] < lowestCost then
							lowestCost = costF[a];
							lowestDirection = a;
						end
					end
				end
			end
			
			if not path[#path].hasGone[lowestDirection] then
				addPathNode(path, lowestDirection);
			else
				path[#path] = nil;
			end
			
			if path[#path].x == endpoint.x and path[#path].y == endpoint.y then
				goto for_continue;
			end
			
			if times > (#dungeon[1] * #dungeon[1][1]) * 2 then
				didPass = false;
				goto for_break;
			end
			
			times = times + 1;
		end
		::for_continue::;
	end
	
	::for_break::;
	return didPass;
end

return p;
