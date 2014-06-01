local optparse = require "optparse"
local renamer  = require "rename"
local util     = require "cliutil"

local MFR_VERSION = "0.5.0"

local parser = optparse(string.format([[
mfr %s

Usage: %s [OPTION]... [FILE]...
Batch rename files using Lua patterns.

  -b, --break              stop processing after encountering an error
  -m, --match=[PATTERN]    set filename match pattern
  -r, --replace=[PATTERN]  set filename replacement pattern
  -s, --source=[FILE]      match against lines from FILE instead of filenames
  -y, --yes                always answer yes at yes/no prompts
  -h, --help               show this help and exit
  -v, --version            show version information and exit

Report bugs at <http://github.com/fur-q/mfr>.
]], MFR_VERSION, arg[0]))

local args, opts = parser:parse(arg)

if #args == 0 then
    parser:opterr("No filenames provided")
end

local match, replace = opts.match, opts.replace

local R = renamer(unpack(args))
util.printf("%d files found.", #R)
if #R == 0 then
    return 1
end

local source

if opts.source == true then -- no filename provided; read from stdin
    source = io.stdin:read("*a")
elseif type(opts.source) == "string" then
    local f, err = io.open(opts.source)
    if not f then
        local err = string.format("Source file not found: %s", opts.source)
        parser:opterr(err)
    end
    source = f:read("*a")
    f:close()
end

R:set_source(source)

-- TODO default to the last pattern used

local function preview()
    match = match or util.prompt("Enter match pattern: ")
    replace = replace or util.prompt("Enter replace pattern: ")
    local count, err = R:match(match, replace)
    if not count then
        util.printf("Pattern error: %s", err)
        return util.yesno("Retry?", true)
    end
    util.printf("Matched %d %s", util.pluralise(count, "file"))
    if count == 0 then
        return util.yesno("Retry?", true)
    end
    if not opts.yes then
        util.preview(R) 
        return util.yesno("OK to rename?") or nil
    end
end

repeat
    ok = preview()
    if ok == false then
        return 1 
    end
until ok == nil

if R:rename(opts["break"]) then
    print("Done with no errors.")
    return 0
end

local prompt = string.format("Done with %d errors. Show errors?", #R.errors)
if util.yesno(prompt, true) then
    for _, i in ipairs(R.errors) do
        local f = R[i]
        util.printf("%s - %s", f.path, f.err)
    end
end
return 1
