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

M.join = function(sep, p1, p2)
    if (not p2) or #p2 == 0 then
        return p1
    end
    return p1 .. sep .. p2
end

M.lines = function(str)
    if type(str) ~= "string" then return end
    out = {}
    for m in str:gmatch("[^\n]+") do
        out[#out+1] = m
    end
    return out
end

return M
