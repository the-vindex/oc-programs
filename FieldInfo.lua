local vec = require("libvec")
local enums = require("OcEnums")
local axis = enums.axis

local FieldInfo = {}

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

return FieldInfo
