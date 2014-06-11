# mfr

A Lua-powered file renaming tool.

## Usage

Bread-and-butter usage:

    $ mfr -x -m "foo(%d+)" -r "bar%1" foo1.lua foo02.c
    $ ls
    bar1.lua    bar02.c

You're right, that does look boring. Here's something more exciting:

    $ cat bar1.lua
    return function(n)
        n = tonumber(n) * 2
        return string.format("foo%s%02d", s, n)
    end
    $ mfr -x -l bar1.lua "(.+)(%d+)$" bar1.lua bar02.c
    $ ls
    foobar02.lua foobar04.c

See [the manual](https://github.com/fur-q/mfr/blob/master/doc/mfr.pod) for more examples.

## Installation

You will need:

- A POSIX-compliant operating system (tested on Debian and FreeBSD)
- GNU make
- pkg-config
- LuaJIT and its dev libraries/headers (`libluajit-5.1-dev` on Debian)
- pod2man (if you care about having a man page)

All other dependencies are bundled in `contrib/`.

Run `make` for a release build or `make debug` for a debug build.

## License

See LICENSE.

## Credits

`mfr` would not be nearly as good without [linenoise](https://github.com/antirez/linenoise) and lua-stdlib's [optparse.lua](https://github.com/lua-stdlib/lua-stdlib/blob/master/lib/std/optparse.lua). So, thanks!

## TODO

- Line edit history
- More comprehensive tests

