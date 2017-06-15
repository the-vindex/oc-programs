local vector = require "libvec"

---
-- @module ShapeInfo
-- @type ShapeInfo
ShapeInfo = {}

--- Create a new ShapeInfo
-- @function [parent=#ShapeInfo] new
-- @return ShapeInfo
function ShapeInfo:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   o.data = {}
   o.coordCache = {} -- cache of "x:y:z" = {x=x,y=y,z=z} for simple traversing of own data

   return o
end

function ShapeInfo:put(x,y,z,value)
   local coord = x..":"..y..":"..z

   self.data[coord] = value
   self.coordCache[coord] = {x=x, y=y, z=z}
end

-- vector put
function ShapeInfo:putV(vect, value)
   self:put(vect.x,vect.y,vect.z,value)
end

function ShapeInfo:get(x, y, z)
   assert(type(x) == "number", "Must be number")

   local coord = x..":"..y..":"..z
   return self.data[coord]
end

-- vector get
function ShapeInfo:getV(vect)
   return self:get(vect.x,vect.y,vect.z)
end

function ShapeInfo:fillYLayer(minX, maxX, minZ, maxZ, y, value)
   for x = minX, maxX do
      for z = minZ, maxZ do
	     self:put(x,y,z,value)
	  end
   end
end

--returns 2 vectors - min and max
function ShapeInfo:getBorderCubeCoords(yFrom, yTo)
   local isLimitY = false
   if yFrom ~= nil and yTo == nil then
		yTo = yFrom
   end

   if yFrom ~= nil then
   		isLimitY = true
	end

   assert(yFrom == nil or tonumber(yFrom) ~= nil, "Either do not specify yFrom or it must be a number")
   assert(yTo == nil or tonumber(yTo) ~= nil, "Either do not specify yTo or it must be a number")
   assert(not(isLimitY) or yFrom <= yTo, "From must be greater then To")

   local minX, maxX, minY, maxY, minZ, maxZ = 1000000,-1000000,1000000,-1000000,1000000,-1000000
   local pointInCubeExists = false
   if (yFrom ~= nil) then
		--print("Limits",yFrom,yTo)
	else
		--print("No limits")
	end
	
   for coord, value in pairs(self.data) do
		local c = self.coordCache[coord]
		--print("Examining coord "..coord)
		if value ~= nil and (not(isLimitY) or (c.y >= yFrom and c.y <= yTo)) then
			minX = math.min(minX, c.x)
			minY = math.min(minY, c.y)
			minZ = math.min(minZ, c.z)
			maxX = math.max(maxX, c.x)
			maxY = math.max(maxY, c.y)
			maxZ = math.max(maxZ, c.z)
			pointInCubeExists = true
		end
   end
   if pointInCubeExists then
   	return vector.new(minX,minY,minZ), vector.new(maxX,maxY,maxZ)
   else
   	return nil, nil
   end
end


-- goes layer by layer (z) and prints farm
function ShapeInfo:printShape()
	local minV, maxV = self:getBorderCubeCoords()
	for y = maxV.y, minV.y, -1 do
		local actual = ""
		for z = maxV.z, minV.z, -1 do
			local line = ""
			for x = minV.x, maxV.x do
				local value = self:get(x, y, z)
				if value ~= nil then
					line = line..tostring(value)
				else
					line = line.." "
				end
			end

			actual = actual..line.."|\n"
		end
		print(actual)
	end
end


function ShapeInfo.unitTest()
   local ass = require("luassert")
   local shapeInfo = ShapeInfo:new()
   for z = 1,4 do
      shapeInfo:fillYLayer(1,5,1,5,z,"F")
   end
   assert(shapeInfo:get(1,1,4) == "F")
   shapeInfo:put(1,1,4, "T")
   assert(shapeInfo:get(1,1,4) == "T")

   --global border cube test
   local s = ShapeInfo:new()
   s:put(1,2,3,"A")
   s:put(-1,-2,-3,"B")
   local minV, maxV = s:getBorderCubeCoords()
   ass.same(minV, vector.new(-1,-2,-3))
   ass.same(maxV, vector.new(1,2,3))

   --test specific y values
   local s = ShapeInfo:new()
   s:put(9,6,2,"A")
   s:put(5,4,2,"A")

   s:put(1,3,2,"A")
   s:put(-1,3,-2,"A")

   s:put(-5,-3,-6,"B")
   local minV, maxV = s:getBorderCubeCoords(3)
   ass.same(minV, vector.new(-1,3,-2))
   ass.same(maxV, vector.new(1,3,2))

   local minV, maxV = s:getBorderCubeCoords(-3, 3)
   ass.same(minV, vector.new(-5,-3,-6))
   ass.same(maxV, vector.new(1,3,2))

   -- test removing items
   local s = ShapeInfo:new()
   s:putV(vector.new(1,2,3),"A")
   s:putV(vector.new(-1,-2,-3),"B")
   s:put(-1,-2,-3,nil)
   local minV, maxV = s:getBorderCubeCoords()
   ass.same(minV, vector.new(1,2,3))
   ass.same(maxV, vector.new(1,2,3))
   
   -- test empty layer
   local s = ShapeInfo:new()
   s:put(1,3,2,"A")
   s:putV(vector.new(-1,-3,-2),"B")
   local minV, maxV = s:getBorderCubeCoords(2)
   ass.same(minV, nil)
   ass.same(maxV, nil)


   print("ShapeInfo unitTest ok")
end


return ShapeInfo
