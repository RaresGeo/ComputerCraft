os.loadAPI("inventory")

local x = 0
local y = 0
local depth = 0

local NORTH = 0
local EAST = 1
local SOUTH = 2
local WEST = 3

local orientation = NORTH

local returning = false
local switch = 0

local tArgs = {...}
squareSize = math.floor(tArgs[1]) -- For whatever reason, this won't work unless I floor.

function refuel()
	turtle.select(1)
	local itemSlot = 1
	while turtle.refuel() == false do
		itemSlot = itemSlot + 1
		if itemSlot > 16 then
			print "No fuel left"
			return false
		end
		turtle.select(itemSlot)
		print "Looking for fuel..."
	end
	
	print "Found fuel."
	print "Adding fuel..."
	
	return true
end

function position()
	if orientation == NORTH then
		x = x + 1
	elseif orientation == EAST then
		y = y + 1
	elseif orientation == SOUTH then
		x = x - 1
	elseif orientation == WEST then
		y = y - 1
	end
	s = "[" .. x .. ", " .. y .. ", " .. depth .. "]" -- Prints out coordinates relative to starting position. 0, 0, 0 being bottom left corner, highest altitude/depth 0
	print(s)
end

function fixOrientation(value)
	tempOrientation =  value
	
	if tempOrientation > 3 then
		tempOrientation = tempOrientation - 4
	end
		
	if tempOrientation < 0 then
		tempOrientation = tempOrientation + 4
	end
	
	return tempOrientation -- Limits orientation to the 4 cardinal directions
end

function setOrientation(value)

	wOri = fixOrientation(value) -- Wanted orientation
	tOri = orientation -- Temporary and imaginary orientation
	
	lTurns = 0 -- Number of left turns required to get to wanted orientation
	
	while tOri ~= wOri do
		lTurns = lTurns + 1
		tOri = fixOrientation(tOri - 1)
	end
	
	tOri = orientation
	rTurns = 0 -- Number of right turns required to get to wanted orientation
	
	while tOri ~= wOri do
		rTurns = rTurns + 1
		tOri = fixOrientation(tOri + 1)
	end
	
	if lTurns <= rTurns then -- Rotating whichever way is fastest (requires the least amount of turns)
		for i=1,lTurns do
			turtle.turnLeft()
		end
	else
		for i=1,rTurns do
			turtle.turnRight()
		end
	end
	
	orientation = wOri -- Set orientation to new current orientation
end

function manageFuel()
	if returning == false then
		if turtle.getFuelLevel() <= fuelToGoToPoint(0, 0, 0) or turtle.getFuelLevel() == 0 then
			local s1 = fuelToGoToPoint(0, 0, 0) .. " required to go back"
			print(s1)
			s2 = "Curent amount of fuel " .. turtle.getFuelLevel()
			print(s2)
			if refuel() == false then
				print "Not enough fuel to continue, returning"
				returning = true
				goToPoint(0, 0, 0)
				emptyInventoryIntoChest()				
				setOrientation(NORTH)
				print(s1)
				print(s2)
				return false
			end
		end
	end
	return true
end

function forward()
	if manageFuel() == false then
		return false
	else
		while turtle.forward() == false do -- Tries to move forward, if not successful do the following
			turtle.attack() -- Attack enemy blocking the way 
			turtle.dig() -- Dig block obstructing the way
		end
		position()
	end
	return true
end
	
function down()
	if manageFuel() == false then
		return false
	else
		local success, data = turtle.inspectDown() -- Check block below
		if data.name ~= "minecraft:bedrock" then -- If it's not bedrock, try to dig down
			while turtle.down() == false do
				turtle.attackDown()
				turtle.digDown()
			end
			depth = depth + 1
		end
	end
	return true
end
	
function up()
	if manageFuel() == false then
		return false
	else
		while turtle.up() == false do
			turtle.attackUp()
			turtle.digUp()
		end
		depth = depth - 1
	end
	return true
end

function invManagement()
	if inventory.isFull() then
		inventory.fixItemScatter()
		if inventory.isFull() then
			returnToStart()
		end
	end
end

function dig() -- Fuel is only used when moving, dig blocks in above and below for efficiency
	invManagement()
	turtle.digUp()
	invManagement()
	turtle.digDown()
	invManagement()
end

function turnAround()
	setOrientation(fixOrientation(orientation + 2))
end


function emptyInventoryIntoChest()
	setOrientation(WEST)
	for i=1,4 do
		local success, data = turtle.inspect()
		if success then
			if data.name:find("Chest") or data.name:find("chest") then
				setOrientation(orientation + 1)
				inventory.fixItemScatter()
				setOrientation(orientation - 1)
				for i=1, 16 do
					local data = turtle.getItemDetail(i)
					if data.count > 0 and data.name ~= "minecraft:coal"then
						turtle.select(i)
						turtle.drop()
					end
				end
				setOrientation(NORTH)
				return true
			end
		end
		setOrientation(orientation + 1)
	end
	setOrientation(NORTH)
	return false
end


function goToPoint(_x, _y, _depth)
	if turtle.getFuelLevel() >= fuelToGoToPoint(_x, _y, _depth) then
		if x ~= _x then
			if x <= _x then
				setOrientation(NORTH)
			else
				setOrientation(SOUTH)
			end
				
			while x ~= _x do
				forward()
			end
		end
		
		if y ~= _y then
			if y <= _y then
				setOrientation(EAST)
			else
				setOrientation(WEST)
			end
				
			while y ~= _y do
				forward()
			end
		end
		
		while depth > _depth do
			up()
		end
		
		while depth < _depth do
			down()
		end
		
		setOrientation(NORTH)
		return true
	else
		local s = fuelToGoToPoint(_x, _y, _depth) .. " required to go back"
		print(s)
		s = "Curent amount of fuel " .. turtle.getFuelLevel()
		print(s)
		s = "Current depth is " .. depth
		print(s)
		return false
	end
end

function returnToStart()
	local _x = x
	local _y = y
	local _depth = depth
	local _orientation = orientation
	
	
	if goToPoint(0, 0, 0) then
		if emptyInventoryIntoChest() then
			if goToPoint(_x, _y, _depth) then
				setOrientation(_orientation)
				return true
			else
				setOrientation(NORTH)
				return false
			end
		else
			setOrientation(NORTH)
			return false
		end
	else
		return false
	end
end

function fuelToGoToPoint(_x, _y, _depth)
	xDistance = x - _x
	yDistance = y - _y
	zDistance = depth - _depth
	
	xDistance = math.sqrt(xDistance * xDistance)
	yDistance = math.sqrt(yDistance * yDistance)
	zDistance = math.sqrt(zDistance * zDistance)
	
	return xDistance + yDistance + zDistance
end
	
	
function digArea(s) -- parameter because we need to turn in different manners depending on whether the size of the quarry is an even or an odd number
	switch = s -- Need to switch between rotating left and rotating right
	for i=1, 2 do
		if down() == false then
			return false
		end
	end
	dig()
	for i=1, squareSize do
		for j=1, (squareSize - 1) do
			if forward() == false then
				return false
			end
			dig()
		end
		if i ~= squareSize then -- Only need to turn around on last iteration
			if switch == 0 then
				setOrientation(orientation + 1) -- Rotate right
				if forward() == false then
					return false
				end
				dig()
				setOrientation(orientation + 1)
				switch = 1
			else
				setOrientation(orientation - 1) -- Rotate left
				if forward() == false then
					return false
				end
				dig()
				setOrientation(orientation - 1)
				switch = 0
			end
		else
			turnAround()
			invManagement()
		end
			
	end
	if down() == false then
		return false
	end
	
	local success, data = turtle.inspectDown()
	if data.name ~= "minecraft:bedrock" then
		if squareSize - math.floor(squareSize/2)*2 == 0 then -- That's basically a modulo operator, lua doesn't have one though so gotta implement your own, couldn't be bothered making a function for it
			return digArea(switch) -- Maintain pattern if even number
		else
			return digArea(0) -- Different pattern if odd
		end
	else
		print "Hit bedrock, returning"
		goToPoint(0, 0, 0)
		emptyInventoryIntoChest()
		return true
	end
end

if turtle.getFuelLevel() == 0 then
	if refuel() == false then
		print "No fuel."
	else
		if #tArgs == 2 then
			goToPoint(0, 0, tArgs[2])
		end
		if digArea(0) then
			print "Finished."
		else
			print "Something went wrong."
		end
	end
else
	if #tArgs == 2 then
		goToPoint(0, 0, math.floor(tArgs[2]))
	end
	if digArea(0) then
		print "Finished."
	else
		print "Something went wrong."
	end
end




