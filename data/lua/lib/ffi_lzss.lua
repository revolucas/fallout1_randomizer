local ffi = require("ffi")
ffi.cdef[[
__declspec(dllexport) unsigned int compress(unsigned char* buffer, int dwInputLength, unsigned char* output);
__declspec(dllexport) unsigned int decompress(unsigned char* buffer, int dwInputLength, unsigned char* output);
]]

return ffi.load("lzss")