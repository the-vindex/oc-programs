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
local VLibs = require("VLibs")
local axis = enums.axis


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

local function tripleToVector(triple)
	return vec.new(triple[1], triple[2], triple[3])
end

local function findWaypointByName(t, name)
	return filterTable_first(t, function(i) return i['label'] == name end)
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
	

--	local ShapeInfo = require ("ShapeInfo")
--	ShapeInfo.unitTest()
	
--	local CoordTracker = require("CoordTracker")
--	CoordTracker.unitTest()
	
--	local Pathfinder = require("Pathfinder")
--	Pathfinder.unitTest()
	
--  local robot = require("robotEmu")
--	robot.unitTest()
  
--	local RobotDriver = require("RobotDriver")
--	RobotDriver.unitTest_automove()
--	RobotDriver.unitTest_autobuild()
	

end

--size
local fieldInfo = loadField()

local shapeInfo = ShapeInfo:new()

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


