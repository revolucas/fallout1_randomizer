-------------------------------------------------------------
--[[	Setup the environment
Here we compose a new lua environment for *.lua found in the 'auto' directory. Each directory and script becomes it's own table. This means, when a variable 
value doesn't exist, it checks namespace_bindings; it will try to auto load a *.lua. This is so individual scripts can reference eachother 
without load order issues, simply by autoloading them. It also eliminates the hassle of using module or require.
Examples:
lua/auto/core/import/xml.lua will be executed within the _G.core.import environment and can be accessed as this table.
lua/auto/core/renderer/shaders can be accessed at core.renderer.shaders
--]]
-------------------------------------------------------------
do
	local function gsplit(s, sep, plain)
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

	local namespace_bindings = {}

	-- Iterate all *.lua in lua/auto directory
	local function on_execute(path,fname,fullpath)
		local sname = fname:sub(1,-5)
		local t = {}
		local parent_namespace = "_G"
		for s in gsplit(path:sub(10),"/",true) do
			if (s ~= "") then
				table.insert(t,s)
				if not (namespace_bindings[ s ]) then
					namespace_bindings[ s ] = {}
				end
				if not (namespace_bindings[ s ][ parent_namespace ]) then
					namespace_bindings[ s ][ parent_namespace ] = {}
				end
				if (sname ~= s) then -- if script name same as directory, then keep current parent ie. core/framework/framework.lua should be core.framework
					parent_namespace = parent_namespace .. "." .. s
				end
			end
		end
		if not (namespace_bindings[ sname ]) then
			namespace_bindings[ sname ] = {}
		end
		if not (namespace_bindings[ sname ][ parent_namespace ]) then
			namespace_bindings[ sname ][ parent_namespace ] = {}
		end
		namespace_bindings[ sname ][ parent_namespace ][ 1 ] = t
		namespace_bindings[ sname ][ parent_namespace ][ 2 ] = fullpath
	end
	filesystem.fileForEach("lua/auto",true,{"lua"},on_execute)

	-- create the metatable structure for all scripts in auto/
	_G.__namespace__ = "_G"
	setmetatable(_G,{__index=function(t,k)
		if (k == "this") then 
			return t
		elseif (k == "Class") then
			setfenv(Class,t) -- So that this[name] in Class isn't always _G, but calling table
		end
		
		-- if variable name indexing this table exists in the binding table along with this tables namespace, then it has a script to load
		local root = namespace_bindings[ k ] and namespace_bindings[ k ][ t.__namespace__ ]
		if (root) then
			namespace_bindings[ k ][ t.__namespace__ ] = nil
			if not (root[1]) then
				local env = {}
				env.__namespace__ = t.__namespace__ .. "." .. k
				env.__holder__ = t
				local mt = {}
				local p_mt = getmetatable(t)
				-- copy metatable from parent
				for k, v in next, p_mt, nil do
					mt[k] = v
				end
				setmetatable(env,mt)
				
				rawset(t,k,env)
				return env
			else
				local node = _G
				for i,namespace in ipairs(root[ 1 ]) do 
					if (node[ namespace ]) then 
						node = node[ namespace ]
					end
				end
				if (node == _G or node == t) then
					local chunk,errormsg = filesystem.loadfile(root[ 2 ])
					if (chunk ~= nil) then
						local env = {}
						env.__namespace__ = t.__namespace__ .. "." .. k
						env.__holder__ = t
						local mt = {}
						local p_mt = getmetatable(t)
						-- copy metatable from parent
						for k, v in next, p_mt, nil do
							mt[k] = v
						end
						setmetatable(env,mt)
						
						setfenv(chunk,env)
						local status,err = pcall(chunk)
						if (status) then
							print("loaded script: " .. root[ 2 ])
						else
							print(err,debug.traceback(1))
						end
						
						rawset(t,k,env)
						return env
					else
						print(errormsg,debug.traceback(1))
					end
				end
			end
		end
		
		return rawget(_G,k)
	end})
end