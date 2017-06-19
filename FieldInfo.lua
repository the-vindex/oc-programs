local vec = require("libvec")
local enums = require("OcEnums")
local axis = enums.axis

local FieldInfo = {___unload = true}

local _FieldInfo = {
	tostring= function(self)
		return "FieldInfo[start=" .. tostring(self.startCoord) ..", endCoord=".. tostring(self.endCoord) ..", fieldMoveVector=" .. tostring(self.fieldMoveVector) ..", axisInfo =" .. self.axisInfo.primaryAxis.name
	end
}

local vmetatable = {
	__index = _FieldInfo,
	__tostring = _FieldInfo.tostring
}

function FieldInfo:newFromParams(startCoord, endCoord)
	assert(vec.isVector(startCoord))
	assert(vec.isVector(endCoord))
	local fieldInfo = self:new()
	fieldInfo.startCoord = startCoord
	fieldInfo.endCoord = endCoord
	
	local fieldMoveVector = fieldInfo.endCoord - fieldInfo.startCoord
	
	fieldInfo.fieldMoveVector = fieldMoveVector

	local axisInfo = {}
	--select primary movement direction - in this direction we move forward, into other direction we just turn
	if (math.abs(fieldMoveVector.x)>=math.abs(fieldMoveVector.z)) then
		axisInfo.primaryAxis = enums.axis.xEastWest
		axisInfo.secondaryAxis = enums.axis.zNorthSouth
	else
		axisInfo.primaryAxis = enums.axis.zNorthSouth
		axisInfo.secondaryAxis = enums.axis.xEastWest
	end

	fieldInfo.axisInfo = axisInfo
		
	return fieldInfo
end


function FieldInfo:new(o)
	o = o or {}
	setmetatable(o, vmetatable)
  
  self.__index = self
	return o
end

function FieldInfo.unitTest()
  local function v(x,y,z) return vec.new(x,y,z) end
  
  local ass = require("luassert")
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

  print("FieldInfo unit tests ok")
end

--FieldInfo.unitTest()

return FieldInfo
