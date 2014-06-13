local ffi  = require "ffi"
local util = require "src.util"

local open, stdin = io.open, io.stdin
local floor, min, max = math.floor, math.min, math.max
local exit = os.exit
local sformat, srep = string.format, string.rep
local ipairs, print, type = ipairs, print, type

ffi.cdef [[
    struct FFILE;
    typedef struct FFILE FILE;

    int    fileno(FILE * stream);
    void   free(void * p);
    FILE * freopen(const char *restrict filename, const char *restrict mode, FILE *restrict stream);
    int    isatty(int fd);
    char * linenoise(const char * prompt);
    int    mfr_termwidth(void);
]]

local M = {}

M.isatty = function(fh)
    return ffi.C.isatty(ffi.C.fileno(fh)) == 1
end

M.freopen = function(fn, mode, stream)
    return ffi.C.freopen(fn, mode, stream)
end

M.pluralise = function(count, word)
    if count ~= 1 and word:sub(#word, #word) ~= "s" then
        word = word .. "s"
    end
    return count, word
end

M.printf = function(fmt, ...)
    print(sformat(fmt, ...))
end

M.prompt = function(prompt)
    local str = ffi.C.linenoise(prompt)
    if str ~= nil then
        local out = ffi.string(str)
        ffi.C.free(str)
        return out
    else -- assume ^C was pressed and die gracefully
        exit(1)
    end
end

M.promptf = function(fmt, ...)
    return M.prompt(sformat(fmt, ...))
end

M.read_input = function(opt, prompt)
    local out
    if opt == true then -- no filename provided; read from stdin
        print(prompt)
        out = stdin:read("*a")
    elseif type(opt) == "string" then
        local f, err = open(opt)
        if not f then
            return nil, sformat("File not found: %s", opt)
        end
        out = f:read("*a")
        f:close()
    end
    return out
end

M.yesno = function(prompt, default)
    local ext = default == true and "Y/n" or "y/N"
    local out = M.promptf("%s (%s) ", prompt, ext)
    if default == true then 
        return not out:match("^[nN]")
    end
    return not not out:match("^[yY]")
end

local termwidth = function()
    return ffi.C.mfr_termwidth()
end

local colwidth = function(R)
    local width = termwidth() - 4
    local colmax = floor(width/2)
    local omax, nmax = 16, 16 -- minimum widths
    for k, v in ipairs(R) do
        if v.new then
            omax, nmax = max(omax, #util.basename(v.path)), max(nmax, #v.new)
        end
    end
    return min(omax, colmax), min(nmax, colmax)
end

local listchanges = function(R)
    local omax, nmax = colwidth(R)
    local fmt = sformat("%%-%d.%ds  %%-%d.%ds", omax, omax, nmax, nmax)
    M.printf(fmt, "Old name", "New name")
    print(srep("-", omax + nmax + 2))
    for k, v in ipairs(R) do
        if v.new then
            M.printf(fmt, util.basename(v.path), v.new)
        end
    end
    print()
end

M.preview = function(R, y)
    R.patt = R.patt or M.prompt("Enter match pattern: ")
    R.repl = R.repl or M.prompt("Enter replace pattern: ")
    local count, err = R:match()
    if count == 0 then
        err = "Nothing to rename."
    end
    if err then
        print(err)
        return M.yesno("Retry?", true)
    end
    if not y then
        M.printf("Matched %d %s:", M.pluralise(count, "file"))
        listchanges(R) 
        return (not M.yesno("OK to rename?")) or nil
    end
end

return M
