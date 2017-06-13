function vectorEquals(a, b)
	assert(a ~= nil, "Nil values not allowed: a")
	assert(b ~= nil, "Nil values not allowed: b")
	return (a-b):length() == 0
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function test()
	print("Item: "..ITEM.EMPTY.slot)
end