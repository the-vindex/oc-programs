local vector = {}
local _vector = {
	add = function( self, o )
		return vector.new(
			self.x + o.x,
			self.y + o.y,
			self.z + o.z
		)
	end,
	sub = function( self, o )
		return vector.new(
			self.x - o.x,
			self.y - o.y,
			self.z - o.z
		)
	end,
	mul = function( self, m )
		return vector.new(
			self.x * m,
			self.y * m,
			self.z * m
		)
	end,
	mulVectors = function(self, o)
		return vector.new(
			self.x*o.x,
			self.y*o.y,
			self.z*o.z
		)
	end,
	dot = function( self, o )
		return self.x*o.x + self.y*o.y + self.z*o.z
	end,
	cross = function( self, o )
		return vector.new(
			self.y*o.z - self.z*o.y,
			self.z*o.x - self.x*o.z,
			self.x*o.y - self.y*o.x
		)
	end,
	length = function( self )
		return math.sqrt( self.x*self.x + self.y*self.y + self.z*self.z )
	end,
	normalize = function( self )
		return self:mul( 1 / self:length() )
	end,
	round = function( self, nTolerance )
	    nTolerance = nTolerance or 1.0
		return vector.new(
			math.floor( (self.x + (nTolerance * 0.5)) / nTolerance ) * nTolerance,
			math.floor( (self.y + (nTolerance * 0.5)) / nTolerance ) * nTolerance,
			math.floor( (self.z + (nTolerance * 0.5)) / nTolerance ) * nTolerance
		)
	end,
	equals = function (self, o)
		return not(o == nil) and self.x == o.x and self.y == o.y and self.z == o.z
	end,
	tostring = function( self )
		return self.x..","..self.y..","..self.z
	end,
	className = function( self)
		return "Vector"
	end,
}

local vmetatable = {
	__index = _vector,
	__add = _vector.add,
	__sub = _vector.sub,
	__mul = _vector.mul,
	__unm = function( v ) return v:mul(-1) end,
	__tostring = _vector.tostring,
}

function vector.new( x, y, z )
	local v = {
		x = x or 0,
		y = y or 0,
		z = z or 0
	}
	setmetatable( v, vmetatable )
	return v
end

function vector.isVector(o)
	return o ~= nil and o.className ~= nil and o:className() == _vector.className()
end

function vector.unitTest()
  local ass = require("luassert")
  local function v(x,y,z) return vector.new(x,y,z) end
  
  	-- test our additions to vectors
	ass.message("equals works").True(v(1,2,3):equals(v(1,2,3)))
	ass.message("not-equals works").False(v(1,2,3):equals(v(1,2,4)))
  print("libvec unit tests ok")
end

--vector.unitTest()

return vector
