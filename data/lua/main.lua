-------------------------------------------------------------
-- Copyright 2019
-------------------------------------------------------------

-------------------------------------------------------------
-- Initialize FFI as global
-------------------------------------------------------------
ffi = require("ffi")

-------------------------------------------------------------
-- Restructure the CommandLine arguments
-------------------------------------------------------------
CommandLine = {}
for opt in string.gmatch(table.concat(arg," "),[[%s*"*([^-"]*)%s*"*]]) do
	local start = opt:find(" ")
	if (start) then
		CommandLine[ opt:sub(1,start-1) ] = opt:sub(start+1)
	else
		CommandLine[ opt ] = true
	end
end

if ( jit.os == "Windows" ) then
	-- Get working directory
	local workingdir = arg[ 1 ]
	
	-- fix path by adding a final slash
	if (workingdir:match("^.*()[\\/]") < workingdir:len()) then
		workingdir = workingdir .. "/"
	end
	
	CommandLine.workingDirectory = workingdir:gsub("\\","/")
	
	-- Set DLL directory (necessary for ffi.load)
	ffi.cdef[[
		int __stdcall SetDllDirectoryA(const char* lpPathName);
	]]

	ffi.C.SetDllDirectoryA(workingdir .. "bin")

	-- lib and include pathes
	package.path = "data/lua/lib/?.lua;data/lua/?.lua;data/lua/lib/?/init.lua;"
	
	package.cpath = workingdir .. "bin\\?.dll;"				.. package.cpath
	package.cpath = workingdir .. "bin\\loadall.dll;"		.. package.cpath
elseif (ffi.os == "Linux") then
	-- Get working directory
	local workingdir = arg[ 1 ]
	
	-- fix path by adding a final slash
	if (workingdir:match("^.*()[\\/]") < workingdir:len()) then
		workingdir = workingdir .. "/"
	end

	CommandLine.workingDirectory = workingdir:gsub("\\","/")

	-- Add Windows LUA_LDIR paths
	local ldir = "./?.lua;!lua/?.lua;!lua/?/init.lua;"
	package.path = package.path:gsub("^%./%?%.lua;",ldir)
	package.path = package.path:gsub("!",workingdir)

	-- lib and include pathes
	package.path = "data/lua/lib/?.lua;data/lua/?.lua;data/lua/lib/?/init.lua;"
	
	package.cpath = "bin/?.so;"			.. package.cpath
	package.cpath = "bin/loadall.so;"	.. package.cpath
end

-------------------------------------------------------------
-- Initialize the filesystem (PhysicsFS)
-------------------------------------------------------------
require("filesystem")
VFS_PATHS = {}

if not (filesystem.init("",true)) then
	print ("ERROR: filesystem.init",filesystem.getLastError())
	return
end

-------------------------------------------------------------
-- Mount directories to the virtual file system
-------------------------------------------------------------
do
	-- load virtual file system mounting points from xml (default is vfs.xml)
	local vfs_path = (CommandLine[ "vfs" ] or "vfs") .. ".xml" -- Can pass path through to command line. (ie. -vfs vfs_custom)
	local f = assert(io.open(vfs_path,"r")) 
    local data = f:read("*all")
    f:close()
	
	local expat = require("ffi_expat")
	local vfs = expat.luaparse(data,data:len())
	
	-- mount
	for i,node in ipairs(vfs.xml[1].module) do
		local t = { node[ 1 ].name, node[ 1 ].path, node[ 1 ].mount, node[ 1 ].relative == "true" }
		table.insert(VFS_PATHS,t)
		filesystem.mount(t[ 2 ],t[ 3 ] or "/",t[ 4 ])
	end
end

-------------------------------------------------------------
-- Load globals
-------------------------------------------------------------
require("environment")
require("lib")
require("global")

----------------------------------------------------------
-- Trigger application callbacks
----------------------------------------------------------
do
	local functor = nil
	local function iterator(path,fname,fullpath)
		-- Split paths and create tables for each directory
		local node = _G
		local namespace = "_G"
		local pp = path:sub(10) -- remove lua/auto/

		for s in pp:gmatch("([^/]+)") do
			if (s ~= "") then
				if (node[ s ]) then 
					node = node[ s ]
					namespace = s
				end
			end
		end
		
		local sname = fname:sub(1,-5)
		if (sname ~= namespace) then
			node = node[ sname ]
		end

		if (node and functor and node[ functor ]) then 
			node[ functor ]()
		end
	end
	-- touch all files so they are compiled
	filesystem.fileForEach("lua/auto",true,{"lua"},iterator)
	-- application_init callback
	functor = "application_init"
	filesystem.fileForEach("lua/auto",true,{"lua"},iterator)
	-- application_run callback
	functor = "application_run"
	filesystem.fileForEach("lua/auto",true,{"lua"},iterator)
	-- application_exit callback
	functor = "application_exit"
	filesystem.fileForEach("lua/auto",true,{"lua"},iterator)
end

print("application exited successfully...")