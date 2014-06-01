local ffi = require "ffi"

ffi.cdef [[
    void   free(void * p);
    char * linenoise(const char * prompt);
    int    mfr_termwidth(void);
]]

local M = {}

-- these shouldn't really be here but who cares

M.pluralise = function(count, word)
    if count ~= 1 and word:sub(#word, #word) ~= "s" then
        word = word .. "s"
    end
    return count, word
end

M.printf = function(fmt, ...)
    print(string.format(fmt, ...))
end

M.prompt = function(prompt)
    local str = ffi.C.linenoise(prompt)
    if str ~= nil then
        local out = ffi.string(str)
        ffi.C.free(str)
        return out
    else -- assume ^C was pressed and die gracefully
        os.exit(1)
    end
end

M.promptf = function(fmt, ...)
    return M.prompt(string.format(fmt, ...))
end

M.yesno = function(prompt, default)
    local ext = default == true and "Y/n" or "y/N"
    local out = M.promptf("%s (%s) ", prompt, ext)
    if default == true then 
        return not not out:match("^[nN]")
    end
    return not not out:match("^[yY]")
end

local termwidth = function()
    return ffi.C.mfr_termwidth()
end

local min, max = math.min, math.max

M.preview = function(rn)
    local width = termwidth() - 4
    local colmax = math.floor(width/2)
    local omax, nmax = 0, 0
    for k, v in ipairs(rn) do
        if v.old then
            omax, nmax = max(omax, #v.old), max(nmax, #v.new)
        end
    end
    omax, nmax = max(16, min(omax, colmax)), max(16, min(nmax, colmax))
    local fmt = string.format("%%-%d.%ds  %%-%d.%ds", omax, omax, nmax, nmax)
    M.printf(fmt, "Old name", "New name")
    print(string.rep("-", omax + nmax + 2))
    for k, v in ipairs(rn) do
        if v.old then
            M.printf(fmt, v.old, v.new)
        end
    end
    print()
end

return M
