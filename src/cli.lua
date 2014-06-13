local optparse = require "mfr_internal.optparse"
local renamer  = require "mfr_internal.rename"
local util     = require "mfr_internal.cliutil"

local stdin, ipairs, print, sformat = io.stdin, ipairs, print, string.format

local MFR_VERSION = "0.9.0"

local parser = optparse(sformat([[
mfr %s

Usage: %s [OPTION]... [FILE]...
Batch rename files using Lua patterns.

  -c, --cautious           stop processing after encountering an error
  -l, --lua-script=[FILE]  replace using the lua script FILE (overrides -r)
  -m, --match=[PATTERN]    set filename match pattern
  -r, --replace=[STRING]   set filename replacement string
  -s, --source=[FILE]      match against lines from FILE instead of filenames
  -x, --no-extensions      don't match against or modify file extensions
  -y, --yes                always answer yes at yes/no prompts
  -h, --help               show this help and exit
  -v, --version            show version information and exit

If a pipe is connected to stdin, it is assumed to contain input filenames.

See the manual for more information on using --lua-script and --source.

Report bugs at <http://github.com/fur-q/mfr>.
]], MFR_VERSION, arg[0]))

local args, opts = parser:parse(arg)

if not util.isatty(stdin) then
    for l in stdin:lines() do
        args[#args+1] = l
    end
    util.freopen("/dev/tty", "r", stdin)
end

if #args == 0 then
    parser:opterr("No filenames provided")
end

local R = renamer(unpack(args))
if #R == 0 then
    parser:opterr("No filenames provided")
end

R.patt, R.repl = opts.match, opts.replace
R.cautious, R.noexts = opts.cautious, opts.no_extensions 

if opts.lua_script then
    local scr, err = util.read_input(opts.lua_script, "Enter Lua script:")
    if not scr then
        parser.opterr(err)
    end
    local err = R:loadscript(scr)
    if err then
        parser.opterr(err)
    end
end

if opts.source then
    local src, err = util.read_input(opts.source, "Enter source text:")
    if not src then
        parser.opterr(err)
    end
    R:loadsource(src)
end

-- TODO default to the last pattern used

repeat
    local ok = util.preview(R, opts.yes)
    if ok == true then -- retry
        R:reset()
    elseif ok == false then -- quit
        return 1 
    end
until ok == nil

if R:rename() then
    print("Done with no errors.")
    return 0
end

local prompt = sformat("Done with %d errors. Show errors?", #R.errors)
if util.yesno(prompt, true) then
    for _, i in ipairs(R.errors) do
        local f = R[i]
        util.printf("%s - %s", f.path, f.err)
    end
end
return 1
