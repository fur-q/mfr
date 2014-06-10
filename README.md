# mfr

A batch file renamer which uses Lua patterns.

## Installation

You will need:

- GNU make
- pkg-config
- LuaJIT and its dev libraries/headers (`libluajit-5.1-dev` on Debian)
- pod2man (if you care about having a man page)

All other dependencies are bundled in `contrib/`.

Run `make` for a release build or `make debug` for a debug build.

## Usage

See [the documentation](https://github.com/fur-q/mfr/doc/mfr.pod) or `mfr --help`.

## License

See LICENSE.

## Credits

`mfr` would not be nearly as good without [linenoise](https://github.com/antirez/linenoise) and lua-stdlib's [optparse.lua](https://github.com/lua-stdlib/lua-stdlib/blob/master/lib/std/optparse.lua). So, thanks!

## To do

- Line edit history
- More comprehensive tests

