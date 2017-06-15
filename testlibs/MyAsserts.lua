local MyAsserts = {} 

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

local function IsIngame()
  local res, keyboard = pcall(function() return require("keyboard") end)
  local ingame
  if type(keyboard) == 'table' then
    ingame = true
  else
    ingame = false
  end
  
  return ingame
end

local function TestRunner(objectWithTests, prefix, beforeTestFunc)
  local functionNameArray = {}
  
	for name, func in pairs(objectWithTests) do
		if string.starts(name, prefix) then
			table.insert(functionNameArray, name)
		end
	end
	
	table.sort(functionNameArray)
	
 	for _, name in pairs(functionNameArray) do
 		local func = objectWithTests[name]
    if beforeTestFunc ~= nil then
      beforeTestFunc()
    end
		print("Running "..name)
		func()
 	end
end

MyAsserts.TestRunner = TestRunner
MyAsserts.IsIngame = IsIngame

return MyAsserts


