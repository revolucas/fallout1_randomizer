local ffi = require("ffi")

local physfs = (physfs or require("ffi_physfs")) ; if not (physfs) then error("failed to load phsyicsfs") end
local ipairs,table,loadstring,assert,print,os,string = ipairs,table,loadstring,assert,print,os,string

module("filesystem")

function exists(filename)
	return physfs.PHYSFS_exists(filename) ~= 0
end

function directoryForEach(dir,recursive,cb_func,...)
	local stack,size = {},0
	while true do
		if (dir) then
			local files = getDirectoryItems(dir)
			for i,fname in ipairs(files) do
				local fullpath = dir.."/"..fname
				if (isDirectory(fullpath)) then
					cb_func(dir,fname,fullpath,...)
					if (recursive) then
						if not (exists(fullpath.."/.ignore")) then
							size = size + 1 
							stack[size] = fullpath
						end
					end
				end
			end
		end

		if (size == 0) then 
			break
		end
		
		dir = stack[size]
		stack[size] = nil
		size = size - 1
	end
end

function fileForEach(dir,recursive,exts,cb_func,...)
	local stack,size = {},0
	while true do
		if (dir) then
			local files = getDirectoryItems(dir)
			for i,fname in ipairs(files) do
				local fullpath = dir.."/"..fname
				if (isDirectory(fullpath)) then
					if (recursive) then
						if not (exists(fullpath.."/.ignore")) then
							size = size + 1 
							stack[size] = fullpath
						end
					end
				else 
					if (exts) then
						for ii,ext in ipairs(exts) do
							if (fname:gsub("(.*)%.","") == ext) then 
								cb_func(dir,fname,fullpath,...)
							end
						end
					else
						cb_func(dir,fname,fullpath,...)
					end
				end
			end
		end

		if (size == 0) then 
			break
		end
		
		dir = stack[size]
		stack[size] = nil
		size = size - 1
	end
end 

function getLastModified(filename)
	return physfs.PHYSFS_getLastModTime(filename)
end

function getAppdataDirectory()
	if (ffi.os == "Windows") then 
		return os.getenv('APPDATA'):gsub("\\","/") .. "/"
	elseif (ffi.os == "Linux") then 
		if not (os.getenv('XDG_DATA_HOME')) then
			return getUserDirectory() .. ".local/share/"
		end
		return getUserDirectory()
	elseif (ffi.os == "OSX") then
		return getUserDirectory() .. "Library/Application Support/"
	end
	return getUserDirectory()
end

function getUserDirectory()
	return ffi.string(physfs.PHYSFS_getUserDir()) .. "/"
end

function getBaseDirectory()
	-- remove 'bin' to get real base directory
	return ffi.string(physfs.PHYSFS_getBaseDir()):sub(1,-5)
end

function getWriteDirectory()
	return ffi.string(physfs.PHYSFS_getWriteDir()) .. "/"
end

function setWriteDirectory(path)
	if (physfs.PHYSFS_setWriteDir(path) == 0) then 
		print("filesystem.setWriteDirectory: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. path)
	end
end

function mkdir(path)
	if not (exists(path)) then 
		if (physfs.PHYSFS_mkdir(path) == 0) then 
			print("filesystem.mkdir: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. path)
		end
	end
end

function getDirectoryItems(dir)
	local rc = physfs.PHYSFS_enumerateFiles(dir)
	local i = 0
	local v = nil
	local t = {}
	repeat
		v = rc[i]
		if (v ~= nil) then
			table.insert(t, ffi.string(v))
		end
		i = i + 1
	until (v == nil)
	physfs.PHYSFS_freeList(rc)
	return t
end

function init(argv0,allow_symbolic_links)
	if (physfs.PHYSFS_init(argv0) == 0) then
		local err = physfs.PHYSFS_getLastErrorCode()
		if (err ~= physfs.PHYSFS_ERR_OK) then
			print("filesystem.lua: Error: Failed to init:", ffi.string(physfs.PHYSFS_getErrorByCode(err)))
		else 
			print("filesystem.lua: Error: unable to init due to unknown reason")
		end
		return false
	end

	physfs.PHYSFS_permitSymbolicLinks(allow_symbolic_links)

	return true
end

function deinit()
	physfs.PHYSFS_deinit()
end

function isDirectory(filename)
	return physfs.PHYSFS_isDirectory(filename) ~= 0
end

function isFile(file)
	return exists(file) and not isDirectory(file)
end

function loadfile(path)
	if (isFile(path)) then
		local str = read(path)
		return assert(loadstring(str,path:sub(-45)))
	end
end

function mount(newDir,mountPoint,appendToPath)
	return physfs.PHYSFS_mount(newDir,mountPoint,appendToPath and 1 or 0) ~= 0
end

function read(filename)
	local file = physfs.PHYSFS_openRead(filename)
	if (file ~= nil) then
		local length = physfs.PHYSFS_fileLength(file)
		local buffer = ffi.new("char[?]",length)
		physfs.PHYSFS_read(file,buffer,1,length)
		physfs.PHYSFS_close(file)
		return ffi.string(buffer,length), length
	else 
		print("filesystem.read: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. filename)
	end
end

function write(filename,data)
	local file = physfs.PHYSFS_openWrite(filename)
	if (file ~= nil) then
		local bytes = string.len(data)
		physfs.PHYSFS_write(file, data, 1, bytes)
		physfs.PHYSFS_close(file)
		return true
	else 
		print("filesystem.write: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. filename)
	end
	return false
end

function getLastError()
	return ffi.string(physfs.PHYSFS_getLastError())
end