local ffi = require "ffi"

ffi.cdef [[
    char * basename(const char * path);
    char * dirname(const char * path);
    int    mfr_isfile(const char * path);
]]

local fstr = function(str)
    if str ~= nil then
        return ffi.string(str)
    end
end

local M = {}

M.basename = function(path)
    return fstr(ffi.C.basename(path))
end

M.dirname = function(path)
    return fstr(ffi.C.dirname(path))
end

M.is_file = function(path)
    return ffi.C.mfr_isfile(path) == 1 
end

M.join = function(path, name, ext)
    if not path then
        return name
    end
    ext = ext and "." .. ext or ""
    return path .. "/" .. name .. ext 
end

return M
