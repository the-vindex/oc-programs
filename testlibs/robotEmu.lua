---Source: https://raw.github.com/theoriginalbit/CC-Emu-robot/master/api
local ShapeInfo = require("ShapeInfo")
local CoordTracker = require("CoordTracker")
local vector = require("libvec")

--- Item Stack
-- @type ItemStack
ItemStack = {}

---
-- @function [parent=#ItemStack] new
-- @param #string itemType
-- @param #number count
-- @return #ItemStack
function ItemStack:new(itemType, count)
   local o = {}
   setmetatable(o, self)
   self.__index = self

   o.itemType = itemType
   o.count = count
   return o
end



---
-- @type robot
local robot = {
  native = {}
}

function robot.resetrobot()
--	robot.native = {}
	
	--- @field [parent=#robot] #table slotContents
	robot.slotContents = {}
		for i = 1,16 do robot.slotContents[i] = {} end
	--- @field [parent=#robot] #ShapeInfo world
	robot.world = ShapeInfo:new()
	--- @field [parent=#robot] #CoordTracker coord
	robot.coord = CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS)
	--- @field [parent=#robot] #number activeSlot
	robot.activeSlot = 1
end

local resetrobot = robot.resetrobot()

robot.resetrobot()


function robot.native.craft( quantity )
  return false
end

local function canMoveIntoDirection(dir)
	return robot.world:getV(robot.coord:coordOf(dir)) == nil
end


function robot.native.forward()
  if canMoveIntoDirection(CoordTracker.MOVE_DIR.FORWARD) then
    robot.coord:moveForward()
    return true
  else
    return false
  end
end

function robot.native.back()
  if canMoveIntoDirection(CoordTracker.MOVE_DIR.BACK) then
    robot.coord:moveBack()
    return true
  else
    return false
  end
end

function robot.native.down()
  if canMoveIntoDirection(CoordTracker.MOVE_DIR.DOWN) then
    robot.coord:moveDown()
    return true
  else
    return false
  end
end

function robot.native.up()
  if canMoveIntoDirection(CoordTracker.MOVE_DIR.UP) then
    robot.coord:moveUp()
    return true
  else
    return false
  end
end

function robot.native.turnLeft()
  robot.coord:turnLeft()
  return true
end

function robot.native.turnRight()
  robot.coord:turnRight()
  return true
end

function robot.native.select( slot )
  if slot < 0 or slot > 16 then error('Slot out of bounds of inventory: '..slot, 2) end
  robot.activeSlot = slot
  return true
end

function robot.native.getItemCount( slot )
  if slot < 0 or slot > 16 then error('Slot out of bounds of inventory: '..slot, 2) end
  return math.random(0, 64)
end

function robot.native.getItemSpace( slot )
  if slot < 0 or slot > 16 then error('Slot out of bounds of inventory: '..slot, 2) end
  return math.random(0, 64)
end

function robot.native.attack()
  return true
end

function robot.native.attackUp()
  return true
end

function robot.native.attackDown()
  return true
end

function robot.native.swing()
  return true
end

function robot.native.swingUp()
  return true
end

function robot.native.swingDown()
  return true
end

function robot.native._placeInner(dir)
  local itemStack = robot.slotContents[robot.activeSlot]
  if itemStack.count == nil or itemStack.count == 0 then
	return false
  end

  --check for block
  if not(canMoveIntoDirection(dir)) then
	return false
  end

  robot.world:putV(robot.coord:coordOf(dir), itemStack.itemType)
  itemStack.count = itemStack.count - 1
  return true
end

function robot.native.place( text )
  return robot._placeInner(CoordTracker.MOVE_DIR.FORWARD)
end

function robot.native.placeUp()
  return robot._placeInner(CoordTracker.MOVE_DIR.UP)
end

function robot.native.placeDown()
  return robot._placeInner(CoordTracker.MOVE_DIR.DOWN)
end

function robot.native.detect()
  return false
end

function robot.native.detectUp()
  return false
end

function robot.native.detectDown()
  return false
end

--~ function robot.native.compare()
--~   return (math.random(1, 2) == 1) -- 50% chance of being the same
--~ end

--~ function robot.native.compareUp()
--~   return (math.random(1, 2) == 1) -- 50% chance of being the same
--~ end

--~ function robot.native.compareDown()
--~   return (math.random(1, 2) == 1) -- 50% chance of being the same
--~ end

--~ function robot.native.compareTo( slot )
--~   if slot < 0 or slot > 16 then error('Slot out of bounds of inventory: '..slot, 2) end
--~   return (math.random(1, 10) == 4) -- 10% chance of being the same
--~ end

function robot.native.drop( amount )
  return true
end

function robot.native.dropUp( amount )
  return true
end

function robot.native.dropDown( amount )
  return true
end

--~ function robot.native.suck()
--~   return true
--~ end

--~ function robot.native.suckUp()
--~   return true
--~ end

--~ function robot.native.suckDown()
--~   return true
--~ end

function robot.native.refuel( amount )
  amount = math.min(amount, robot.slotContents[robot.activeSlot])
  robot.fuelLevel = robot.fuelLevel + (amount * 80) -- emulate coal
  robot.slotContents[robot.activeSlot] = robot.slotContents[robot.activeSlot] - amount
  return true
end

function robot.native.getFuelLevel()
  return math.random(0, 40960)
end

function robot.native.transferTo( slot, amount )
  if slot < 0 or slot > 16 then error('Slot out of bounds of inventory: '..slot, 2) end
  return true
end

function robot.native.use(side, sneaking, duration)
  local block = robot.world:getV(robot.coord.coords+robot.coord.direction.forward)
  return robot.native._useInner(block, side, sneaking, duration)
end

function robot.native.useDown(side, sneaking, duration)
  local block = robot.world:getV(robot.coord.coords + CoordTracker.MOVE_DIR.DOWN.move)
  return robot.native._useInner(block, side, sneaking, duration)
end

function robot.native.useUp(side, sneaking, duration)
  local block = robot.world:getV(robot.coord.coords + CoordTracker.MOVE_DIR.UP.move)
  return robot.native._useInner(block, side, sneaking, duration)
end

function robot.native._useInner(block, side, sneaking, duration)
  local result = false
  
  if block ~= nil then
    result = true
    
    if type(block) == "table" and block.rightClick ~= nil then
      local rightClickResult = block:rightClick()
      local drops = rightClickResult.drops
      for _, drop in pairs(drops) do
        local slot = robot.slotContents[robot.activeSlot]
        if slot.count ~= nil and slot.count > 0 then
          error("Simulator doesn't support merging of stacks, implementation of inventory simulation is needed")
        end
        robot.slotContents[robot.activeSlot] = drop
      end
    end
  end
  
  return result
end

-- make copies
for k,v in pairs(robot.native) do
  robot[k] = v
end

-- ====================================== TESTING

function robot.unitTest()
  local origPath = package.path
  package.path="./?/init.lua;" .. package.path
	package.path="./testlibs/?.lua;" .. package.path
  
	require("minecraftCompat")
	local testTools = require("MyAsserts")
	local ass = require("luassert")
  local Blocks = require("Blocks")
  
  package.path = origPath
  
	local function v(x,y,z)
		return vector.new(x,y,z)
	end

  local tests = {}

	function tests.helper_unitTest_move(params)
		local startingDir = params.startingDir or CoordTracker.DIR.X_PLUS
		local obstacle = params.obstacle
		local expectedCoord = params.expectedCoord
		local callThis = params.callThis
		local testOnlyPositive = params.testOnlyPositive
		local testOnlyNegative = params.testOnlyNegative

		if not(testOnlyNegative) then
			--test successful move
			robot.coord = CoordTracker:new(0,0,0, startingDir)
			robot.world = ShapeInfo:new()

			ass.same(callThis(), true)
			ass.same(robot.coord:getCoords(), expectedCoord)
		end

		if not(testOnlyPositive) then
			--test blocked move
			robot.coord = CoordTracker:new(0,0,0, startingDir)
			robot.world = ShapeInfo:new()

			if obstacle ~= nil then
				robot.world:putV(obstacle.coord, obstacle.value)
			end

			ass.same(callThis(), false)
			ass.same(robot.coord:getCoords(), v(0,0,0))
		end
	end


	function tests.unitTest_moveForward()

		tests.helper_unitTest_move({
			callThis = robot.forward,
			expectedCoord = v(1,0,0),
			obstacle = {coord = v(1,0,0), value = "A"}
		})
	end

	function tests.unitTest_moveBack()

		tests.helper_unitTest_move({
			callThis = robot.back,
			expectedCoord = v(-1,0,0),
			obstacle = {coord = v(-1,0,0), value = "A"}
		})
	end

	function tests.unitTest_moveUp()

		tests.helper_unitTest_move({
			callThis = robot.up,
			expectedCoord = v(0,1,0),
			obstacle = {coord = v(0,1,0), value = "A"}
		})
	end

	function tests.unitTest_moveDown()

		tests.helper_unitTest_move({
			callThis = robot.down,
			expectedCoord = v(0,-1,0),
			obstacle = {coord = v(0,-1,0), value = "A"}
		})
	end

	function tests.unitTest_turnRight()

		tests.helper_unitTest_move({
			callThis = robot.turnRight,
			expectedCoord = v(0,0,0),
			testOnlyPositive = true
		})

		ass.same(robot.coord:getDirection().name, CoordTracker.DIR.Z_MINUS.name)
	end

	function tests.unitTest_turnLeft()

		tests.helper_unitTest_move({
			callThis = robot.turnLeft,
			expectedCoord = v(0,0,0),
			testOnlyPositive = true
		})

		ass.same(robot.coord:getDirection().name, CoordTracker.DIR.Z_PLUS.name)
	end

	function tests.helper_unitTest_place_ok(callThis, targetCoord)

		robot.activeSlot = 1
		robot.slotContents[1] = ItemStack:new("X", 10)

		tests.helper_unitTest_move({
			callThis = callThis,
			expectedCoord = v(0,0,0),
			testOnlyPositive = true
		})

		ass.same(robot.world:getV(targetCoord), "X")
		ass.same(robot.slotContents[1].count, 9)
	end

	function tests.helper_unitTest_place_failsIfSlotEmpty(callThis,targetCoord)

		robot.activeSlot = 1
		robot.slotContents[1] = {}

		tests.helper_unitTest_move({
			callThis = callThis,
			expectedCoord = v(0,0,0),
			testOnlyNegative = true
		})

		ass.same(robot.world:getV(targetCoord), nil)
		ass.same(robot.slotContents[1].count, nil)
	end

	function tests.helper_unitTest_place_failsSpaceOccupied(callThis,targetCoord)

		robot.activeSlot = 1
		robot.slotContents[1] = ItemStack:new("X", 10)

		tests.helper_unitTest_move({
			callThis = callThis,
			expectedCoord = v(0,0,0),
			obstacle = {coord = targetCoord, value = "A"},
			testOnlyNegative = true
		})

		ass.same(robot.world:getV(targetCoord), "A")
		ass.same(robot.slotContents[1].count, 10)
	end

	function tests.helper_unitTest_place(func,targetCoord)
		tests.helper_unitTest_place_ok(func,targetCoord)
		tests.helper_unitTest_place_failsIfSlotEmpty(func,targetCoord)
		tests.helper_unitTest_place_failsSpaceOccupied(func,targetCoord)
	end

	function tests.unitTest_place_forward()
		tests.helper_unitTest_place(robot.place, v(1,0,0))
	end

	function tests.unitTest_place_down()
		tests.helper_unitTest_place(robot.placeDown, v(0,-1,0))
	end

	function tests.unitTest_place_up()
		tests.helper_unitTest_place(robot.placeUp, v(0,1,0))
	end
   
  function tests.unitTest_use()
    robot.activeSlot = 1
		robot.slotContents[1] = {}
    robot.coord = CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS)
  
    function createPlant(drop)
      return Blocks.Plant:new(nil, "wheat", {"seeds"}, true, {drop})
    end
    
    function verifyResult(message, block, expectedClickCount, expectedDrop)
      ass.message(message..": rightclicked a block").equals(expectedClickCount, block.rightClickCount)
      ass.message(message..": harvested drop is in the slot").equals(expectedDrop, robot.slotContents[1])
    end
  
    local plant1 = createPlant("front wheat")
    robot.world:put(0,0,1, plant1)
    local plant2 = createPlant("bottom wheat")
    robot.world:put(0,-1,0, plant2)
    local plant3 = createPlant("top wheat")
    robot.world:put(0,1,0, plant3)
    
    robot.use(nil, false, nil)
    verifyResult("use front", plant1, 1, "front wheat")
    
    robot.useDown(nil, false, nil)
    verifyResult("use down", plant2, 1, "bottom wheat")
    
    robot.useUp(nil, false, nil)
    verifyResult("use up", plant3, 1, "top wheat")
    
  end

  testTools.TestRunner(tests,"unitTest_", resetrobot)
end

-- robot.unitTest()

return robot
