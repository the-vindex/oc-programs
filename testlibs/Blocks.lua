local testTools = require("testlibs/MyAsserts")
local ass = require("luassert")

local Blocks = {}

Blocks.BlockType = { Solid="Solid", Plant="Plant" }

local Block = {}
Blocks.Block = Block

function Block:new(o, blockType, name, breakDrops)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   o.blockType = blockType
   o.name = name
   o.breakDrops = breakDrops
   o.rightClickCount = 0
   
   return o
end

local Plant = Block:new()
Blocks.Plant = Plant

function Plant:new(o, name, breakDrops, rightClickHarvests, harvestDrops)
  o = Block.new(self, o, Blocks.BlockType.Plant, name, breakDrops)
    
  o.harvestDrops = harvestDrops
  o.rightClickHarvests = rightClickHarvests
  
  return o
end

function Plant:rightClick(side, sneaking)
  self.rightClickCount = self.rightClickCount + 1
  local drops = {}
  if self.rightClickHarvests then
    drops = self.harvestDrops 
  end
  return { drops = drops }
end


function Blocks.unitTest()
  local function createPlant()
    return Plant:new(nil, "wheat", {"seeds"}, false, {"harvested wheat"})
  end

  local tests = {
    test1_Block = function()
      local p = Block:new(nil, Blocks.BlockType.Plant, "wheat", {"seeds"})
      
      ass.message("correct name").same("wheat", p.name)
      ass.message("correct drops").same({"seeds"}, p.breakDrops)
      
    end,
    
    test2_PlantInheritance = function()
      local p = createPlant()
      
      ass.message("correct name").same("wheat", p.name)
      ass.message("correct drops").same({"seeds"}, p.breakDrops)
      ass.message("correct harvest").same({"harvested wheat"}, p.harvestDrops)
      
    end,
    
    test3_BlockRightClick_nodrops = function()
      local p = createPlant()
      p.rightClickHarvests = false 
      
      local drops = p:rightClick(nil, false).drops
      ass.message("rightclick counter increment").equals(1, p.rightClickCount)
      ass.message("should not harvest").same({}, drops)
    end,
    
    test3_BlockRightClick_nodrops = function()
      local p = createPlant()
      p.rightClickHarvests = true
      local drops = p:rightClick(nil, false).drops
      ass.message("should harvest").same({"harvested wheat"}, drops)
    end
  }

  testTools.TestRunner(tests, "test")
end

--Blocks.unitTest()

return Blocks
