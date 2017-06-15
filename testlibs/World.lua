local ShapeInfo = require("ShapeInfo")
local testTools = require("testlibs/MyAsserts")
local vector = require("libvec")
local ass = require("luassert")
local Blocks = require("testlibs/Blocks")

local World = ShapeInfo:new {
  breakBlock = function(self, x, y, z)
    self:breakBlockV(vector.new(x, y, z))
  end,
  
  breakBlockV = function(self, pos)
    local block = self:getV(pos)
    local result = { result = false, drops = {}}
    if block == nil then
      return result
    else
      result.result = true -- we are breaking something
      
      if type(block) ~= "table" then
        result.drops = {block} -- simple string-like blocks
      else
        result.drops = block.breakDrops        
      end      
      
      self:putV(pos, nil) -- and clear world
      
      return result
    end
    
  end,
  
  rightClickBlock = function(self, x, y, z, side, sneaking)
    self:rightClickBlockV(vector.new(x,y,z), side, sneaking)
  end,
  
  rightClickBlockV = function(self, pos, side, sneaking)
    local block = self:getV(pos)
    local failureResult = { result = false }
    if block == nil then
      return failureResult
    else
      if block.rightClick == nil then
        return failureResult
      else
        local res = block:rightClick(side,sneaking)
        if res ~= nil then
          res.result = true
          return res
        else
          return failureResult
        end
        
      end
    end
  end
}


function World.unitTest()
  tests = {
    testInheritance = function()
      local w = World:new {}
      
      w:put(1,2,3, "X")
      
      ass.message("world inherited put and get").same("X", w:get(1,2,3))
    end,
    
    testBreakBlock = function()
      local w = World:new()
      
      local pos = vector.new(0,0,0)
      w:putV(pos, "X")
      
      local drops = w:breakBlockV(pos).drops
      
      ass.message("Break block must set position in the world to nil").is_nil(w:getV(pos))
      ass.message("Break must return drops - simple block").same({"X"}, drops)      
    end,
    
    testBreakBlockComplex = function()
      local w = World:new()
      local pos = vector.new(0,0,1)
      w:putV(pos, Blocks.Plant:new(nil, "wheat", {"seeds"}, true, {"harvested wheat"}))
      
      local drops = w:breakBlockV(pos).drops
      
      ass.message("Break block must set position in the world to nil").is_nil(w:getV(pos))
      ass.message("Break must return drops - complex block").same({"seeds"}, drops)
    end,
    
    testRightClickPlant = function()
      local w = World:new()
    end
  }
  
  testTools.TestRunner(tests,"test")
end

--World.unitTest()

return World
