local rename = require "rename"
local util   = require "util"
local test   = require "test"
local files  = { "file1.lua", "file2.c", "file3.lua" }

local testscript = [[
local i = 0
return function(s)
    i = i + 1
    return s .. i
end
]]

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
    return MOCK_SUCCEED, MOCK_SUCCEED or ";_;"
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
    assert.equal(util.join(".", "foo", "bar"), "foo.bar")
    assert.equal(util.join(".", "foo"), "foo")
    assert.equal(util.join("/", ".", "foo"), "./foo")
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
    R.patt, R.repl = "file(%d+).lua", "test%1.lua"
    local count, err = R:match()
    assert.equal(count, 2)
    assert.equal(R[1].new, "test1.lua")
    assert.equal(R[2].new, nil)
end

test.match_error = function()
    R.patt, R.repl = "[[[", ""
    local count, err = R:match()
    assert.equal(count, nil)
end

test.dupe_error = function()
    R.patt, R.repl = ".+", "foo"
    local count, err = R:match()
    assert.equal(err, "Duplicate output filename: foo")
end

test.source = function()
    R:loadsource("foo\nbar")
    R.patt, R.repl = "(.+)", "%1"
    local count, err = R:match()
    assert.equal(count, 2)
    assert.equal(R[1].new, "foo")
    assert.equal(R[3], nil)
end

test.preserve = function()
    R.noexts = true
    local count, err = R:match()
    assert.equal(R[1].new, "foo.lua")
end

test.script = function()
    R:loadscript(testscript)
    local count, err = R:match()
    assert.equal(R[1].new, "foo1.lua")
    assert.equal(R[2].new, "bar2.c")
end

-- FIXME test break_on_error
test.rename = function()
    assert.equal(R:rename(), true)
end

test.rename_error = function()
    MOCK_SUCCEED = false
    assert.equal(R:rename(), false)
end

test.errors = function()
    assert.equal(R[R.errors[1]].err, ";_;")
end

test()
