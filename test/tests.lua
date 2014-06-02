local rename = require "rename"
local util   = require "util"
local test   = require "test"
local files  = { "file1.lua", "file2.c", "file3.lua" }

local testpaths = {
    { "/usr/lib", "/usr", "lib" },
    { "/usr/",    "/",    "usr" },
    { "usr",      ".",    "usr" },
    { "/",        "/",    "/"   },
    { ".",        ".",    "."   },
    { "..",       ".",    ".."  },
}
if jit.os == "Linux" then -- gnu basename
    testpaths[2][3] = ""
    testpaths[4][3] = ""
end

-- mock functions

local MOCK_SUCCEED = true

util.is_file = function()
    return MOCK_SUCCEED
end

os.rename = function()
    return MOCK_SUCCEED
end

-- util tests

test.basename = function()
    for i, v in ipairs(testpaths) do
        assert.equal(util.basename(v[1]), v[3])
    end
end

test.dirname = function()
    for i, v in ipairs(testpaths) do
        assert.equal(util.dirname(v[1]), v[2])
    end
end

test.join = function()

end

-- rename tests

local R

test.add = function()
    R = rename(unpack(files))
    assert.equal(#R, 3)
end

test.add_error = function()
    MOCK_SUCCEED = false
    R = rename(unpack(files))
    assert.equal(#R, 0)
    MOCK_SUCCEED = true
end

test.match = function()
    R = rename(unpack(files))
    local count, err = R:match("file(%d+).lua", "test%1.lua")
    assert.equal(count, 2)
    assert.equal(R[1].new, "test1.lua")
    assert.equal(R[2].new, nil)
end

test.match_error = function()
    local count, err = R:match("[[[", "")
    assert.equal(count, nil)
end

test.source = function()
    R:set_source("foo\nbar")
    local count, err = R:match("(.+)", "%1")
    assert.equal(count, 2)
    assert.equal(R[1].new, "foo")
    assert.equal(R[3], nil)
end

test.preserve = function()
    local count, err = R:match("(.+)", "%1", true)
    assert.equal(R:newpath(1), "./foo.lua")
end

-- FIXME test break_on_error
test.rename = function()
    assert.equal(R:rename(), true)
end

test.rename_error = function()
    MOCK_SUCCEED = false
    assert.equal(R:rename(), false)
end

test()
