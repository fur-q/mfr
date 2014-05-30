# mfr

A batch file renamer which uses Lua patterns.

# Installation

You will need:

- GNU make
- pkg-config
- LuaJIT and its dev libraries/headers (`libluajit-5.1-dev` on Debian)

All other dependencies are bundled in `contrib/`.

Run `make` for a release build or `make debug` for a debug build.

# Usage

`mfr --help` or `man mfr`.

# License

See LICENSE.

# Credits

`mfr` would not be nearly as good without [linenoise](https://github.com/antirez/linenoise) and lua-stdlib's [optparse.lua](https://github.com/lua-stdlib/lua-stdlib/blob/master/lib/std/optparse.lua). So, thanks!

# To do

There are no tests, the manpage sucks and there is no install target in the makefile. Boo hoo.
