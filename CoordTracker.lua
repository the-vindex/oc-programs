local vector = require("libvec")
------------------ Coordinate Tracker
-- Coordinate Tracker will be able to track relative coordinates of the robot
-- This will be used for data driven block placement
-- (0,0,0) is located in lower left corner, positive z goes up
--  ^ +y
--  |
--  |
--  |-----> +x
-- creates vector
local function v(x,y,z)
   return vector.new(x,y,z)
end

---
-- @module CoordTracker
-- @type CoordTracker
local CoordTracker = {___unload = true}

--- Facing direction
-- @type DIR
CoordTracker.DIR = {X_PLUS  = {name="x+", left="Z_MINUS", right="Z_PLUS", forward=v(1,0,0), back=v(-1,0,0), sideApiValue = 5 },
					Z_PLUS  = {name="z+", left="X_PLUS", right="X_MINUS", forward=v(0,0,1), back=v(0,0,-1), sideApiValue = 3 },
          X_MINUS = {name="x-", left="Z_PLUS", right="Z_MINUS", forward=v(-1,0,0), back=v(1,0,0), sideApiValue = 4 },
					Z_MINUS = {name="z-", left="X_MINUS", right="X_PLUS" , forward=v(0,0,-1), back=v(0,0,1), sideApiValue = 2 }
					}
for name, value in pairs(CoordTracker.DIR) do
	value.leftObj = CoordTracker.DIR[value.left]
	value.rightObj = CoordTracker.DIR[value.right]
end

-- move = vector which will be added to current coordinates
-- wrap = parameter for peripheral.wrap() call
-- place = name of function for placing item in this direction
CoordTracker.MOVE_DIR = {
					UP = {name="y+", move = v(0,1,0), wrap = "top", place = "placeUp", sideApiValue = 1},
					DOWN = {name="y-", move = v(0,-1,0), wrap = "bottom", place = "placeDown", sideApiValue = 0},
					FORWARD = {name="forward", move = nil, wrap="front", place = "place"}, -- for forward move is direction dependant
					BACK = {name="back", move = nil} -- for back move is direction dependant
					}

CoordTracker.DIR.Y_PLUS = CoordTracker.MOVE_DIR.UP
CoordTracker.DIR.Y_MINUES = CoordTracker.MOVE_DIR.DOWN


CoordTracker.SIDEAPI_TO_DIR = {}
for _, direction in pairs(CoordTracker.DIR) do
  CoordTracker.SIDEAPI_TO_DIR[direction.sideApiValue] = direction
end

function CoordTracker.getDirFromSideApi(side)
  return CoordTracker.SIDEAPI_TO_DIR[side]
end

--- Constructor
-- @function [parent=#CoordTracker] new
-- @param #number x X
-- @param #number y Y
-- @param #number z Z
-- @param #DIR direction direction
-- @return #CoordTracker new instance
function CoordTracker:new(x, y, z, direction)
   local o = {}
   setmetatable(o, self)
   self.__index = self

   if direction.left == nil then
      error("Direction is suspicious: "..tostring(direction))
   end
   o.direction = direction
   o.coords = v(x,y,z)
   return o
end

function CoordTracker:turnRight()
   self.direction = CoordTracker.DIR[self.direction.right]
   return self
end

function CoordTracker:turnLeft()
   self.direction = CoordTracker.DIR[self.direction.left]
   return self
end

function CoordTracker:getCoords()
   return self.coords
end

function CoordTracker:getDirection()
   return self.direction
end

function CoordTracker:setCoords(newCoords)
   self.coords = coords
   return self
end

function CoordTracker:moveUp()
   self.coords = self:coordOf(CoordTracker.MOVE_DIR.UP)
   return self
end

function CoordTracker:moveDown()
   self.coords = self:coordOf(CoordTracker.MOVE_DIR.DOWN)
   return self
end

function CoordTracker:moveForward()
   self.coords = self:coordOf(CoordTracker.MOVE_DIR.FORWARD)
   return self
end

function CoordTracker:moveBack()
   self.coords = self:coordOf(CoordTracker.MOVE_DIR.BACK)
   return self
end

function CoordTracker:coordOf(moveDir)
   assert(moveDir ~= nil, "moveDir not specified")
   if moveDir == CoordTracker.MOVE_DIR.UP or moveDir == CoordTracker.MOVE_DIR.DOWN then
      return self.coords + moveDir.move
   elseif moveDir == CoordTracker.MOVE_DIR.FORWARD or moveDir == CoordTracker.MOVE_DIR.BACK then
      return self.coords + self.direction[moveDir.name]
   else
      error("Unknown direction "..s(moveDir))
   end
end

function CoordTracker.unitTest()
   local ass = require("luassert")
   local c = CoordTracker:new(2,2,2,CoordTracker.DIR.Z_PLUS)
   local vequals = function(v1, v2)
      return v1:equals(v2)
   end
   assert(vequals(v(1,1,1),v(1,1,1)), "equals function doesn't work")
   assert(CoordTracker.DIR.Z_PLUS.name == c:turnRight():turnRight():turnRight():turnRight().direction.name, "after turning 4x right we don't face same direction")
   assert(CoordTracker.DIR.Z_PLUS.name == c:turnLeft():turnLeft():turnLeft():turnLeft().direction.name, "after turning 4x left we don't face same direction")
   assert(vequals(v(2,2,2), c:turnRight():moveForward():turnRight():moveForward():turnRight():moveForward():turnRight():moveForward():getCoords()), "after making circle to right we did not finish at the start")
   assert(vequals(v(2,2,2), c:turnRight():moveBack():turnRight():moveBack():turnRight():moveBack():turnRight():moveBack():getCoords()), "after making circle to right we did not finish at the start")
   
   ass.same(v(2,3,2),c:moveUp():getCoords())
   ass.same(v(2,2,2),c:moveDown():getCoords())
   print("CoordTracker unitTest ok")
   
   ass.message("SideAPI mapping").equals(CoordTracker.DIR.Z_PLUS, CoordTracker.getDirFromSideApi(3))
end

--CoordTracker.unitTest()

return CoordTracker
