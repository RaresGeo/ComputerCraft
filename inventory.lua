	local trash = {
		"minecraft:cobblestone",
		"minecraft:stone",
		"minecraft:gravel",
		"minecraft:dirt",
		"minecraft:red_flower",
		"minecraft:yellow_flower",
		"minecraft:apple",
		"chisel:andesite",
		"chisel:marble",
		"chisel:limestone",
		"chisel:diorite",
		"chisel:granite",
		"Thaumcraft:ItemResource",
		"Thaumcraft:blockCustomOre",
		"Thaumcraft:ItemShard",
		"BiomesOPlenty:flowers2",
		"Botania:mushroom"
		}

function isFull()
	for i=1, 16 do
		if turtle.getItemCount(i) == 0 then
			return false
		end
	end
	return true
end

function cleanInventory()
local isTrash = false -- For debugging purposes and expanding the trash list	
	for i=1, 16 do -- 16 inventory slots
		isTrash = false
		local data = turtle.getItemDetail(i)
		if data then
			for j= 1, #trash do -- loop through trash table
				if data.name == trash[j] then
					turtle.select(i) -- select item
					turtle.drop() -- drop it
					isTrash = true
				end
				
			end
			if isTrash == false then
				print(data.name) -- print out so I can add it to the trash list
			end
		end
	end
end

function fixItemScatter()
local isTrash
	for i=1,16 do
		isTrash = false
		local ii = turtle.getItemDetail(i)
		if ii ~= nil then
			for t= 1, #trash do
				if ii.name == trash[t] then
					turtle.select(i) -- select item
					turtle.drop() -- drop it
					isTrash = true
				end
			end
			if isTrash == false then
				for j=1, 16 do
					if i ~= j then
						local jj = turtle.getItemDetail(j)
						if jj then
							if ii.name == jj.name then
								turtle.select(j)
								turtle.transferTo(i)
							end
						end
					end
				end
			end
		end
	end
end
	
function selectItem(s, itemSlot)
	itemSlot = itemSlot or 1
	for i=itemSlot, 16 do
		local data  = turtle.getItemDetail(i)
		if data then
			if s == data.name then
				turtle.select(i)
				return true
			end
		end
	end
	return false
end
	
function getItemCount(s)
	local count = 0
	itemSlot = 1
	while selectItem(s, itemSlot) do
		itemSlot = turtle.getSelectedSlot() + 1
		local data  = turtle.getItemDetail()
		count = count + data.count
	end
	return count
end
	
