CC      = gcc
LJ      = luajit
PC      = pkg-config
CFLAGS  = `$(PC) --cflags luajit` -Wall -fPIC
LDFLAGS = `$(PC) --libs luajit` -Wl,-E
VPATH   = src:contrib:contrib/linenoise

all: release

release: CFLAGS += -O2 -s
debug: CFLAGS += -O0 -g

release debug: mfr

mfr: cli.o cliutil.o linenoise.o cli.l.o cliutil.l.o rename.l.o util.l.o optparse.l.o
	$(CC) $(LDFLAGS) -o $@ $^

%.l.o: %.lua
	$(LJ) -bg $^ $@

.PHONY: test clean

test: 
	LUA_PATH=";;src/?.lua;contrib/?.lua" $(LJ) test/tests.lua

clean:
	-rm -f *.o mfr
