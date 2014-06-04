local optparse = require "optparse"
local renamer  = require "rename"
local util     = require "cliutil"

local MFR_VERSION = "0.5.0"

local parser = optparse(string.format([[
mfr %s

Usage: %s [OPTION]... [FILE]...
Batch rename files using Lua patterns.

  -b, --break              stop processing after encountering an error
  -e, --no-extensions      don't match against or modify file extensions
  -m, --match=[PATTERN]    set filename match pattern
  -r, --replace=[STRING]   set filename replacement string
  -s, --source=[FILE]      match against lines from FILE instead of filenames
  -y, --yes                always answer yes at yes/no prompts
  -h, --help               show this help and exit
  -v, --version            show version information and exit

Report bugs at <http://github.com/fur-q/mfr>.
]], MFR_VERSION, arg[0]))

local args, opts = parser:parse(arg)

if not util.isatty(io.stdin) then
    for l in io.stdin:lines() do
        args[#args+1] = l
    end
    util.freopen("/dev/tty", "r", io.stdin)
end

if #args == 0 then
    parser:opterr("No filenames provided")
end

local R = renamer(unpack(args))
if #R == 0 then
    parser:opterr("No filenames provided")
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

local match, replace = opts.match, opts.replace

local function preview()
    match = match or util.prompt("Enter match pattern: ")
    replace = replace or util.prompt("Enter replace pattern: ")
    local count, err = R:match(match, replace, opts.no_extensions)
    if count == 0 then
        err = "Nothing to rename."
    end
    if err then
        print(err)
        return util.yesno("Retry?", true)
    end
    if not opts.yes then
        util.printf("Matched %d %s:", util.pluralise(count, "file"))
        util.preview(R) 
        return (not util.yesno("OK to rename?")) or nil
    end
end

local ok = true

repeat
    ok = preview()
    if ok == true then -- retry
        match, replace = nil, nil
    end
    if ok == false then -- quit
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
