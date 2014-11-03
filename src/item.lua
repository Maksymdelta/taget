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

local i = {};

i.type = table.setReadOnly{
	none = true,
	weapon = true,
	helmet = true,
	chestplate = true,
	leggings = true,
	boots = true,
	equipment = true,
	food = true,
	misc = true,
};

i.list = {};

local function checkItemValidity(k)
	if tonumber(k) then
		io.write("Warning : using a numerical item id "..k..
			", this may cause problems later!\n");
	end

	local entry = i.list[k];

	if not entry.name then
		io.write("Warning : item id \""..k.."\" does not have a "..
			"valid name entry!\n");
	end

	if not i.type[entry.type] then
		io.write("Warning : item id \""..k.."\" does not have a "..
			"valid type entry!\n");
	end

	if not entry.description then
		io.write("Warning : item id \""..k.."\" does not have a "..
			"valid description entry!\n");
	end

	if k ~= "none" and type(entry.onAttack) ~= "function" and
			type(entry.onHit) ~= "function" and
			type(entry.onTurn) ~= "function" and
			type(entry.onUse) ~= "function" then
		io.write("Warning : item id \""..k.."\" does not have any "..
			"valid event hooks!\n");
	end
end

function i.initialize()
	i.list = dofile("data/items.lua");

	for k in pairs(i.list) do
		checkItemValidity(k);
	end
end

function i.getItem(id)
	return i.list[id];
end

function i.listInv(input)
	local inv = taget.player.inventory;

	print("Weapon : "..i.getItem(inv.weapon).name);

	print("\nCurrently wearing : ");
	print("Helmet - "..i.getItem(inv.helmet).name);
	print("Chestplate - "..i.getItem(inv.chestplate).name);
	print("Leggings - "..i.getItem(inv.leggings).name);
	print("Boots - "..i.getItem(inv.boots).name);

	print("\nEquipment : ");

	for id = 1, inv.equipment.limit do
		print(i.getItem(inv.equipment[id]).name);
	end

	print("\nStored : ");

	for id = 1, #inv do
		print(i.getItem(inv[id]).name);
	end

	print();
end

--[[local nameToSlot = table.setReadOnly{
	weapon = taget.player.inventory.weapon;
	w = taget.player.inventory.weapon;
	helmet = taget.player.inventory.helmet;
	h = taget.player.inventory.helmet;
	chestplate = taget.player.inventory.chestplate;
	c = taget.player.inventory.chestplate;
	leggings = taget.player.inventory.leggings;
	l = taget.player.inventory.leggings;
	boots = taget.player.inventory.boots;
	b = taget.player.inventory.boots;
};]]

function i.getItemId(itemType, itemSlot)
	if nameToSlot[itemType] then
		return nameToSlot[itemType];
	elseif itemType == "equipment" or itemType == "e" then
		return taget.player.inventory.equipment[itemSlot];
	elseif itemType == "inventory" or itemType == "i" then
		return taget.player.inventory[itemSlot];
	end
end

function i.getInvItem(storageType, slot)
	local id;

	if tonumber(storageType) then
		id = i.getItemId("inventory", tonumber(storageType));
	else
		id = i.getItemId(storageType, tonumber(slot));
	end

	return i.getItem(tonumber(id));
end

function i.displayInfo(invId)
	local item = i.getInvItem(invId[2], invId[3]);

	if not item then
		print("Item not found!\n");
		return;
	end

	print("Item name - "..item.name);
	print("\nItem type - "..item.type);
	print("\nItem description - ");
	io.write(item.description);
	print("\nThis item has properties - ");

	if item.onHit then print("* On hit") end
	if item.onAttack then print("* On attack") end
	if item.onUse then print("* On use") end
	if item.onTurn then print("* On turn") end

	io.write("\n");
end

function i.deleteItem(itemType, itemSlot)
	itemSlot = tonumber(itemSlot);

	if itemType == "weapon" or itemType == "w" then
		taget.player.inventory.weapon = 0;
	elseif itemType == "helmet" or itemType == "h" then
		taget.player.inventory.helmet = 0;
	elseif itemType == "chestplate" or itemType == "c" then
		taget.player.inventory.chestplate = 0;
	elseif itemType == "leggings" or itemType == "l"  then
		taget.player.inventory.leggings = 0;
	elseif itemType == "boots" or itemType == "b" then
		taget.player.inventory.boots = 0;
	elseif itemType == "equipment" or itemType == "e" then
		taget.player.inventory.equipment[itemSlot] = 0;
	elseif itemType == "inventory" or itemType == "i" then
		table.remove(taget.player.inventory, itemSlot);
	elseif tonumber(itemType) then
		table.remove(taget.player.inventory, tonumber(itemType));
	end
end

function i.useItem(id)
	local item = i.getInvItem(id[2], id[3]);

	if not item then
		print("Item not found!\n");
		return;
	end

	if item.onUse then
		item.onUse();

		if item.type == "food" then
			i.deleteItem(id[2], id[3]);
		end
	else
		print("You can't use this item!\n");
	end
end

-- Does not handle equipping equipment... TODO - handle it

function i.equipItem(id)
	local item = i.getInvItem("inventory", tonumber(id[2]));

	if not item then
		print("Item not found!\n");
		return;
	end

	if (id[3] == "weapon" or id[3] == "w") and
			taget.player.inventory.weapon ~= 0 then
		print("You already have a weapon equipped!\n");
		return;
	elseif (id[3] == "helmet" or id[3] == "h") and
			taget.player.inventory.helmet ~= 0 then
		print("You already have a helmet equipped!\n");
		return;
	elseif (id[3] == "chestplate" or id[3] == "c") and
			taget.player.inventory.chestplate ~= 0 then
		print("You already have a chestplate equipped!\n");
		return;
	elseif (id[3] == "leggings" or id[3] == "l") and
			taget.player.inventory.leggings ~= 0 then
		print("You already have leggings equipped!\n");
		return;
	elseif (id[3] == "boots" or id[3] == "b") and
			taget.player.inventory.boots ~= 0 then
		print("You already have boots equipped!\n");
		return;
	end

	if id[3] == "weapon" or id[3] == "w" then
		taget.player.inventory.weapon = tonumber(id[2]);
	elseif id[3] == "helmet" or id[3] == "h" then
		taget.player.inventory.helmet = tonumber(id[2]);
	elseif id[3] == "chestplate" or id[3] == "c" then
		taget.player.inventory.chestplate = tonumber(id[2]);
	elseif id[3] == "leggings" or id[3] == "l" then
		taget.player.inventory.leggings = tonumber(id[2]);
	elseif id[3] == "boots" or id[3] == "b" then
		taget.player.inventory.boots = tonumber(id[2]);
	end

	i.deleteItem("inventory", tonumber(id[2]));
end

return i;
