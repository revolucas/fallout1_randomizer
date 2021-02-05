local function Class(name)
	local self = {}
	local caller = getfenv(2)
	caller[ name ] = self
	setmetatable(self,{
		__call = function(t,...)
			local o = {}
			local mt = {}
			setmetatable(o,mt)
			
			o.__class = name
			
			mt.__index = self
			mt.__tostring = o.__tostring
			mt.__unm  = o.__unm
			mt.__add  = o.__add
			mt.__sub  = o.__sub
			mt.__mul  = o.__mul
			mt.__div  = o.__div
			mt.__mod  = o.__mod
			mt.__pow  = o.__pow
			mt.__concat = o.__concat
			mt.__eq   = o.__eq
			mt.__lt   = o.__lt
			mt.__le   = o.__le
			
			if (o.__gc) then 
				local __newproxy = newproxy(true)
				local metatable = getmetatable(__newproxy)
				metatable.__gc = function()
					o:__gc()
				end
				o.__newproxy = __newproxy
			end
			
			o:__init(...)
			
			return o
		end
	})
	return function(...)
		local p = {...}
		self.inherited = p
		getmetatable(self).__index=function(t,k)
			for i,v in ipairs(self.inherited) do
				local ret = rawget(v,k)
				if (ret ~= nil) then
					return ret
				end
			end
		end
	end
end

return Class