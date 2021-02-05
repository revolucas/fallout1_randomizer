-- import.ini(filename)
getmetatable(this).__call = function(self,filename)
	return cINI(filename)
end

Class "cINI"
function cINI:__init(filename)
	self.sections = setmetatable({},{})
	local buffer, length = filesystem.read(filename)
	if (length == nil or length == 0) then
		print("parse ini - Invalid path: "..filename)
		return
	end
	local data = ""
	for path in string.gmatch(buffer,[[#include%s*"([&%w_%-.%s\"'=:]*)"]]) do 
		local buffer2, length2 = filesystem.read(path)
		if (length2 == nil or length2 == 0) then
			print("parse ini - Invalid path for #include: "..path)
		else
			data = data .. "\n" .. buffer2
		end
	end
		
	data = data .. "\n" .. buffer
	
	for section,body in string.gmatch(data,"%[%s*(.-)%s*%]([^%[%]]*)") do
		if not (self.sections[ section ]) then
			self.sections[ section ] = setmetatable({},{})
		end
		
		for ln in string.gmatch(body,"%s*([^\n\r]+)%s*") do
			if (ln:find(":") == 1) then
				for parent in string.gmatch(ln:sub(2),"%s*([^,]+)%s*") do
					if not (self.inherit) then
						self.inherit = {}
					end
					table.insert(self.inherit,parent)
				end
			elseif (ln ~= "") then
				local comment, value
				local start = ln:find(";")
				if (start) then
					comment = ln:sub(start)
					ln = ln:sub(1,start+1)
				end
				start = ln:find("=")
				if (start) then
					value = ln:sub(start+1):gsub("^%s*(.-)%s*$", "%1")
					ln = ln:sub(1,start-1):gsub("^%s*(.-)%s*$", "%1")
				end
				self.sections[ section ][ ln ] = {value,comment}
			end
		end
		
		if (self.inherit) then
			getmetatable(self.sections[ section ]).__index=function(tbl,key)
				for i=#self.inherit,1 do
					local t = self.sections[ self.inherit[ i ] ]
					if (t and t[ key ]) then
						local ret = t[ key ][ 1 ]
						if (ret ~= nil) then
							return ret
						end
					end
				end
			end
		end
	end
	return self
end

function cINI:r_string(sec,key,def)
	local v = self.sections[ sec ] and self.sections[ sec ][ key ] and self.sections[ sec ][ key ][ 1 ]
	if (v == nil) then 
		return def 
	end
	return v
end

function cINI:r_bool(sec,key,def)
	local v = self.sections[ sec ] and self.sections[ sec ][ key ] and self.sections[ sec ][ key ][ 1 ]
	if (v == nil) then 
		return def 
	end
	return v == "true" or v == "1" or v == "on"
end

function cINI:r_number(sec,key,def)
	local v = self.sections[ sec ] and self.sections[ sec ][ key ] and self.sections[ sec ][ key ][ 1 ]
	if (v == nil) then 
		return def 
	end
	return tonumber(v) or def
end

function cINI:write(sec,key,val)
	if not (self.sections[ sec ]) then 
		self.sections[ sec ] = {}
	end
	if not (self.sections[ sec ][ key ]) then
		self.sections[ sec ][ key ] = {}
	end
	self.sections[ sec ][ key ][ 1 ] = val and tostring(val)
end

function cINI:exist(sec,key)
	return self.sections[ sec ] ~= nil and (key and self.sections[ sec ][ key ] ~= nil or true) or false
end

function cINI:clear(sec,key)
	if (self.sections[ sec ]) then
		self.sections[ sec ][ key ] = nil 
	end
end

function cINI:sectionForEach(functor)
	for sec,t in pairs(self.sections) do
		functor(self,sec)
	end
end

function cINI:keyForEach(sec,functor)
	if (self.sections[sec]) then
		for key,t in pairs(self.sections[ sec ]) do
			functor(self,sec,key,t[ 1 ],t[ 2 ])
		end	
	end
end

function cINI:save(save_as_path)
	local function addTab(s,n)
		local l = string.len(s)
		for i=1,n-l do
			s = s .. " "
		end
		return s
	end
	
	local output = {}
	for section,kv in spairs(self.sections) do
		if (self.inherit) then
			table.insert(output,strformat("[%s]:%s",section,table.concat(self.inherit,",")))
		else
			table.insert(output,strformat("[%s]",section))
		end
		for key,t in spairs(kv) do
			local str = ""
			local value = t[ 1 ]
			if (value == nil or value == "") then
				str = key
			else
				str = strformat("%s%s= %s\n",key,addTab(key,40),value)
			end
			if (t[ 2 ]) then
				str = str .. " ; " .. t[ 2 ]
			end
			table.insert(output,str)
		end
	end
	
	filesystem.write(save_as_path,table.concat(output,"\n"))
end