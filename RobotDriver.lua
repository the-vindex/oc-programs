local CoordTracker = require("CoordTracker")
local ShapeInfo = require("ShapeInfo")
local vector = require("libvec")
local Pathfinder = require("Pathfinder")

--detect whether we are in MC
local res, robot = pcall(function() return require("robot") end)
local ingame
if type(robot) == 'table' then
	ingame = true
else
	ingame = false
end

local sleep
local Blocks
if not(ingame) then
	robot = require("testlibs/robotEmu")
  Blocks = require("testlibs/Blocks")
	sleep = function() end
else
	sleep = os.sleep
end

DOWN = "down"
UP = "up"
FRONT = "front"

local RobotDriver = {___unload = true}

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function RobotDriver:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   o.coordTracker = CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS)
   return o
end

function RobotDriver:listMethods()
   local methods = {}
   for name,originalFunction in pairs(self) do
      methods[name] = originalFunction
   end

   for name,originalFunction in pairs(getmetatable(self)) do
      methods[name] = originalFunction
   end

   --forbidden symbols
   methods["__index"] = nil
   methods["new"] = nil
   methods["listMethods"] = nil

   return methods
end

function RobotDriver:turnLeft()
   robot.turnLeft()
   self.coordTracker:turnLeft()
end

function RobotDriver:turnRight()
   robot.turnRight()
   self.coordTracker:turnRight()
end

function RobotDriver:moveForward()
   local res = self:_cycle(function() return robot.forward() end)
   if res then self.coordTracker:moveForward() end
   return res
end

function RobotDriver:moveBack()
   local res = self:_cycle(function() return robot.back() end)
   if res then self.coordTracker:moveBack() end
   return res
end

function RobotDriver:moveUp()
   local res = self:_cycle(function() return robot.up() end)
   if res then self.coordTracker:moveUp() end
   return res
end

function RobotDriver:moveDown()
   local res = self:_cycle(function() return robot.down() end)
   if res then self.coordTracker:moveDown() end
   return res
end

function RobotDriver:_cycle(f)
   local count = 10

   repeat
     sleep(1)
     count = count - 1
   until f() or count == 0

   return count > 0 -- if count >0, then we were successful
end

function RobotDriver:dig(item)
   self:_doWithItem(item, robot.dig, true)
end

function RobotDriver:digUp(item)
   self:_doWithItem(item, robot.digUp, true)
end

function RobotDriver:digDown(item)
   self:_doWithItem(item, robot.digDown, true)
end

function RobotDriver:suck(item)
   self:_doWithItem(item, robot.suck, true)
end

function RobotDriver:suckUp(item)
   self:_doWithItem(item, robot.suckUp, true)
end

function RobotDriver:suckDown(item)
   self:_doWithItem(item, robot.suckDown, true)
end

function RobotDriver:discardDig(digDirection)
   print("DisacrdDig")
   print("Item: ", ITEM)
   print("ITEM.EMPTY: ", s(ITEM.EMPTY.slot))

   local digDirections
   if (type(digDirection) == "string") then
      digDirections = {digDirection}
   else
      digDirections = digDirection
   end

   for _, digDirection in ipairs(digDirections) do
	   self:_chooseSlotByItem(ITEM.EMPTY)
	   robot.drop()

	   if digDirection == DOWN then
		  robot.digDown()
		  robot.dropDown()
	   elseif digDirection == UP then
		  robot.digUp()
		  robot.dropUp()
	   elseif digDirection == FRONT then
		  robot.dig()
		  robot.drop()
	   else
		  error("Unknown dig direction: "..digDirection)
	   end
   end
end

function RobotDriver:place(item)
   self:_doWithItem(item, robot.place)
end

function RobotDriver:placeUp(item)
   self:_doWithItem(item, robot.placeUp)
end

function RobotDriver:placeDown(item)
   self:_doWithItem(item, robot.placeDown)
end

function RobotDriver:dropDown(item, doNotFail)
   self:_doWithItem(item, robot.dropDown, doNotFail)
end

function RobotDriver:_doWithItem(item, funcToDo, doNotFail)
   self:_chooseSlotByItem(item)

   if not funcToDo() and doNotFail ~= true then
      error("Operation with "..item.name.." failed, coord = " .. self.coordTracker.coords:tostring())
   end
end

function RobotDriver:_chooseSlotByItem(item)
   assert(item ~= nil, "Item must not be nil")
   robot.select(item.slot)
end


function RobotDriver:takeFromChest(item, count)
    if (count == nil) then
	   count = 64
	end
	local chest = peripheral.wrap("bottom")
	for slotNumber = 0, 26 do
	   local slotContents = chest.getStackInSlot(slotNumber)
	   if slotContents ~= nil and item.uuid == uuid(slotContents.id, slotContents.dmg) then
	      chest.pushIntoSlot("up", slotNumber, count, item.slot-1) -- openperipherals count slots from 0
		  return true
	   end
	end
	return false
end


function RobotDriver:_resupply()
    self:discardDig(DOWN)
	self:placeDown(ITEM.CHEST_IN)
	for name, item in pairs(ITEM) do
	   --print("Considering "..name)
	   if item.alwaysClearDuringResupply or (item.minAmount ~= nil and robot.getItemCount(item.slot)<= item.minAmount) then
	      if item.alwaysClearDuringResupply then
	      	self:dropDown(item)
	      end
	      local weHave = robot.getItemCount(item.slot)
		  local weShouldHave = item.restockAmount
		  while(weHave < weShouldHave) do
		     self:takeFromChest(item,weShouldHave-weHave)
			 weHave = robot.getItemCount(item.slot)
			 sleep(0.3)
		  end
	   end
	end
	self:digDown(ITEM.CHEST_IN)
	
	-- now we discard any items that require this - be careful with this setting
	for name, item in pairs(ITEM) do
	   if item.discardDuringResupply then
	   		self:dropDown(item, true)
	   end
	end
end

function RobotDriver:_checkFuel()
   if robot.getFuelLevel()<400 then
      self:discardDig(DOWN)
	  self:placeDown(ITEM.CHEST_IN)
	  self:takeFromChest(ITEM.CHARCOAL, 10)
	  self:_chooseSlotByItem(ITEM.CHARCOAL)
	  robot.refuel()
	  self:digDown(ITEM.CHEST_IN)
   end
end

function RobotDriver:doLeftTurn(bool)
  if bool then
	 self:turnLeft()
  else
	 self:turnRight()
  end
end

function RobotDriver:_clear3Layers()
   local leftTurn = true
   local linesLeft = 5
   while (linesLeft > 0) do
      linesLeft = linesLeft - 1
      for i = 1,4 do
	     self:discardDig({DOWN, FRONT, UP})
		 self:moveForward()
	  end

	  -- if more lines to do left, then move to next line
	  if (linesLeft > 0) then
	     self:doLeftTurn(leftTurn)
	     self:discardDig({DOWN, FRONT, UP})
	     self:moveForward()
	     self:doLeftTurn(leftTurn)
	     leftTurn = not(leftTurn)
	  else
	     self:discardDig({DOWN, UP})
	  end
	  self:_checkFuel()
   end
end

function RobotDriver:placeAndConfigure(shapeInfo, moveDir)
   assert(shapeInfo ~= nil, "shapeInfo is nil")
   assert(moveDir ~= nil, "moveDir is nil")
   --print("My current:"..self.coordTracker:getCoords():tostring())
   local coord = self.coordTracker:coordOf(moveDir)
   --print("Target coord:"..coord:tostring())
   local item = shapeInfo:getV(coord)
   if item ~= nil then
      --print("Target item:"..item.name)
	  self[moveDir.place](self, item)
	  if item.tesseractConfig ~= nil then
		 local p = peripheral.wrap(moveDir.wrap)
		 assert(p ~= nil, "Peripheral not found")
		 local result = p.setFrequency(item.tesseractConfig.freq)
		 if (p.setMode ~= nil) then
		 	p.setMode("RECEIVE")
		 end
		 if not(result) then
		 	print("Configuration of "..item.name.." failed")
		 end
	  end
   end
end

function RobotDriver:placeAndMove(shapeInfo)
   assert(shapeInfo ~= nil, "shapeInfo is nil")
   self:placeAndConfigure(shapeInfo, CoordTracker.MOVE_DIR.UP)
   self:placeAndConfigure(shapeInfo, CoordTracker.MOVE_DIR.DOWN)
   self:moveBack()
   self:placeAndConfigure(shapeInfo, CoordTracker.MOVE_DIR.FORWARD)
end

function RobotDriver:moveTo(targetCoord, callbackParam)
	local whereTo = targetCoord - self.coordTracker:getCoords()
	local moveCallback = callbackParam or function() end
	for i = 1,math.abs(whereTo.y) do
		if(whereTo.y<0) then
			self:moveDown()
		end
		if(whereTo.y>0) then
			self:moveUp()
		end
		whereTo = targetCoord - self.coordTracker:getCoords()
	end

	if (whereTo.z ~= 0) then

		local correctDirection
		if (whereTo.z > 0) then
			correctDirection = CoordTracker.DIR.Z_PLUS
		else
			correctDirection = CoordTracker.DIR.Z_MINUS
		end

		for _ = 1,4 do
			if self.coordTracker:getDirection().name ~= correctDirection.name then
				self:turnRight()
			end
		end

		for _ = 1,math.abs(whereTo.z) do
			self:moveForward()
			moveCallback(self)
		end
	end

	if (whereTo.x ~= 0) then

		local correctDirection
		if (whereTo.x > 0) then
			correctDirection = CoordTracker.DIR.X_PLUS
		else
			correctDirection = CoordTracker.DIR.X_MINUS
		end

		for _ = 1,4 do
			if self.coordTracker:getDirection().name ~= correctDirection.name then
				self:turnRight()
			end
		end

		for _ = 1,math.abs(whereTo.x) do
			self:moveForward()
			moveCallback(self)
		end
	end
end


function RobotDriver:autoBuild(shapeInfo, coordTracker)
	self.coordTracker = coordTracker
	local minV,maxV = shapeInfo:getBorderCubeCoords()
	local maxY, minY = maxV.y, minV.y
	local offset = vector.new(0,1,0)

	for y = maxY, minY, -1 do
		local path = Pathfinder.calculatePath(coordTracker, shapeInfo, y)
		
		if #path > 0 then
			self:moveTo(path[1]-offset)
			self:placeAndConfigure(shapeInfo, CoordTracker.MOVE_DIR.UP)
			for i = 2, #path do
				self:moveTo(path[i]-offset, function() 
					self:placeAndConfigure(shapeInfo, CoordTracker.MOVE_DIR.UP)
				end)
				self:_resupply()
				self:_checkFuel()
			end
		end
	end
end

function RobotDriver:autoHarvest(shapeInfo, coordTracker)
	self.coordTracker = coordTracker
	local minV,maxV = shapeInfo:getBorderCubeCoords()
	local maxY, minY = maxV.y, minV.y
  local d = vector.new(0, 0, 0)

	for y = maxY, minY, -1 do
		local path = Pathfinder.calculatePath(coordTracker, shapeInfo, y)
		require("VLibs").printTable(path)

		if #path > 0 then
			self:moveTo(path[1] + d)
			self:harvestPlantDown(shapeInfo)
			for i = 2, #path do
        print(tostring(vector.new(require("component").navigation.getPosition())))
				self:moveTo(path[i]  + d, function() 
					self:harvestPlantDown(shapeInfo)
				end)
				--self:_resupply()
				--self:_checkFuel()
			end
		end
	end
end

function RobotDriver:harvestPlantDown(shapeInfo)
  robot.useDown()
end


function RobotDriver:buildFarm()
   -- Building 5x5x4 farm
   -- robot starts at south eastern top corner of the farm - just above the farm level.
   -- South-eastern is relative to robot current facing
   --  Top view			Side view					Top view z=1    Soil layers
   -- +y			|+z                          |  +y            | E
   --5FFFFF			|4FFFFF                      |  5FFFFF        | S
   -- FFFFF			| FFFFF                      |   FFFFF        |  BFFFFFB
   -- FFFFF			| FFFFF                      |   FFGFH        | E FFFFF
   -- FFFFF			| FFXFX <= functional blocks |   FFVFH        | S FFFFF
   --1FFFFF +x		|0  T T <= tesseracts etc    |  1FFHFH +x     |  BFFFFFB
   --01   X<--robot is on 5,0,5 coord           |  01            |     T T
   --                                                               E
   --                                                               S

   self:_resupply()

   --- @{#ShapeInfo}
   local shapeInfo = ShapeInfo:new()
   for z = 1,4 do
      shapeInfo:fillYLayer(1,5,1,5,z,ITEM.FARM_BLOCK)
   end
   -- functional farm blocks
   shapeInfo:put(5,1,1,ITEM.FARM_HATCH)
   shapeInfo:put(5,2,1,ITEM.FARM_HATCH)
   shapeInfo:put(5,3,1,ITEM.FARM_HATCH)
   shapeInfo:put(3,1,1,ITEM.FARM_HATCH)
   shapeInfo:put(3,2,1,ITEM.FARM_VALVE)
   shapeInfo:put(3,3,1,ITEM.FARM_GEARBOX)
   -- functional non-farm blocks
   shapeInfo:put(5,1,0,ITEM.ITEM_TESSERACT_1)
   shapeInfo:put(5,2,0,ITEM.ITEM_TESSERACT_2)
   shapeInfo:put(5,3,0,ITEM.ITEM_TESSERACT_3)
   shapeInfo:put(3,1,0,ITEM.ENDER_CHEST)
   shapeInfo:put(3,2,0,ITEM.WATER_TESSERACT)
   shapeInfo:put(3,3,0,ITEM.ENERGY_TESSERACT)
   --
   shapeInfo:layoutFarm(1,1, 1, 5,5, 6, ITEM.STONE_BRICK)
   shapeInfo:layoutFarm(1,1, 4, 5,5, 6, ITEM.STONE_BRICK)

   self:autoBuild(shapeInfo, CoordTracker:new(5,0,5, CoordTracker.DIR.Z_PLUS))
end

------------------------- Unit tests
function RobotDriver.unitTest_automove()
	local ass = require("luassert")
  local testTools = require("testlibs/MyAsserts")

	local function v(x,y,z)
		return vector.new(x,y,z)
	end

	-- commands robot to move to the target point from starting coordinate specified by CoordTracker
	function RobotDriver._testMoveTo(target, startingCoordTracker)
		if startingCoordTracker == nil then
			startingCoordTracker = CoordTracker:new(0,0,0, CoordTracker.DIR.X_PLUS)
		end

		local f = RobotDriver:new()
		f.coordTracker = startingCoordTracker

		f:moveTo(target)
		ass.same(target, f.coordTracker:getCoords())
	end

	function RobotDriver.automoveTestMoveDown()
		RobotDriver._testMoveTo(v(0,-3,0))
	end

	function RobotDriver.automoveTestMoveUp()
		RobotDriver._testMoveTo(v(0,3,0))
	end

	function RobotDriver.automoveTestGoToYWithTurn()
		RobotDriver._testMoveTo(v(0,0,3))
		RobotDriver._testMoveTo(v(0,0,-3))
	end

	function RobotDriver.automoveTestGoToYWithoutTurn()
		RobotDriver._testMoveTo(v(0,3,0), CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS))
		RobotDriver._testMoveTo(v(0,-3,0), CoordTracker:new(0,0,0, CoordTracker.DIR.Z_MINUS))
	end

	function RobotDriver.automoveTestGoToXWithTurn()
		RobotDriver._testMoveTo(v(0,3,0), CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS))
		RobotDriver._testMoveTo(v(0,-3,0), CoordTracker:new(0,0,0, CoordTracker.DIR.Z_PLUS))
	end

	function RobotDriver.automoveTestGoToXWithoutTurn()
		RobotDriver._testMoveTo(v(3,0,0), CoordTracker:new(0,0,0, CoordTracker.DIR.X_PLUS))
		RobotDriver._testMoveTo(v(-3,0,0), CoordTracker:new(0,0,0, CoordTracker.DIR.X_MINUS))
	end

	function RobotDriver.automoveTestGoToAny()
		RobotDriver._testMoveTo(v(4,3,-5))
	end

	function RobotDriver.automoveTestMoveWithCallback()
		local f = RobotDriver:new()
		local callbackCalledTimes = 0

		f.coordTracker = CoordTracker:new(0,0,0, CoordTracker.DIR.X_PLUS)

		f:moveTo(v(0,0,3), function(o)
			assert(o ~= nil)
			callbackCalledTimes = callbackCalledTimes + 1
		end
		)

		ass.same(callbackCalledTimes, 3)
	end

--	for name, func in pairs(RobotDriver) do
--		if string.starts(name, "automoveTest") then
--			print("Running "..name)
--			func()
--		end
--	end
  
  testTools.TestRunner(RobotDriver, "automoveTest", function() robot.resetrobot() end)

	print("unitTest_automove ok")
end

function RobotDriver.unitTest_autobuild()
	local ass = require("luassert")
	local testTools = require("testlibs/MyAsserts")
	local oldResupply = RobotDriver._resupply
	RobotDriver._resupply = function() end

	function RobotDriver.helper_autobuildTest_setup()
		-- setup world emulation
		robot.world = ShapeInfo:new()
		robot.coord = CoordTracker:new(5,5,5, CoordTracker.DIR.X_PLUS)
		robot.slotContents[1] = ItemStack:new("A", 10)

		-- setup our robot model
		local fb = RobotDriver:new()

		local request = ShapeInfo:new()
		local currentCoordFb = CoordTracker:new(5,5,5, CoordTracker.DIR.X_PLUS)
		return fb, request, currentCoordFb
	end

	function RobotDriver.autobuildTest_1onePoint()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()

		request:put(0,0,0, {slot=1})

		fb:autoBuild(request, currentCoordFb)
		ass.same(vector.new(0,-1,0), robot.coord:getCoords())
		ass.same("A", robot.world:get(0,0,0))
	end


	function RobotDriver.autobuildTest_2twoPoints()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()

		request:put(0,0,0, {slot=1})
		request:put(-2,0,0, {slot=1})

		fb:autoBuild(request, currentCoordFb)
		ass.same(robot.coord:getCoords(), vector.new(-2,-1,0))
		ass.same(robot.world:get(0,0,0), "A")
		ass.same(robot.world:get(-1,0,0), nil)
		ass.same(robot.world:get(-2,0,0), "A")
	end
	
	function RobotDriver.autobuildTest_3oneLine()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()

		request:put(0,0,0, {slot=1})
		request:put(-1,0,0, {slot=1})
		request:put(-2,0,0, {slot=1})

		fb:autoBuild(request, currentCoordFb)
		ass.same(robot.coord:getCoords(), vector.new(-2,-1,0))
		ass.same(robot.world:get(0,0,0), "A")
		ass.same(robot.world:get(-1,0,0), "A")
		ass.same(robot.world:get(-2,0,0), "A")
	end

	function RobotDriver.autobuildTest_4square()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()

		request:put(0,0,0, {slot=1})
		request:put(-3,0,0, {slot=1})
		request:put(-2,0,2, {slot=1})
		request:put(0,0,1, {slot=1})

		fb:autoBuild(request, currentCoordFb)
		robot.world:printShape()
		
		ass.same(robot.world:get(0,0,0), "A")
		ass.same(robot.world:get(-3,0,0), "A")
		ass.same(robot.world:get(-2,0,2), "A")
		ass.same(robot.world:get(0,0,1), "A")
	end
	
	function RobotDriver.autobuildTest_5multiY()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()

		request:put(0,1,0, {slot=1, name="A"})
		request:put(-3,3,0, {slot=1, name="A"}) -- by this we test empty layer handling (layer 2)
		request:put(-2,0,2, {slot=1, name="A"})
		request:put(0,0,1, {slot=1, name="A"})

		fb:autoBuild(request, currentCoordFb)
		robot.world:printShape()

		ass.same(robot.world:get(-3,3,0), "A")
		ass.same(robot.world:get(0,1,0), "A")
		ass.same(robot.world:get(-2,0,2), "A")
		ass.same(robot.world:get(0,0,1), "A")
	end
  
  function RobotDriver.autobuildTest_6harvest_singleSquare()
		local fb, request, currentCoordFb = RobotDriver.helper_autobuildTest_setup()
    robot.slotContents[1] = {}

    local plant = Blocks.Plant:new(nil, "wheat", {"seeds"}, true, {"harvested wheat"})
		robot.world:put(1,0,1, plant)
    robot.world:put(1,0,2, plant)
    robot.world:put(1,0,3, plant)
    robot.world:put(2,0,3, plant)
    robot.world:put(1,-1,1, "dirt")
    
    request:put(1,0,1, "P")
    request:put(1,0,2, "P")
    request:put(1,0,3, "P")
    request:put(2,0,3, "P")
    

		fb:autoHarvest(request, currentCoordFb)
		robot.world:printShape()

    --ass.message("robot above plant").same(vector.new(1,1,1), robot.coord.coords)
		ass.message("robot harvested expected plants").same(4, plant.rightClickCount)
	end

  testTools.TestRunner(RobotDriver, "autobuildTest_", function() robot.resetrobot() end)

	RobotDriver._resupply = oldResupply
	
	print("unitTest_autobuild ok")
end

function RobotDriver.unitTest()
  RobotDriver.unitTest_automove()
  RobotDriver.unitTest_autobuild()
end

--RobotDriver.unitTest()

return RobotDriver
