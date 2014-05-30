CC      = gcc
LJ      = luajit
PC      = pkg-config
CFLAGS  = `$(PC) --cflags luajit` -Wall -fPIC
LDFLAGS = `$(PC) --libs luajit` -Wl,-E
VPATH   = src:contrib:contrib/linenoise

all: release

release: CFLAGS += -O2 -s
release: mfr

debug: CFLAGS += -O0 -g
debug: mfr

test: mfr lpty.o test.o
	$(CC) $(LDFLAGS) -o $@ lpty.o test.o

mfr: main.o linenoise.o main.l.o rename.l.o util.l.o optparse.l.o
	$(CC) $(LDFLAGS) -o $@ $^

%.l.o: %.lua
	$(LJ) -bg $^ $@

clean:
	-rm -f *.o mfr
