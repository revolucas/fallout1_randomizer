local expat = require("ffi_expat")	; if not (expat) then error("failed to load expat") end

-- import.xml(filename)
getmetatable(this).__call = function(self,filename,attribute_callback,start_element_callback,end_element_callback)
	if (filesystem.exists(filename)) then
		return cXML(filename,attribute_callback,start_element_callback,end_element_callback)
	end
	print("import.xml file doesn't exist!",filename)
end

Class "cXML"
function cXML:__init(filename,attribute_callback,start_element_callback,end_element_callback)
	local buffer, length = filesystem.read(filename)
	local data = expat.luaparse(buffer,length,attribute_callback,start_element_callback,end_element_callback)
	self.data = data.xml[ 1 ] -- shortcut since all xml files for this engine will only have a single <xml> tag
end

--TODO: Implement save
function cXML:save(filename)

end