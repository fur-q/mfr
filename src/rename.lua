local util = require "mfr_internal.util"  -- FIXME this breaks testing

local sformat, sgsub = string.format, string.gsub
local rename = os.rename 
local ipairs, pcall, setmetatable, select, type = ipairs, pcall, setmetatable, select, type

local M = {}

M.add = function(self, name)
    if util.is_file(name) then
        self[#self+1] = { path = name }
    end
end

M.loadscript = function(self, scr)
    local fn, err = loadstring(scr)
    if not fn then
        return sformat("Error in Lua script: %s", err)
    end
    local rep = fn()
    if type(rep) ~= "function" and type(rep) ~= "table" then
        return "Error: Lua script must return a function or table"
    end
    self.repl = rep
end

M.loadsource = function(self, src)
    self.src = util.lines(src)
end

M.match = function(self)
    local count = 0
    local dupes = {}
    for i, v in ipairs(self) do
        -- stop processing when no self.src lines are left
        if self.src and not self.src[i] then
            v.new = nil
            goto skip
        end
        local old, ext = util.basename(v.path), nil
        if self.noexts then
            old, ext = old:match("^(.-)%f[.%z]%.?([^.]*)$") -- thx mniip
        end
        local src = self.src and self.src[i] or old
        local ok, new = pcall(sgsub, src, self.patt, self.repl)
        if not ok then -- pattern error
            return nil, "Pattern error: " .. new
        end
        if (not new) or old == new then
            goto skip
        end
        if dupes[new] then
            return nil, "Duplicate output filename: " .. new
        end
        count = count + 1
        dupes[new] = true
        v.new = util.join(".", new, ext)
        ::skip::
    end
    return count
end

M.rename = function(self)
    local status = true
    for i, v in ipairs(self) do
        if not v.new then
            goto skip
        end
        local ok, err = os.rename(v.path, util.join("/", util.dirname(v.path), v.new))
        if ok then 
            goto skip
        end
        status = false
        v.err = err
        self.errors[#self.errors+1] = i
        if self.cautious then 
            break
        end
        ::skip::
    end
    return status
end

M.reset = function(self)
    self.patt = nil
    self.repl = type(self.repl) ~= "string" and self.repl or nil
end

return function(...)
    local out = setmetatable({ errors = {} }, { __index = M })
    for i = 1, select('#', ...) do
        out:add(select(i, ...))
    end
    return out
end
