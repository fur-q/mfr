local util = require "util"

local M = {}

M.add = function(self, name)
    if util.is_file(name) then
        self[#self+1] = { path = name }
    end
end

M.loadscript = function(self, scr)
    local fn, err = loadstring(scr)
    if not fn then
        return string.format("Error in Lua script: %s", err)
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

-- FIXME source should be a param, or all the other shit should not be
M.match = function(self)
    local count = 0
    local dupes = {}
    for i, v in ipairs(self) do
        -- stop processing when no self.src lines are left
        if self.src and not self.src[i] then
            self[i] = nil
            goto skip
        end
        local old = util.basename(v.path)
        local ext
        if self.noexts then
            old, ext = old:match("^(.-)%f[.%z]%.?([^.]*)$") -- thx mniip
        end
        local src = self.src and self.src[i] or old
        local ok, new = pcall(string.gsub, src, self.patt, self.repl)
        if not ok then -- pattern error
            return nil, "Pattern error: " .. new
        end
        new = util.join(".", new, ext)
        if old ~= new then
            if dupes[new] then
                return nil, "Duplicate output filename: " .. new
            end
            dupes[new] = true
            v.new = new
            count = count + 1
        else
            v.new, v.ext = nil, nil
        end
        ::skip::
    end
    return count
end

M.rename = function(self)
    local status = true
    for i, f in ipairs(self) do
        local ok, err = os.rename(f.path, util.join("/", util.dirname(f.path), f.new))
        if ok then 
            goto skip
        end
        status = false
        f.err = err
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
    self.repl = type(self.rep) ~= "string" and self.repl or nil
end

return function(...)
    local out = setmetatable({ errors = {} }, { __index = M })
    for i = 1, select('#', ...) do
        out:add(select(i, ...))
    end
    return out
end
