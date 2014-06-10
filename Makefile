CC      = gcc
PC      = pkg-config
LUA     = luajit
LUA_PC  = luajit
CFLAGS  = `$(PC) --cflags $(LUA_PC)` -Wall -fPIC
LDFLAGS = `$(PC) --libs $(LUA_PC)` -Wl,-E
VPATH   = src:contrib:contrib/linenoise
BINDIR  = /usr/local/bin
MANDIR  = /usr/local/man

all: release
release: CFLAGS += -O2 -s
debug: CFLAGS += -O0 -g
release debug: mfr
.PHONY: test clean

mfr: cli.o linenoise.o util.o cli.l.o cliutil.l.o rename.l.o util.l.o optparse.l.o
	$(CC) $(LDFLAGS) -o $@ $^

%.l.o: %.lua
	$(LUA) -bg $^ $@

doc/mfr.1: doc/mfr.pod
	pod2man -c "" -n MFR -r "" -s 1 $^ $@

install: mfr doc/mfr.1
	install mfr $(BINDIR)
	-install doc/mfr.1 $(MANDIR)/man1

test: 
	LUA_PATH=";;src/?.lua;contrib/?.lua" $(LJ) test/tests.lua

clean:
	-rm -f *.o mfr
