if pcall('require("robot")') then
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
	ass = require("luassert")
end

vec = require("libvec")

local robotInfo = {
	x = 'unknown',
	y = 'unknown',
	z = 'unknown',
	facing = 'unknown'
}

local axis = {
	zNorthSouth = "zNorthSouth",
	xEastWest = "xEastWest",
	yUpDown = "yUpDown"
}

-- class FieldInfo
FieldInfo = {}
function FieldInfo:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function FieldInfo:newFromParams(startCoord, endCoord)
	local fieldInfo = self:new()
	fieldInfo.startCoord = startCoord
	fieldInfo.endCoord = endCoord
	
	local fieldMoveVector = subtractVectors(fieldInfo.endCoord, fieldInfo.startCoord)
	
	fieldInfo.fieldMoveVector = fieldMoveVector

	local axisInfo = {}
	--select primary movement direction - in this direction we move forward, into other direction we just turn
	if (math.abs(fieldMoveVector.x)>=math.abs(fieldMoveVector.z)) then
		axisInfo.primaryAxis = axis.xEastWest
		axisInfo.secondaryAxis = axis.zNorthSouth
	else
		axisInfo.primaryAxis = axis.zNorthSouth
		axisInfo.secondaryAxis = axis.xEastWest
	end

	fieldInfo.axisInfo = axisInfo
	
	return fieldInfo
end

function printObject(object)
	print(ser.serialize(object,true))
end

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
	local myCoord = tripleToVector({myX,myY,myZ})
	local startCoord = sumVectors(myCoord,tripleToVector(fieldStart))
	local endCoord = sumVectors(myCoord,tripleToVector(fieldEnd))
	printObject(startCoord)
	printObject(endCoord)

	return FieldInfo:newFromParams(startCoord, endCoord)
end

function createVector(x,y,z)
	return {x = x, y = y, z = z}
end

function sumVectors(v1, v2)
--print(ser.serialize(v1))
--print(ser.serialize(v2))
	return createVector(v1['x'] + v2['x'], v1['y'] + v2['y'], v1['z'] + v2['z'])
end

function multiplyVectors(v1, v2)
	return createVector(v1['x'] * v2['x'], v1['y'] * v2['y'], v1['z'] * v2['z'])
end

function subtractVectors(v1, v2)
--print(ser.serialize(v1))
--print(ser.serialize(v2))
	return createVector(v1['x'] - v2['x'], v1['y'] - v2['y'], v1['z'] - v2['z'])
end


function tripleToVector(triple)
	--print(ser.serialize(triple))
	return createVector(triple[1], triple[2], triple[3])
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


--- automatic self-test
function t()
	v = function(x,y,z)
		return createVector(x,y,z)
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


