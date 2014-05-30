local util = require "util"

local M = {}

M.add = function(self, name)
    if util.is_file(name) then
        self[#self+1] = { path = name }
    end
end

M.match = function(self, match, replace)
    local count = 0
    for i, v in ipairs(self) do
        -- stop processing when no source lines are left
        if self.source and not self.source[i] then
            break
        end
        local old = self.source[i] or util.basename(v.path)
        local ok, new = pcall(string.gsub, old, match, replace)
        if not ok then -- pattern error
            return nil, new
        end
        if old ~= new then
            v.old, v.new = old, new
            count = count + 1
        else
            v.old, v.new = nil, nil
        end
    end
    return count
end

M.rename = function(self, stop)
    local status = true
    for i, f in ipairs(self) do
        local newpath = util.join(util.dirname(f.path), f.new)
        local ok, err = os.rename(f.path, newpath)
        if ok then 
            goto skip
        end
        status = false
        f.err = err
        self.errors[#self.errors+1] = i
        if stop then 
            break
        end
        ::skip::
    end
    return status
end

M.source = function(self, src)
    if not type(src) == "string" then return end
    self.source = {}
    for m in src:gmatch("[^\n]+") do
        self.source[#self.source+1] = m
    end
end

return function(...)
    local out = setmetatable({ errors = {} }, { __index = M })
    for i = 1, select('#', ...) do
        out:add(select(i, ...))
    end
    return out
end
