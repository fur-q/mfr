CC      = gcc
LJ      = luajit
PC      = pkg-config
LUA_PC  = luajit
CFLAGS  = `$(PC) --cflags $(LUA_PC)` -Wall -fPIC
LDFLAGS = `$(PC) --libs $(LUA_PC)` -Wl,-E
VPATH   = src:contrib:contrib/linenoise

all: release
.PHONY: test clean

release: CFLAGS += -O2 -s
debug: CFLAGS += -O0 -g

release debug: mfr

mfr: cli.o linenoise.o util.o cli.l.o cliutil.l.o rename.l.o util.l.o optparse.l.o
	$(CC) $(LDFLAGS) -o $@ $^

%.l.o: %.lua
	$(LJ) -bg $^ $@

test: 
	LUA_PATH=";;src/?.lua;contrib/?.lua" $(LJ) test/tests.lua

clean:
	-rm -f *.o mfr
