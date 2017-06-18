local serpent = require("serpent")
local log = require("log")

local AutoLogger = {}
log.outfile = "log.txt"
log.usecolor = false

function AutoLogger:new(params)
    local o = o or {}
    params = params or {}
    setmetatable(o, self)
    self.__index = self
    
    o.log = {}
    o.addLog = params.addLog or function(message) 
      table.insert(o.log, message) 
      log.trace(message)
    end
    o.before = params.before or function(functionName, allParams) 
      local message = "call to: " .. (functionName or "") .. ": " .. serpent.line(allParams, {comment=false})
      o.addLog(message)
    end
    
    return o
end

function AutoLogger:wrapFunction(functionName, f)
  local before = self.before
  return function(...)
    before(functionName, {...})
    return f(table.unpack({...}))
  end
end

function AutoLogger:wrapObject(o)
  local newO = {}
  
  local _o = o
  
  local mt = {
    __index = function (t,k)
      --print("*access to element " .. tostring(k))
      local value = _o[k]
      if type(value) == "function" then
        value = self:wrapFunction(k, value)
      end
      return value   -- access the original table
    end,

    __newindex = function (t,k,v)
      --print("*update of element " .. tostring(k) .. " to " .. tostring(v))
      _o[k] = v   -- update original table
    end
  }
  setmetatable(newO, mt)
  
  
  return newO
end


function AutoLogger.unitTest()
  local origPath = package.path
  package.path="./?/init.lua;" .. package.path
	package.path="./testlibs/?.lua;" .. package.path
  
	local testTools = require("MyAsserts")
	local ass = require("luassert")
  local Blocks = require("Blocks")
  
  package.path = origPath
  local VLibs = require("VLibs")
  
  local test= {
    test1WrapFunction = function()
      local log = AutoLogger:new()
      local fn = function(param1, param2)
        return param2
      end
      
      local fnWrapped = log:wrapFunction("fn", fn)
      ass.message("direct call returns the same value as logged call").same(fn(1,2), fnWrapped(1,2))
      ass.message("call was logged").same("call to: fn: {1, 2}", log.log[1])
    end,
    
    test2WrapObject = function()
      local log = AutoLogger:new()
      local o = {
        value = 5,
        tab = {3},
        fn1 = function(param1) return param1 + 1 end,
        fn2 = function(self, param1) return "xxx" end
      }
      
      o = log:wrapObject(o)
      ass.message("call returns correct value").equals(6, o.fn1(5))
      ass.message("function calls are logged").equals("call to: fn1: {5}", log.log[1])
      ass.message("call returns correct value").equals("xxx", o:fn2(8))
      ass.message("function calls are logged").True(string.starts(log.log[2],"call to: fn2: "))
      ass.message("value parameters are unchanged").same({5, {3}}, {o.value, o.tab})
    end,
    
    test3WrapClassObject = function()
      local log = AutoLogger:new()
      local A = {
        new = function(self, o)
          o = o or {}
          setmetatable(o, self)
          self.__index = self
          
          o.callCount = 0
          return o
        end,
        
        fn = function(self, param1)
          self.callCount = self.callCount + 1
          return self.callCount
        end
      }
      local plant = A:new()
      
      plant = log:wrapObject(plant)
      plant:fn(5)
      ass.message("function executed").equals(1, plant.callCount)
      ass.message("function calls are logged").equals("call to: fn: {{}, 5}", log.log[1])
    end    
  }
  
  
  testTools.TestRunner(test,"test")
end

--AutoLogger.unitTest()

return AutoLogger
