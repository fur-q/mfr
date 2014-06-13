#include <stdio.h>
#include <sys/ioctl.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define DIE(e) do { fprintf(stderr, "FATAL: %s\n", e); return 1; } while (0)

int mfr_termwidth(void) {
    struct winsize w;
    int ok = ioctl(0, TIOCGWINSZ, &w);
    if (ok == -1)
        return -1;
    return w.ws_col;
}

static void l_getargs(lua_State * L, int argc, const char ** argv) {
    int i;
    lua_newtable(L);
    for (i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

static int l_require(lua_State * L, const char * k) {
    lua_getglobal(L, "require");
    lua_pushstring(L, k);
    if (lua_pcall(L, 1, 1, 1)) {
        return 1;
    }
    return 0;
}

static int l_traceback(lua_State * L) {
    const char * msg = lua_tostring(L, 1);
    if (!msg)
        return 0;
    luaL_traceback(L, L, msg, 1);
    return 1;
}

int main(int argc, const char ** argv) {
    lua_State * L = luaL_newstate();
    if (!L) 
        DIE("Error creating Lua state");
    luaL_openlibs(L);
    lua_pushcfunction(L, l_traceback);
    l_getargs(L, argc, argv);
    if (l_require(L, "mfr_internal.cli"))
        DIE(lua_tostring(L, -1));
    lua_close(L);
    return 0;
}
