local util = require "util"

local M = {}

M.add = function(self, name)
    if util.is_file(name) then
        self[#self+1] = { path = name }
    end
end

M.match = function(self, match, replace, preserve)
    local count = 0
    local dupes = {}
    for i, v in ipairs(self) do
        -- stop processing when no source lines are left
        if self.source and not self.source[i] then
            self[i] = nil
            goto skip
        end
        local old = util.basename(v.path)
        local ext
        if preserve then
            old, ext = old:match("^(.-)%f[.%z]%.?([^.]*)$") -- thx mniip
        end
        local src = self.source and self.source[i] or old
        local ok, new = pcall(string.gsub, src, match, replace)
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

M.rename = function(self, stop)
    local status = true
    for i, f in ipairs(self) do
        local ok, err = os.rename(f.path, util.join("/", util.dirname(f.path), f.new))
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

M.set_source = function(self, src)
    if type(src) ~= "string" then return end
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
