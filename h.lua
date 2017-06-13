--detect whether we are in MC
local res, robot = pcall(function() return require("robot") end)
if type(robot) == 'table' then
	ingame = true
else
	ingame = false
end

if ingame then
	os.execute("wget -f -q http://192.168.0.101:8000/oc2/libvec.lua")
	robot = require("robot")
	component = require("component")
	ser = require("serialization")
	counter = 100
else
	package.path="./?/init.lua;" .. package.path
	package.path="./testlibs/?.lua;" .. package.path
	ass = require("luassert")
end

local vec = require("libvec")
local FieldInfo = require("FieldInfo")
local enums = require("OcEnums")
local axis = enums.axis


function printTable(t)
	for k,v in pairs(t) do
		print(k)
	end
end

function printObject(object)
	print(ser.serialize(object,true))
end

local robotInfo = {
	x = 'unknown',
	y = 'unknown',
	z = 'unknown',
	facing = 'unknown'
}


function nav()
	return component.navigation
end

function loadField()
	local nav = nav()
	local waypoints = nav.findWaypoints(60)
--	printObject(waypoints)
	local fieldStart  = findWaypointByName(waypoints, "start")['position']
--	printObject(fieldStart)
	local fieldEnd  = findWaypointByName(waypoints, "end")['position']
--	printObject(fieldEnd)
	local myX, myY, myZ = nav.getPosition()
	-- error checking
	if (not(myX)) then
		print("Error, can't get my position")
		os.exit()
	end
	
	--normalize waypoints coordinates towards map
	local myCoord = vec.new(myX,myY,myZ)
	local startCoord = myCoord + tripleToVector(fieldStart)
	local endCoord = myCoord + tripleToVector(fieldEnd)
	printObject(startCoord)
	printObject(endCoord)

	return FieldInfo:newFromParams(startCoord, endCoord)
end

function tripleToVector(triple)
	--print(ser.serialize(triple))
	return vec.new(triple[1], triple[2], triple[3])
end

function findWaypointByName(t, name)
	return filterTable_first(t, function(i) return i['label'] == name end)
end

function filterTable_first(t,filter)
	for _, item in ipairs(t) do
		if filter(item) then
			return item
		end
	end
end

function planMoves(field)
	local primaryAxis = field.axisInfo.primaryAxis
	local secondaryAxis = field.axisInfo.secondaryAxis
	
	local coordinateDeltas = {}
	coordinateDeltas[1] = field.fieldMoveVector:mulVectors(primaryAxis.coordinateFilter)
	coordinateDeltas[2] = field.fieldMoveVector:mulVectors(secondaryAxis.coordinateFilter):normalize()
	coordinateDeltas[3] = coordinateDeltas[1]:mul(-1)
	coordinateDeltas[4] = coordinateDeltas[2]
	
	for i=#coordinateDeltas,1,-1 do
		if coordinateDeltas[i]:length() == 0 then
			table.remove(coordinateDeltas,i)
		end
	end
	
	local i = 1
	local limit = #coordinateDeltas
	local currentCoord = field.startCoord
	local finalCoord = field.endCoord
	local moves = {}
	local count = 0
	
	
	while count<100 and not(currentCoord:equals(finalCoord)) do
		local nextCoord = currentCoord:add(coordinateDeltas[i])
		
		table.insert(moves, {currentCoord, nextCoord})
		currentCoord = nextCoord
		
		i = i + 1
		if (i > limit) then
			i = 1
		end
		count = count + 1
	end
	
	return moves
end


--- automatic self-test
function t()
	v = function(x,y,z)
		return vec.new(x,y,z)
	end
	
	--FieldInfo tests"
		local s = v(0,0,0)
		local e = v(2,0,5)
		local f = FieldInfo:newFromParams(s, e)
		ass.message("start coord").same(v(0,0,0), f.startCoord)
		ass.message("start end").same(v(2,0,5), f.endCoord)
		ass.message("vector").same(e,f.fieldMoveVector)
		ass.message("axis primary").same(axis.zNorthSouth, f.axisInfo.primaryAxis)
		ass.message("axis secondary").same(axis.xEastWest, f.axisInfo.secondaryAxis)
		ass.message("shouldn't crash").Not.has.errors(function () tostring(f) end)
	
	-- test our additions to vectors
	ass.message("equals works").True(v(1,2,3):equals(v(1,2,3)))
	ass.message("not-equals works").False(v(1,2,3):equals(v(1,2,4)))
	
	local moves1 = planMoves(FieldInfo:newFromParams(v(0,0,0),v(5,0,0)))
	ass.message("moves by X axis only").same({v(0,0,0),v(5,0,0)}, moves1[1])
	
	local moves2 = planMoves(FieldInfo:newFromParams(v(0,0,0),v(5,0,2)))
	ass.message("moves by X and Z - length").same(5, #moves2)
	ass.message("moves by X and Z - 1").same({v(0,0,0),v(5,0,0)}, moves2[1])
	ass.message("moves by X and Z - 2").same({v(5,0,0),v(5,0,1)}, moves2[2])
	ass.message("moves by X and Z - 3").same({v(5,0,1),v(0,0,1)}, moves2[3])
	ass.message("moves by X and Z - 4").same({v(0,0,1),v(0,0,2)}, moves2[4])
	ass.message("moves by X and Z - 4").same({v(0,0,2),v(5,0,2)}, moves2[5])
	
--	local ShapeInfo = require ("ShapeInfo")
--	ShapeInfo.unitTest()
	
--	local CoordTracker = require("CoordTracker")
--	CoordTracker.unitTest()
	
--	local Pathfinder = require("Pathfinder")
--	Pathfinder.unitTests()
	
--  local robot = require("robotEmu")
--	robot.testAll()
  
	local RobotDriver = require("RobotDriver")
--	RobotDriver.unitTest_automove()
	RobotDriver.unitTest_autobuild()
	

end

--size
--local fieldInfo = loadField()
if not(ingame) then
	t()
	os.exit()
end

os.exit()
while counter>0 do
	counter = counter - 1
	robot.useDown()
	local isMoved,failReason = robot.forward()
	if(not(isMoved)) then
		print('fail')
		robot.swing()
	end
	os.sleep(5);
end


