-------------------------------------------------------------
-- Initialize third-party libraries into global namespaces
-------------------------------------------------------------
bit 			= require("bit")
physfs			= require("ffi_physfs")										; if not (physfs) then error("Failed to load physfs") end
Class			= require("class")
lzss			= require("ffi_lzss")