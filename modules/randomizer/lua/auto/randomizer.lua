local config =  nil
function application_init()
	config = core.import.ini("settings.ini")
	local path = config:r_string("path","fallout1",[[C:\Program Files (x86)\Steam\steamapps\common\Fallout\]])
	filesystem.mount(path,"Fallout/",false)
	filesystem.setWriteDirectory(path)
	
	local seedStr = config:r_string("randomize","seed")
	if (seedStr) then
		local seed = 0
		for i=1,#seedStr do
			seed = seed + string.byte(seedStr,i)
		end
		math.randomseed(seed)
	else
		math.randomseed(os.time())
	end
end

local EXTRACT_ALL = false -- testing only

function application_run()
	if not (filesystem.exists("Fallout/MASTER.DAT")) then
		print("Cannot find MASTER.DAT. Make sure proper Fallout path is configured in modules/randomizer/settings.ini")
		return
	end
	
	local bin = core.import.binary("Fallout/MASTER.DAT")
	
	-- Read as Big Endian
	bin.endian = "be" 
	
	bin:r_seek(bin:size()-8)
	local treeSize = bin:r_u32()
	local fileSizeFromDat = bin:r_u32()
	
	-- decide which version of Fallout
	if (bin:size() == fileSizeFromDat) then
		print("This modification only supports Fallout 1")
		return
	end

	bin:r_seek(0)
	
	local dirCount = bin:r_u32()
	if not (bit.band(dirCount,0xFF00000) == 0) then
		print("This modification only supports Fallout 1")
		return
	end
	
	bin:r_advance(12)

	local directories = {}
	for i=1, dirCount do
		local dirName = bin:r_string(bin:r_u8())
		if (dirName == ".") then
			dirName = ""
		else
			dirName = dirName:gsub("\\","/")
		end
		table.insert(directories,dirName)
	end
	
	local extractList = { ["PROTO/CRITTERS"] = true, ["PROTO/ITEMS"] = true }

	for i,dirName in ipairs(directories) do
		local fileCount = bin:r_u32()

		bin:r_advance(12)
		
		for j=1, fileCount do
			local r_pos = bin:r_tell()
			if (extractList[dirName] or EXTRACT_ALL == true) then
				local fileName = bin:r_string(bin:r_u8())
				local ext = fileName:gsub("(.*)%.","")
				if (ext == "PRO" or EXTRACT_ALL == true) then
					print("DATA/" .. dirName .. "/" .. fileName)
					local subdata = extract_FO1(bin)
					
					local objDescriptor = subdata:r_u32()
					local objType = bit.band(bit.bswap(objDescriptor),0x0FFF)
					local objID = bit.band(objDescriptor,0x0FFF)
					
					if (objType == 0) then
						randomize_item(subdata)
					elseif (objType == 1) then
						randomize_critter(subdata)
					end
					
					-- testing only
					if (EXTRACT_ALL) then
						filesystem.mkdir("TEST/" .. dirName)
						subdata:export("TEST/" .. dirName .. "/" .. fileName)
					end
					
					filesystem.mkdir("DATA/" .. dirName)
					subdata:export("DATA/" .. dirName .. "/" .. fileName)
				end
			end
			bin:r_seek(r_pos)
			bin:r_advance(16+bin:r_u8())
		end
	end
end

function extract_FO1(stream)
	local r_pos = stream:r_tell()
	
	local compression = stream:r_u32() == 0x40
	local offset = stream:r_u32()
	local sizeUncompressed = stream:r_u32()
	local sizeCompressed = stream:r_u32()

	local buffer2 = ffi.new("unsigned char[?]",sizeUncompressed)
	
	if (compression) then
		local ptr1 = stream.data+offset
		local pBuf = buffer2
		local bytesLeft = sizeCompressed
		
		repeat
			local v = ffi.cast("uint16_t *",ptr1)
			local blockDescriptor = tonumber( bit.rshift(bit.bswap(v[0]),ffi.sizeof("uint16_t")*8) )
			
			local bytesToRead = bit.band(blockDescriptor,0x7FFF)

			if (bit.band(blockDescriptor,0x8000) ~= 0) then -- uncompressed block
				ffi.copy(pBuf,ptr1+2,bytesToRead)
				pBuf = pBuf + bytesToRead
			else
				local sz = lzss.decompress(ptr1+2,bytesToRead,pBuf)
				pBuf = pBuf + sz
			end
			ptr1 = ptr1 + bytesToRead + 2
			bytesLeft = bytesLeft - bytesToRead - 2
		until (bytesLeft <= 0)
	else
		ffi.copy(buffer2,stream.data+offset,sizeUncompressed)
	end
	
	local outputStream = core.import.binary.new(buffer2,sizeUncompressed)
	outputStream.endian = "be"
	
	stream:r_seek(r_pos)
	
	return outputStream
end

function randomize_critter(stream)
	if (config:r_bool("randomize","CritterSPECIAL",false)) then
		stream:w_seek(0x00BC)
		stream:r_seek(0x0030)
		for i=1,7 do
			local attrib = stream:r_u32()
			local val =  math.random(-2,2)
			if (attrib + val < 1) then
				val = 0
			elseif (attrib + val > 10) then
				val = 10 - attrib
			end
			stream:w_u32( val )
		end
	end
	
	if (config:r_bool("randomize","CritterHP",false)) then
		stream:r_seek(0x004C)
		local HP = stream:r_u32()
		local val = math.random(-math.floor(HP/2),HP)
		stream:w_seek(0x00D8)
		stream:w_u32( val )
	end

	if (config:r_bool("randomize","CritterAP",false)) then
		stream:r_seek(0x0050)
		local AP = stream:r_u32()
		local val = math.random(-2,2)
		if (AP + val < 6) then
			val = 0
		end
		stream:w_seek(0x00DC)
		stream:w_u32( val )
	end
	
	if (config:r_bool("randomize","CritterAC",false)) then
		stream:r_seek(0x0054)
		local AC = stream:r_u32()
		local val = math.random(-10,10)
		if (AC + val < 0) then
			val = 0
		end
		stream:w_seek(0x00E0)
		stream:w_u32( val )
	end
	
	if (config:r_bool("randomize","CritterSkills",false)) then
		stream:w_seek(0x0148)
		for i=1,18 do
			stream:w_u32( math.random(0,100) )
		end
	end
	
	-- Recalculate Exp based on attributes
	if (config:r_bool("randomize","CritterExp",false)) then
		local SPECIAL = 0
		stream:r_seek(0x0030)
		for i=1,7 do
			SPECIAL = SPECIAL + stream:r_u32()
		end
		stream:r_seek(0x00BC)
		for i=1,7 do
			SPECIAL = SPECIAL + stream:r_u32()
		end
		stream:r_seek(0x004C)
		local HP = stream:r_u32()
		stream:r_seek(0x00D8)
		local BHP = stream:r_u32()
		stream:r_seek(0x0050)
		local AP = stream:r_u32()
		stream:r_seek(0x00DC)
		local BAP = stream:r_u32()
		stream:r_seek(0x0054)
		local AC = stream:r_u32()
		stream:r_seek(0x00E0)
		local BAC = stream:r_u32()
		local DTTotal = 0
		local DRTotal = 0
		stream:r_seek(0x0100)
		for i=1,5 do
			DTTotal = DTTotal + stream:r_u32()
		end
		stream:r_seek(0x011C)
		for i=1,5 do
			local val = stream:r_u32()
			DRTotal = DRTotal + (val / 10)
		end
		local Exp = math.floor( (SPECIAL * 0.25) + ((HP+BHP) * 0.50) + ((AC+BAC) * 0.75) + ((AP+BAP) * 3) + (DRTotal+DTTotal*2) )
		stream:w_seek(0x0194)
		stream:w_u32( Exp )
	end
end

function randomize_item(stream)
	stream:r_seek(0x0020)
	local objSubType = stream:r_u32()
	
	-- ARMOR
	if (objSubType == 0) then
		stream:w_seek(0x0039)
		stream:w_u32( math.random(0,20) )
		for i=1,14 do
			stream:w_u32( math.random(0,50) )
		end
	-- CONTAINER
	elseif (objSubType == 1) then

	-- DRUG
	elseif (objSubType == 2) then

	-- WEAPON
	elseif (objSubType == 3) then
		if (config:r_bool("randomize","WeaponDamage",false)) then
			stream:r_seek(0x003D)
			local minDamage = stream:r_u32()
			local maxDamage = stream:r_u32()
			stream:w_seek(0x003D)
			stream:w_u32( math.clamp(math.random(minDamage-5,minDamage+5),5,minDamage+5) )
			stream:w_u32( math.clamp(math.random(maxDamage-5,maxDamage+5),minDamage,maxDamage+5) )
		end
	-- AMMO
	elseif (objSubType == 4) then
	
	-- MISC.
	elseif (objSubType == 5) then
	
	-- KEY
	elseif (objSubType == 6) then
	
	end
end