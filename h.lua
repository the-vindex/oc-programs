--detect whether we are in MC
local res, robot = pcall(function() return require("robot") end)
if type(robot) == 'table' then
	ingame = true
else
	ingame = false
end

if ingame then
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
local ShapeInfo = require("ShapeInfo")
local RobotDriver = require("RobotDriver")
local CoordTracker = require("CoordTracker")
local AutoLogger = require("AutoLogger")

local function nav()
	return component.navigation
end

local function loadField()
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
	--printObject(startCoord)
	--printObject(endCoord)

	return FieldInfo:newFromParams(startCoord, endCoord)
end

local function tripleToVector(triple)
	return vec.new(triple[1], triple[2], triple[3])
end

local function findWaypointByName(t, name)
	return VLibs.filterTable_first(t, function(i) return i['label'] == name end)
end

--- automatic self-test
function t()
	v = function(x,y,z)
		return vec.new(x,y,z)
	end
  
  -- empty right now

end

--size
local fieldInfo = loadField()
local startCoord = fieldInfo.startCoord
local endCoord = fieldInfo.endCoord

local request = ShapeInfo:new()
request:putV(startCoord, "P")
request:putV(endCoord, "P")

local minV, maxV = request:getBorderCubeCoords()
request:fillYLayer(minV.x, maxV.x, minV.z, maxV.z, minV.y, "P")
request:printShape()

local driver = RobotDriver:new()

local myX, myY, myZ = nav().getPosition()
local facing = nav().getFacing()
local currentCoord = CoordTracker:new(myX, myY, myZ, CoordTracker.getDirFromSideApi(facing))

print(tostring(currentCoord.coords))
print(tostring(startCoord), tostring(endCoord))

local filelogger = require("log")
filelogger.outfile = "log.txt"

--local log = AutoLogger:new()
--driver = log:wrapObject(driver)

driver:autoHarvest(request, currentCoord)
