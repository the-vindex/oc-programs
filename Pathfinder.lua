local vector = require("libvec")
local ShapeInfo = require("ShapeInfo")
local CoordTracker = require("CoordTracker")

local Pathfinder = {}

function Pathfinder.calculatePath(coord, shape, y)
	local v = Pathfinder.v
	local minV, maxV = shape:getBorderCubeCoords(y)
	
	-- 
	if minV == nil then
		return {}, "Layer is empty"
	end
	
	local path = {}
	function addPath(point)
		table.insert(path,point)
	end

	--expects vectors
	local function addUniquePoint(array, newValue)
		for _, value in ipairs(array) do
			if vectorEquals(value, newValue) then
				return
			end
		end
		table.insert(array,newValue)
	end

	local function findClosestPoint(myPoint, pointArray)
		local minIndex, minDist = nil, 10000000

		for i, point in ipairs(pointArray) do
			if (point ~= nil ) then
				local currentDist = (myPoint - point):length()
				if  currentDist < minDist then
					minIndex, minDist = i, currentDist
				end
			end
		end
		return minIndex, pointArray[minIndex]
	end

	function math.sign(value)
		if value == 0 then
			return 0
		else
			return value/math.abs(value)
		end
	end

	local function arrayContainsVector(array, vect)
		for _, value in ipairs(array) do
			if vectorEquals(vect,value) then
				return true
			end
		end
		return false
	end
	--v(maxV.x,minV.y,maxV.z), v(maxV.y,minV.x,maxV.z), v(minV.x,minV.y,maxV.z)

	local function calculateOpositeCornerIndex(index)
		return ((index - 1 + 2) % 4) + 1 -- its modulo 4, but we start at 1... so it's more complex
	end

	local topCorners = {}

	--  2FFFF3
	--  FFFFFF
	--  FFFFFF
	--  1FFFF4
	topCorners[1]=v(minV.x,maxV.y,minV.z)
	topCorners[2]=v(minV.x,maxV.y,maxV.z)
	topCorners[3]=v(maxV.x,maxV.y,maxV.z)
	topCorners[4]=v(maxV.x,maxV.y,minV.z)

	local rangeX = math.abs(maxV.x - minV.x)
	local rangeZ = math.abs(maxV.z - minV.z)

	local startingPointIndex, startingPoint = findClosestPoint(coord:getCoords(), topCorners)
	addPath(startingPoint)

	local targetPointIndex = calculateOpositeCornerIndex(startingPointIndex)
	local targetPoint = topCorners[targetPointIndex]
	local direction = targetPoint - startingPoint
	local stepX = v(1,0,0) * math.sign(direction.x)
	local stepZ = v(0,0,1) * math.sign(direction.z)

	local stepOuter, stepInner, rangeOuter

	if rangeX>rangeZ then
		stepOuter, stepInner, rangeOuter = stepZ, stepX * rangeX, rangeZ
	else
		stepOuter, stepInner, rangeOuter = stepX, stepZ * rangeZ, rangeX
	end

	local current = startingPoint

	local innerReverse = 1

	if (rangeOuter % 2 == 1) then
		local nextPointIndex, _ = findClosestPoint(current + stepInner * innerReverse, topCorners)
		targetPoint = topCorners[calculateOpositeCornerIndex(nextPointIndex)]
	end

	while not(vectorEquals(current,targetPoint)) do
		current = current + stepInner * innerReverse
		addUniquePoint(path,current)

		if not(vectorEquals(current,targetPoint)) then
			current = current + stepOuter
			addUniquePoint(path,current)
		end
		innerReverse = innerReverse * -1
	end

	return path
end

function Pathfinder.v(x,y,z)
   return vector.new(x,y,z)
end

function Pathfinder.unitTests()
	local ass = require("luassert")
	require("MyAsserts")
	
	local v = Pathfinder.v
	local calculatePath = Pathfinder.calculatePath

	local function testGoToCoordinate()
		local c = CoordTracker:new(2,2,2, CoordTracker.DIR.Z_PLUS)
		local s = ShapeInfo:new()
		s:put(0,0,0,"T")

		local path = calculatePath(c, s, 0)

		local expected = {v(0,0,0)}

		ass.same(path, expected)
		print("testGoToCoordinate ok")
	end

	local function testDoOneLine()
		local s = ShapeInfo:new()
		s:put(0,0,0,"T")
		s:put(5,0,0,"T")

		local path = calculatePath(CoordTracker:new(2,2,2, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(0,0,0), v(5,0,0)}
		ass.same(path, expected)

		local path = calculatePath(CoordTracker:new(4,4,2, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(5,0,0),v(0,0,0)}
		ass.same(path, expected)
		
		print("testDoOneLine ok")
	end

	local function testSmallSquare()
		local s = ShapeInfo:new()
		s:fillYLayer(0,1,0,1,0,"F")
		s:printShape()

		-- if no direction is better, we prefer to move along Y axis
		local path = calculatePath(CoordTracker:new(-1,-1,0, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(0,0,0), v(0,0,1), v(1,0,1), v(1,0,0)}
		ass.same(expected,path)
		
		print("testSmallSquare ok")
	end

	local function testSmallRectangle()
		local s = ShapeInfo:new()
		s:fillYLayer(0,5,0,1,0,"F")
		s:printShape()

		-- if no direction is better, we prefer to move along Y axis
		local path = calculatePath(CoordTracker:new(-1,-1,0, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(0,0,0), v(5,0,0), v(5,0,1), v(0,0,1)}
		ass.same(path, expected)
		
		print("testSmallRectangle ok")
	end


	local function testRectangle()
		local s = ShapeInfo:new()
		s:fillYLayer(0,5,0,2,0,"F")
		s:printShape()

		-- if no direction is better, we prefer to move along Y axis
		local path = calculatePath(CoordTracker:new(-1,-1,0, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(0,0,0), v(5,0,0), v(5,0,1), v(0,0,1), v(0,0,2), v(5,0,2)}
		ass.same(path, expected)
		
		print("testRectangle ok")
	end
	
	local function testOptimizeLineMovement()
		local s = ShapeInfo:new()
		s:fillYLayer(0,5,0,0,0,"F")
		s:fillYLayer(2,3,1,1,0,"F")
		s:fillYLayer(0,5,2,2,0,"F")
		s:printShape()

		-- if no direction is better, we prefer to move along Y axis
		local path = calculatePath(CoordTracker:new(-1,-1,0, CoordTracker.DIR.Z_PLUS), s, 0)
		local expected = {v(0,0,0), v(5,0,0), v(5,0,1), v(0,0,1), v(0,0,2), v(5,0,2)}
		ass.same(path, expected)
		
		print("testOptimizeLineMovement ok")
	end

	testGoToCoordinate()
	testDoOneLine()
	testSmallSquare()
	testSmallRectangle()
	testRectangle()
	testOptimizeLineMovement()
end

return Pathfinder
