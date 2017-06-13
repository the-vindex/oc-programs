local vec = require("libvec")

local OcEnums = {
	axis = {
		zNorthSouth = {name = "zNorthSouth", coordinateFilter = vec.new(0,0,1)},
		xEastWest = {name = "xEastWest", coordinateFilter = vec.new(1,0,0)},
		yUpDown = {name = "yUpDown", coordinateFilter = vec.new(0,1,0)},
	}
}
return OcEnums
