local VLibs = {}

function VLibs.filterTable_first(t,filter)
	for _, item in ipairs(t) do
		if filter(item) then
			return item
		end
	end
end

function VLibs.printTable(t)
	for k,v in pairs(t) do
		print(k, v)
	end
end

function VLibs.printObject(object)
	print(ser.serialize(object,true))
end

return VLibs
