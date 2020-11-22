os.loadAPI("inventory")

local dugSoFar = depth
local hitBedrock = false
local x = 0
local y = 0
local depth = 0

local NORTH = 0
local EAST = 1
local SOUTH = 2
local WEST = 3

local orientation = NORTH

local switch = 0

local tArgs = {...}
squareSize = math.floor(tArgs[1]) -- For whatever reason, this won't work unless I floor.

if #tArgs == 3 then
	goX = math.floor(tArgs[1])
	goY = math.floor(tArgs[2])
	goDepth = math.floor(tArgs[3])
end

function refuel()
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
	turtle.refuel()
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

function forward()
	while turtle.forward() == false do -- Tries to move forward, if not successful do the following
		turtle.attack() -- Attack enemy blocking the way 
		turtle.dig() -- Dig block obstructing the way
	end
	position()
end
	
function down()
	local success, data = turtle.inspectDown() -- Check block below
	if data.name ~= "minecraft:bedrock" then -- If it's not bedrock, try to dig down
		while turtle.down() == false do
			turtle.attackDown()
			turtle.digDown()
		end
		dugSoFar = depth
		depth = depth + 1
	end
end
	
function up()
	while turtle.up() == false do
		turtle.attackUp()
		turtle.digUp()
	end
	depth = depth - 1
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
				for i=1, 16 do
					if turtle.getItemCount(i) > 0 then
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
	if x <= _x then
		setOrientation(NORTH)
	else
		setOrientation(SOUTH)
	end
		
	while x ~= _x do
		forward(1)
	end
	
	if y <= _y then
		setOrientation(EAST)
	else
		setOrientation(WEST)
	end
		
	while y ~= _y do
		forward(0)
	end
	
	while depth > _depth do
		up()
	end
	
	while depth < _depth do
		down()
	end
	
	setOrientation(NORTH)
end

function returnToStart()
	local _x = x
	local _y = y
	local _depth = depth
	local _orientation = orientation
	
	
	goToPoint(0, 0, 0)
	if emptyInventoryIntoChest() then
		goToPoint(_x, _y, _depth)
		setOrientation(_orientation)
		return true
	else
		setOrientation(NORTH)
		return false
	end
end
	
	
function digArea(s) -- parameter because we need to turn in different manners depending on whether the size of the quarry is an even or an odd number
switch = s -- Need to switch between rotating left and rotating right
down()
down()
dig()
position()
	for i=1, squareSize do
		for j=1, (squareSize - 1) do
			if turtle.getFuelLevel() < 200 then
				refuel()
			end
			forward(1)
			dig()
		end
		if i ~= squareSize then -- Only need to turn around on last iteration
			if switch == 0 then
				setOrientation(orientation + 1) -- Rotate right
				forward(0)
				dig()
				setOrientation(orientation + 1)
				switch = 1
			else
				setOrientation(orientation - 1) -- Rotate left
				forward(0)
				dig()
				setOrientation(orientation - 1)
				switch = 0
			end
		else
			turnAround()
			inventory.cleanInventory()
		end
			
	end
	down()
	
	local success, data = turtle.inspectDown()
	if data.name ~= "minecraft:bedrock" then
		if squareSize - math.floor(squareSize/2)*2 == 0 then -- That's basically a modulo operator, lua doesn't have one though so gotta implement your own, couldn't be bothered making a function for it
			digArea(switch) -- Maintain pattern if even number
		else
			digArea(0) -- Different pattern if odd
		end
	else
		print "Hit bedrock, returning"
		hitBedrock = true
		goToPoint(0, 0, 0)
		emptyInventoryIntoChest()
	end
end

if #tArgs == 4 then
	goToPoint(goX, goY, goDepth)
end

digArea(0) -- If this was called with 1 instead of 0 as the parameter, and the one on line 231 changed, it would simply go left instead of right
-- And therefore start in the bottom right corner.
-- But then the returnToStart() function wouldn't work correctly anymore. I see no point in fixing that, to be honest.
