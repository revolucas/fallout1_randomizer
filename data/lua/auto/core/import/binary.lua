-- TODO: Implement a dedicated thread pool to loading and processing binary data since it will be an important file type and iterating over files bytes at a time is demanding

-- import.binary(fname,seek,length,chunk,callback)
getmetatable(this).__call = function (self,fname,seek,length,chunk,callback)
	if (chunk) then
		if (chunk.data) then
			return cBinaryData(fname,seek,length,chunk)
		end	
	elseif (fname and filesystem.exists(fname) and not filesystem.isDirectory(fname)) then
		return cBinaryData(fname,seek,length,chunk)
	end
end

function new(data,size)
	local bin = cBinaryData()
	bin.data = data
	bin._size = size
	bin.loaded = true
	return bin
end

local ENDIAN = ffi.abi("le") and "le" or "be"
---------------------------------------------------------
-- BinaryData
---------------------------------------------------------
Class "cBinaryData"
function cBinaryData:__init(fname,seek,length,chunk)
	self.endian = "le"
	self.w_marker = 0
	self.r_marker = 0
	if (chunk) then -- copy data from another cBinaryData object
 		if (chunk.data) then
			seek = seek or 0
			length = length or chunk:size()
			self.data = ffi.new("unsigned char[?]",length)
			self._size = tonumber(length)
			ffi.copy(self.data,chunk.data+seek,length)
			self.loaded = true
		end
	elseif (fname) then
		self.fname = fname
		local file = filesystem.exists(fname) and not filesystem.isDirectory(fname) and physfs.PHYSFS_openRead(fname)
		if not (file) then
			print("cBinaryData:initialize: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. fname)
			return
		end
		seek = seek or 0
		length = length or physfs.PHYSFS_fileLength(file)
		physfs.PHYSFS_seek(file,seek)
		local buffer = ffi.new("unsigned char[?]",length)
		physfs.PHYSFS_readBytes(file,buffer,length)
		physfs.PHYSFS_close(file)
		self.data = buffer
		self._size = tonumber(length)
		self.loaded = true
	end
end

function cBinaryData:size()
	return self._size
end

function cBinaryData:w_tell()
	return self.w_marker
end 

function cBinaryData:r_tell()
	return self.r_marker
end 

function cBinaryData:r_advance(pos)
	self.r_marker = self.r_marker+pos
	math.clamp(self.r_marker,0,self._size)
end 

function cBinaryData:w_advance(pos)
	self.w_marker = self.w_marker+pos
	math.clamp(self.w_marker,0,self._size)
end

function cBinaryData:r_seek(pos)
	self.r_marker = pos
	math.clamp(self.r_marker,0,self._size)
end 

function cBinaryData:w_seek(pos)
	self.w_marker = pos
	math.clamp(self.w_marker,0,self._size)
end 

function cBinaryData:w_eof()
	return self.w_marker >= self._size
end 

function cBinaryData:r_eof()
	return self.r_marker >= self._size
end 

function cBinaryData:r_u8()
	local v = ffi.cast("uint8_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("uint8_t")
	return tonumber(v[0]) or 0
end 

function cBinaryData:w_u8(val)
	local v = ffi.cast("uint8_t *",self.data+self.w_marker)
	v[0] = tonumber(val) or 0
	self.w_marker = self.w_marker+ffi.sizeof("uint8_t")
end

function cBinaryData:r_s8()
	local v = ffi.cast("int8_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("int8_t")
	return tonumber(v[0]) or 0
end

function cBinaryData:w_s8(val)
	local v = ffi.cast("int8_t *",self.data+self.w_marker)
	v[0] = tonumber(val) or 0
	self.w_marker = self.w_marker+ffi.sizeof("int8_t")
end

function cBinaryData:r_u16()
	local v = ffi.cast("uint16_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("uint16_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("uint16_t")*8) )
	end
	return tonumber(v[0]) or 0
end 

function cBinaryData:w_u16(val)
	local v = ffi.cast("uint16_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("uint16_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("uint16_t")
end

function cBinaryData:r_s16()
	local v = ffi.cast("int16_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("int16_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("int16_t")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_s16(val)
	local v = ffi.cast("int16_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("int16_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("int16_t")
end

function cBinaryData:r_u32()
	local v = ffi.cast("uint32_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("uint32_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("uint32_t")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_u32(val)
	local v = ffi.cast("uint32_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("uint32_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("uint32_t")
end

function cBinaryData:r_s32()
	local v = ffi.cast("int32_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("int32_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("int32_t")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_s32(val)
	local v = ffi.cast("int32_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("int32_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("int32_t")
end

function cBinaryData:r_u64()
	local v = ffi.cast("uint64_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("uint64_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("uint64_t")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_u64(val)
	local v = ffi.cast("uint64_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("uint64_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("uint64_t")
end

function cBinaryData:r_s64()
	local v = ffi.cast("int64_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("int64_t")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("int64_t")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_s64(val)
	local v = ffi.cast("int64_t *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("int64_t")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("int64_t")
end

function cBinaryData:r_float()
	local v = ffi.cast("float *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("float")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("float")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_float(val)
	local v = ffi.cast("float *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("float")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("float")
end

function cBinaryData:r_double()
	local v = ffi.cast("double *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("double")
	if (self.endian ~= ENDIAN) then
		return tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("double")*8) )
	end
	return tonumber(v[0]) or 0
end

function cBinaryData:w_double(val)
	local v = ffi.cast("double *",self.data+self.w_marker)
	if (self.endian ~= ENDIAN) then
		v[0] = tonumber( bit.rshift(bit.bswap(val),ffi.sizeof("double")*8) )
	else
		v[0] = tonumber(val) or 0
	end
	self.w_marker = self.w_marker+ffi.sizeof("double")
end

function cBinaryData:r_float_q16(min,max)
	local v = ffi.cast("uint16_t *",self.data+self.r_marker)
	self.r_marker = self.r_marker+ffi.sizeof("uint16_t")
	local ret = tonumber(v[0]) or 0
	ret = (ret * (max - min)) / 65535 + min
	return ret
end

function cBinaryData:r_stringZ()
	local v = ffi.string(self.data+self.r_marker)
	self.r_marker = self.r_marker + v:len() + 1
	return v
end

function cBinaryData:w_stringZ(str)
	str = tostring(str) or ""
	ffi.copy(self.data+self.w_marker,str)
	self.w_marker = self.w_marker+ffi.sizeof("char")*(str:len()+1)
end

function cBinaryData:r_string(cnt)
	-- For S.T.A.L.K.E.R.
	-- local marker = self.r_marker
	-- while (self:r_eof() == false and self:r_tell()+1 < self:size()) do
		-- if (self:r_u8() == 13) then
			-- self:r_u8()
			-- break
		-- end
	-- end
	-- local v = ffi.string(self.data+marker,self.r_marker-marker)
	-- return v
	local v = ffi.string(self.data+self.r_marker,cnt)
	self.r_marker = self.r_marker + v:len()
	return v
end 

function cBinaryData:w_string(str)
	str = tostring(str) or ""
	ffi.copy(self.data+self.w_marker,str)
	self.w_marker = self.w_marker+ffi.sizeof("char")*str:len()
	-- For S.T.A.L.K.E.R.
	-- self:w_u8(13) -- CR
	-- self:w_u8(10) -- LF
end

function cBinaryData:r_block(sz)
	local newdata = ffi.new("unsigned char[?]",sz)
	ffi.copy(newdata,self.data+self.r_marker,sz)
	self.r_marker = self.r_marker+sz
	return newdata
end

function cBinaryData:find_chunk(ID)
	self.r_marker = 0
	while (self:r_eof() == false and self:r_tell()+8 < self:size()) do
		local typ,sz = self:r_u32(),self:r_u32()
		if (typ == ID) then
			return sz
		end
		self.r_marker = self.r_marker + sz
	end
	return 0
end

function cBinaryData:open_chunk(ID)
	self.r_marker = 0
	while (self:r_eof() == false and self:r_tell()+8 < self:size()) do
		local typ,sz = self:r_u32(),self:r_u32()
		if (typ == ID) then
			return cBinaryData(nil,self.r_marker,sz,self)
		end
		self.r_marker = self.r_marker + sz
	end
	return
end 

function cBinaryData:grow(size)
	assert(size > self:size())
	local newdata = ffi.new("unsigned char[?]",size)
	ffi.copy(newdata,self.data,self:size())
	self.data = newdata
	self._size = size
end 

function cBinaryData:shrink(size)
	assert(size < self:size())
	local newdata = ffi.new("unsigned char[?]",size)
	ffi.copy(newdata,self.data,size)
	self.data = newdata
	self._size = size
end 

function cBinaryData:replace_chunk(ID,chunk)
	self.r_marker = 1
	local size = self:size()
	local dwType,dwSize
	while true do
		dwType,dwSize = self:r_u32(),self:r_u32()
		if not (dwType and dwSize) then
			return
		end
		if (dwType == ID) then
			if (dwSize > 0) then
				local newsize = chunk:size()
				if (newsize ~= dwSize) then
					print("ID=%s newsize=%s dwSize=%s",ID,newsize,dwSize)
					self:w_seek(self.r_marker-4)
					self:w_u32(newsize)
				end
				local dif = self._size + newsize - dwSize
				local newdata = ffi.new("unsigned char[?]",dif)
				ffi.copy(newdata,self.data,self:r_tell())
				ffi.copy(newdata+self:r_tell()+1,chunk.data,chunk:size())
				ffi.copy(newdata+self:r_tell()+chunk:size()+1,self.data+self:r_tell()+dwSize)
				self.data = newdata
				self._size = dif
			end
			return
		end
		self.r_marker = self.r_marker + dwSize
		if (self.r_marker > size) then 
			self.r_marker = size
			return
		elseif (self.r_marker == size) then 
			return
		end
	end
end

function cBinaryData:export(as_filename)
	local fname = as_filename or self.fname
	local file = physfs.PHYSFS_openWrite(fname)
	if (file ~= nil) then
		physfs.PHYSFS_writeBytes(file,self.data,self._size)
		physfs.PHYSFS_close(file)
		return true
	else 
		print("filesystem.write: " .. ffi.string(physfs.PHYSFS_getLastError()) .. " - " .. filename)
	end
end