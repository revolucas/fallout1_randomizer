---------------------------------------------------------------
-- Create a custom package loader
-- We want to load modules using our virtual file system
-- TODO: Need a DLL loader for modules so that plugins don't have to put dlls in main bin
---------------------------------------------------------------
local function custom_loader(fname)
	local errmsg = ""
	fname = fname:gsub("%.","/")
	for s in ("lua/lib/?.lua;lua/?.lua;lua/lib/?/init.lua;"):gmatch("([^;]+)") do
		local fullpath = s:gsub("%?",fname)
		if (filesystem.exists(fullpath) and not filesystem.isDirectory(fullpath)) then
			local chunk,err = filesystem.loadfile(fullpath)
			if (chunk ~= nil) then
				setfenv(chunk,getfenv(3)) -- getfenv(3) This should be env of the script that uses 'require'
				return chunk
			elseif (err) then
				return debug.traceback(1).."\n".."ERROR: "..err
			end
		else
			errmsg = errmsg.."\n\tno file '"..fullpath.."' (checked with custom package loader)"
		end
	end
	return errmsg
end

-- Install the loader so that it's called just before the normal Lua loader
table.insert(package.loaders, 2, custom_loader)

local callbacks = {}
function CallbackRemoveAll(name)
	if (name) then
		callbacks[name] = nil
	else
		callbacks = nil
	end
end

function CallbackSet(name,func_or_userdata,prior)
	if not (callbacks) then
		return -- intentionally removed all callbacks
	end
	if (func_or_userdata == nil) then 
		print("Attempt to set nil callback for " .. name)
	end
	if not (callbacks[name]) then
		callbacks[name] = {}
	end
	callbacks[name][func_or_userdata] = prior or 0
end

function CallbackUnset(name,func_or_userdata)
	if (callbacks and callbacks[name]) then
		callbacks[name][func_or_userdata] = nil
	end
end

local function order(t,a,b)
	return t[a] > t[b]
end
function CallbackSend(name,...)
	if (callbacks and callbacks[name]) then
		for func_or_userdata,v in spairs(callbacks[name],order) do
			if (type(func_or_userdata) == "function") then 
				func_or_userdata(...)
			elseif (func_or_userdata[name]) then
				func_or_userdata[name](func_or_userdata,...)
			end
		end
	end
end

function SetGC(o,functor)
	local __newproxy = newproxy(true)
	local metatable = getmetatable(__newproxy)
	metatable.__gc = functor
	o.__newproxy = __newproxy
end

function string.gsplit(s, sep, plain)
	local start = 1
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true return s end
		return pass(s:find(sep, start, plain))
	end
end

function print_table(node,format_only)
	local cache, stack, output = {},{},{}
	local depth = 1
	local output_str = "{\n"

	while true do
		local size = 0
		for k,v in pairs(node) do
			size = size + 1
		end

		local cur_index = 1
		for k,v in pairs(node) do
			if (cache[node] == nil) or (cur_index >= cache[node]) then
				
				if (string.find(output_str,"}",output_str:len())) then
					output_str = output_str .. ",\n"
				elseif not (string.find(output_str,"\n",output_str:len())) then
					output_str = output_str .. "\n"
				end

				-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
				table.insert(output,output_str)
				output_str = ""
				
				local key
				if (type(k) == "number" or type(k) == "boolean") then
					key = "["..tostring(k).."]"
				else
					key = "['"..tostring(k).."']"
				end

				if (type(v) == "number" or type(v) == "boolean") then
					output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
				elseif (type(v) == "table") then
					output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
					table.insert(stack,node)
					table.insert(stack,v)
					cache[node] = cur_index+1
					break
				else
					output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
				end

				if (cur_index == size) then
					output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
				else
					output_str = output_str .. ","
				end
			else
				-- close the table
				if (cur_index == size) then
					output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
				end
			end

			cur_index = cur_index + 1
		end

		if (size == 0) then
			output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
		end
			
		if (#stack > 0) then
			node = stack[#stack]
			stack[#stack] = nil
			depth = cache[node] == nil and depth + 1 or depth - 1
		else
			break
		end
	end

	-- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
	table.insert(output,output_str)
	output_str = table.concat(output)
	
	if not (format_only) then
		print(output_str)
	end 
	return output_str
end

function strformat(s,...)
	s = tostring(s)
	if (select('#',...) >= 1) then
		local i = 0
		local p = {...}
		local function sr(a)
			i = i + 1
			if (type(p[i]) == 'userdata') then
				return 'userdata'
			elseif (type(p[i]) == 'cdata') then 
				return 'cdata'
			end
			return tostring(p[i])
		end
		s = string.gsub(s,"%%s",sr)
	end
	return s
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function printf(s,...)
	print(strformat(s,...))
end

function printe(s,...)
	if (gDebug) then 
		error(strformat(s,...))
	else 
		print(strformat(s,...))
	end
end

function math.clamp(val, min, max)
	return val < min and min or val > max and max or val
end

function math.clamp_angle(angle,min,max)
	if (angle < -360) then 
		angle = angle + 360
	end 
	if (angle > 360) then 
		angle = angle - 360
	end 
	return math.clamp(angle,min,max)
end

function table.isempty(self)
	for k,v in pairs(self) do
		return false
	end
	return true
end

function namespace_from_string(str)
	local node = _G
	--for s in str:gsplit(".",true) do
	for s in str:gmatch("([^%.]+)") do
		if not (node[s]) then 
			return
		end
		node = node[s]
	end
	return node
end

-- Because 'require' still loads into _G namespace when using setfenv
-- Another issue with require is with lua lanes, require still loads into main thread's luaState
function invoke(fname,env)
	fname = fname:gsub("%.","/")
	for s in ("lua/lib/?.lua;lua/?.lua;lua/lib/?/init.lua;"):gmatch("([^;]+)") do
		local fullpath = s:gsub("?",fname)
		if (filesystem.exists(fullpath) and not filesystem.isDirectory(fullpath)) then
			local chunk,err = filesystem.loadfile(fullpath)
			if (chunk ~= nil) then
				setfenv(chunk,env or getfenv(2))
				return chunk()
			elseif (err) then
				print(debug.traceback(1).."\n".."ERROR: "..err)
			end
			return
		end
	end
	print("invoke: Unable to find "..fname)
end