local ffi = require( "ffi" )
ffi.cdef([[
typedef enum PHYSFS_ErrorCode
{
    PHYSFS_ERR_OK,               /**< Success; no error.                    */
    PHYSFS_ERR_OTHER_ERROR,      /**< Error not otherwise covered here.     */
    PHYSFS_ERR_OUT_OF_MEMORY,    /**< Memory allocation failed.             */
    PHYSFS_ERR_NOT_INITIALIZED,  /**< PhysicsFS is not initialized.         */
    PHYSFS_ERR_IS_INITIALIZED,   /**< PhysicsFS is already initialized.     */
    PHYSFS_ERR_ARGV0_IS_NULL,    /**< Needed argv[0], but it is NULL.       */
    PHYSFS_ERR_UNSUPPORTED,      /**< Operation or feature unsupported.     */
    PHYSFS_ERR_PAST_EOF,         /**< Attempted to access past end of file. */
    PHYSFS_ERR_FILES_STILL_OPEN, /**< Files still open.                     */
    PHYSFS_ERR_INVALID_ARGUMENT, /**< Bad parameter passed to an function.  */
    PHYSFS_ERR_NOT_MOUNTED,      /**< Requested archive/dir not mounted.    */
    PHYSFS_ERR_NOT_FOUND,        /**< File (or whatever) not found.         */
    PHYSFS_ERR_SYMLINK_FORBIDDEN,/**< Symlink seen when not permitted.      */
    PHYSFS_ERR_NO_WRITE_DIR,     /**< No write dir has been specified.      */
    PHYSFS_ERR_OPEN_FOR_READING, /**< Wrote to a file opened for reading.   */
    PHYSFS_ERR_OPEN_FOR_WRITING, /**< Read from a file opened for writing.  */
    PHYSFS_ERR_NOT_A_FILE,       /**< Needed a file, got a directory (etc). */
    PHYSFS_ERR_READ_ONLY,        /**< Wrote to a read-only filesystem.      */
    PHYSFS_ERR_CORRUPT,          /**< Corrupted data encountered.           */
    PHYSFS_ERR_SYMLINK_LOOP,     /**< Infinite symbolic link loop.          */
    PHYSFS_ERR_IO,               /**< i/o error (hardware failure, etc).    */
    PHYSFS_ERR_PERMISSION,       /**< Permission denied.                    */
    PHYSFS_ERR_NO_SPACE,         /**< No space (disk full, over quota, etc) */
    PHYSFS_ERR_BAD_FILENAME,     /**< Filename is bogus/insecure.           */
    PHYSFS_ERR_BUSY,             /**< Tried to modify a file the OS needs.  */
    PHYSFS_ERR_DIR_NOT_EMPTY,    /**< Tried to delete dir with files in it. */
    PHYSFS_ERR_OS_ERROR,         /**< Unspecified OS-level error.           */
    PHYSFS_ERR_DUPLICATE,        /**< Duplicate entry.                      */
    PHYSFS_ERR_BAD_PASSWORD,     /**< Bad password.                         */
    PHYSFS_ERR_APP_CALLBACK      /**< Application callback reported error.  */
} PHYSFS_ErrorCode;
typedef unsigned char PHYSFS_uint8;
typedef signed char PHYSFS_sint8;
typedef unsigned short PHYSFS_uint16;
typedef signed short PHYSFS_sint16;
typedef unsigned int PHYSFS_uint32;
typedef signed int PHYSFS_sint32;
typedef unsigned long long PHYSFS_uint64;
typedef signed long long PHYSFS_sint64;
typedef int PHYSFS_dummy_uint8[(sizeof(PHYSFS_uint8) == 1) * 2 - 1];
typedef int PHYSFS_dummy_sint8[(sizeof(PHYSFS_sint8) == 1) * 2 - 1];
typedef int PHYSFS_dummy_uint16[(sizeof(PHYSFS_uint16) == 2) * 2 - 1];
typedef int PHYSFS_dummy_sint16[(sizeof(PHYSFS_sint16) == 2) * 2 - 1];
typedef int PHYSFS_dummy_uint32[(sizeof(PHYSFS_uint32) == 4) * 2 - 1];
typedef int PHYSFS_dummy_sint32[(sizeof(PHYSFS_sint32) == 4) * 2 - 1];
typedef int PHYSFS_dummy_uint64[(sizeof(PHYSFS_uint64) == 8) * 2 - 1];
typedef int PHYSFS_dummy_sint64[(sizeof(PHYSFS_sint64) == 8) * 2 - 1];
typedef struct PHYSFS_File
{
    void *opaque;
} PHYSFS_File;
typedef struct PHYSFS_ArchiveInfo
{
    const char *extension;
    const char *description;
    const char *author;
    const char *url;
} PHYSFS_ArchiveInfo;
typedef struct PHYSFS_Version
{
    PHYSFS_uint8 major;
    PHYSFS_uint8 minor;
    PHYSFS_uint8 patch;
} PHYSFS_Version;

typedef enum PHYSFS_EnumerateCallbackResult
{
    PHYSFS_ENUM_ERROR = -1,   
    PHYSFS_ENUM_STOP = 0,     
    PHYSFS_ENUM_OK = 1        
} PHYSFS_EnumerateCallbackResult;

typedef PHYSFS_EnumerateCallbackResult (*PHYSFS_EnumerateCallback)(void *data, const char *origdir, const char *fname);
__attribute__((visibility("default"))) int PHYSFS_enumerate(const char *dir, PHYSFS_EnumerateCallback c, void *d);

__attribute__((visibility("default"))) void PHYSFS_getLinkedVersion(PHYSFS_Version *ver);
__attribute__((visibility("default"))) int PHYSFS_init(const char *argv0);
__attribute__((visibility("default"))) int PHYSFS_deinit(void);
__attribute__((visibility("default"))) const PHYSFS_ArchiveInfo **PHYSFS_supportedArchiveTypes(void);
__attribute__((visibility("default"))) void PHYSFS_freeList(void *listVar);
__attribute__((visibility("default"))) const char *PHYSFS_getLastError(void);
__attribute__((visibility("default"))) const char * PHYSFS_getErrorByCode(PHYSFS_ErrorCode code);
__attribute__((visibility("default"))) PHYSFS_ErrorCode PHYSFS_getLastErrorCode(void);
__attribute__((visibility("default"))) const char *PHYSFS_getDirSeparator(void);
__attribute__((visibility("default"))) void PHYSFS_permitSymbolicLinks(int allow);
__attribute__((visibility("default"))) char **PHYSFS_getCdRomDirs(void);
__attribute__((visibility("default"))) const char *PHYSFS_getBaseDir(void);
__attribute__((visibility("default"))) const char *PHYSFS_getUserDir(void);
__attribute__((visibility("default"))) const char *PHYSFS_getPrefDir(const char *organization, const char *appName);
__attribute__((visibility("default"))) const char *PHYSFS_getWriteDir(void);
__attribute__((visibility("default"))) int PHYSFS_setWriteDir(const char *newDir);
__attribute__((visibility("default"))) int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);
__attribute__((visibility("default"))) int PHYSFS_removeFromSearchPath(const char *oldDir);
__attribute__((visibility("default"))) char **PHYSFS_getSearchPath(void);
__attribute__((visibility("default"))) int PHYSFS_setSaneConfig(const char *organization, const char *appName, const char *archiveExt, int includeCdRoms, int archivesFirst);
__attribute__((visibility("default"))) int PHYSFS_mkdir(const char *dirName);
__attribute__((visibility("default"))) int PHYSFS_delete(const char *filename);
__attribute__((visibility("default"))) const char *PHYSFS_getRealDir(const char *filename);
__attribute__((visibility("default"))) char **PHYSFS_enumerateFiles(const char *dir);
__attribute__((visibility("default"))) int PHYSFS_exists(const char *fname);
__attribute__((visibility("default"))) int PHYSFS_isDirectory(const char *fname);
__attribute__((visibility("default"))) int PHYSFS_isSymbolicLink(const char *fname);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_getLastModTime(const char *filename);
__attribute__((visibility("default"))) PHYSFS_File *PHYSFS_openWrite(const char *filename);
__attribute__((visibility("default"))) PHYSFS_File *PHYSFS_openAppend(const char *filename);
__attribute__((visibility("default"))) PHYSFS_File *PHYSFS_openRead(const char *filename);
__attribute__((visibility("default"))) int PHYSFS_close(PHYSFS_File *handle);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_read(PHYSFS_File *handle, void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_readBytes(PHYSFS_File *handle,void *buffer,PHYSFS_uint64 len);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_write(PHYSFS_File *handle, const void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);
__attribute__((visibility("default"))) int PHYSFS_eof(PHYSFS_File *handle);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_tell(PHYSFS_File *handle);
__attribute__((visibility("default"))) int PHYSFS_seek(PHYSFS_File *handle, PHYSFS_uint64 pos);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_fileLength(PHYSFS_File *handle);
__attribute__((visibility("default"))) int PHYSFS_setBuffer(PHYSFS_File *handle, PHYSFS_uint64 bufsize);
__attribute__((visibility("default"))) int PHYSFS_flush(PHYSFS_File *handle);
__attribute__((visibility("default"))) PHYSFS_sint16 PHYSFS_swapSLE16(PHYSFS_sint16 val);
__attribute__((visibility("default"))) PHYSFS_uint16 PHYSFS_swapULE16(PHYSFS_uint16 val);
__attribute__((visibility("default"))) PHYSFS_sint32 PHYSFS_swapSLE32(PHYSFS_sint32 val);
__attribute__((visibility("default"))) PHYSFS_uint32 PHYSFS_swapULE32(PHYSFS_uint32 val);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_swapSLE64(PHYSFS_sint64 val);
__attribute__((visibility("default"))) PHYSFS_uint64 PHYSFS_swapULE64(PHYSFS_uint64 val);
__attribute__((visibility("default"))) PHYSFS_sint16 PHYSFS_swapSBE16(PHYSFS_sint16 val);
__attribute__((visibility("default"))) PHYSFS_uint16 PHYSFS_swapUBE16(PHYSFS_uint16 val);
__attribute__((visibility("default"))) PHYSFS_sint32 PHYSFS_swapSBE32(PHYSFS_sint32 val);
__attribute__((visibility("default"))) PHYSFS_uint32 PHYSFS_swapUBE32(PHYSFS_uint32 val);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_swapSBE64(PHYSFS_sint64 val);
__attribute__((visibility("default"))) PHYSFS_uint64 PHYSFS_swapUBE64(PHYSFS_uint64 val);
__attribute__((visibility("default"))) int PHYSFS_readSLE16(PHYSFS_File *file, PHYSFS_sint16 *val);
__attribute__((visibility("default"))) int PHYSFS_readULE16(PHYSFS_File *file, PHYSFS_uint16 *val);
__attribute__((visibility("default"))) int PHYSFS_readSBE16(PHYSFS_File *file, PHYSFS_sint16 *val);
__attribute__((visibility("default"))) int PHYSFS_readUBE16(PHYSFS_File *file, PHYSFS_uint16 *val);
__attribute__((visibility("default"))) int PHYSFS_readSLE32(PHYSFS_File *file, PHYSFS_sint32 *val);
__attribute__((visibility("default"))) int PHYSFS_readULE32(PHYSFS_File *file, PHYSFS_uint32 *val);
__attribute__((visibility("default"))) int PHYSFS_readSBE32(PHYSFS_File *file, PHYSFS_sint32 *val);
__attribute__((visibility("default"))) int PHYSFS_readUBE32(PHYSFS_File *file, PHYSFS_uint32 *val);
__attribute__((visibility("default"))) int PHYSFS_readSLE64(PHYSFS_File *file, PHYSFS_sint64 *val);
__attribute__((visibility("default"))) int PHYSFS_readULE64(PHYSFS_File *file, PHYSFS_uint64 *val);
__attribute__((visibility("default"))) int PHYSFS_readSBE64(PHYSFS_File *file, PHYSFS_sint64 *val);
__attribute__((visibility("default"))) int PHYSFS_readUBE64(PHYSFS_File *file, PHYSFS_uint64 *val);
__attribute__((visibility("default"))) int PHYSFS_writeSLE16(PHYSFS_File *file, PHYSFS_sint16 val);
__attribute__((visibility("default"))) int PHYSFS_writeULE16(PHYSFS_File *file, PHYSFS_uint16 val);
__attribute__((visibility("default"))) int PHYSFS_writeSBE16(PHYSFS_File *file, PHYSFS_sint16 val);
__attribute__((visibility("default"))) int PHYSFS_writeUBE16(PHYSFS_File *file, PHYSFS_uint16 val);
__attribute__((visibility("default"))) int PHYSFS_writeSLE32(PHYSFS_File *file, PHYSFS_sint32 val);
__attribute__((visibility("default"))) int PHYSFS_writeULE32(PHYSFS_File *file, PHYSFS_uint32 val);
__attribute__((visibility("default"))) int PHYSFS_writeSBE32(PHYSFS_File *file, PHYSFS_sint32 val);
__attribute__((visibility("default"))) int PHYSFS_writeUBE32(PHYSFS_File *file, PHYSFS_uint32 val);
__attribute__((visibility("default"))) int PHYSFS_writeSLE64(PHYSFS_File *file, PHYSFS_sint64 val);
__attribute__((visibility("default"))) int PHYSFS_writeULE64(PHYSFS_File *file, PHYSFS_uint64 val);
__attribute__((visibility("default"))) int PHYSFS_writeSBE64(PHYSFS_File *file, PHYSFS_sint64 val);
__attribute__((visibility("default"))) int PHYSFS_writeUBE64(PHYSFS_File *file, PHYSFS_uint64 val);
__attribute__((visibility("default"))) int PHYSFS_isInit(void);
__attribute__((visibility("default"))) int PHYSFS_symbolicLinksPermitted(void);
typedef struct PHYSFS_Allocator
{
    int (*Init)(void);
    void (*Deinit)(void);
    void *(*Malloc)(PHYSFS_uint64);
    void *(*Realloc)(void *, PHYSFS_uint64);
    void (*Free)(void *);
} PHYSFS_Allocator;

typedef enum PHYSFS_FileType
{
	PHYSFS_FILETYPE_REGULAR, 
	PHYSFS_FILETYPE_DIRECTORY, 
	PHYSFS_FILETYPE_SYMLINK, 
	PHYSFS_FILETYPE_OTHER 
} PHYSFS_FileType;

typedef struct PHYSFS_Stat
{
	PHYSFS_sint64 filesize; 
	PHYSFS_sint64 modtime;  
	PHYSFS_sint64 createtime; 
	PHYSFS_sint64 accesstime; 
	PHYSFS_FileType filetype; 
	int readonly; 
} PHYSFS_Stat;

__attribute__((visibility("default"))) int PHYSFS_setAllocator(const PHYSFS_Allocator *allocator);
__attribute__((visibility("default"))) int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);
__attribute__((visibility("default"))) int PHYSFS_unmount(const char *oldDir);

__attribute__((visibility("default"))) const char *PHYSFS_getMountPoint(const char *dir);
typedef void (*PHYSFS_StringCallback)(void *data, const char *str);
typedef void (*PHYSFS_EnumFilesCallback)(void *data, const char *origdir, const char *fname);
__attribute__((visibility("default"))) void PHYSFS_getCdRomDirsCallback(PHYSFS_StringCallback c, void *d);
__attribute__((visibility("default"))) void PHYSFS_getSearchPathCallback(PHYSFS_StringCallback c, void *d);
__attribute__((visibility("default"))) void PHYSFS_enumerateFilesCallback(const char *dir, PHYSFS_EnumFilesCallback c, void *d);
__attribute__((visibility("default"))) void PHYSFS_utf8FromUcs4(const PHYSFS_uint32 *src, char *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) void PHYSFS_utf8ToUcs4(const char *src, PHYSFS_uint32 *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) void PHYSFS_utf8FromUcs2(const PHYSFS_uint16 *src, char *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) void PHYSFS_utf8ToUcs2(const char *src, PHYSFS_uint16 *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) void PHYSFS_utf8FromLatin1(const char *src, char *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) void PHYSFS_utf8FromUtf16(const PHYSFS_uint16 *src, char *dst, PHYSFS_uint64 len);
__attribute__((visibility("default"))) int PHYSFS_utf8stricmp(const char *str1,const char *str2);
__attribute__((visibility("default"))) int PHYSFS_stat(const char *fname, PHYSFS_Stat *stat);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_read(PHYSFS_File *handle, void *buffer, PHYSFS_uint32 objSize,PHYSFS_uint32 objCount);
__attribute__((visibility("default"))) PHYSFS_sint64 PHYSFS_writeBytes(PHYSFS_File *handle, const void *buffer, PHYSFS_uint64 len);
]])
return ffi.load( "physfs" )
