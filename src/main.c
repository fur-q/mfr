#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define OH_NO(e) do { fprintf(stderr, "FATAL: %s\n", e); return 1; } while (0)

int mfr_isfile(const char * path) {
    struct stat buf;
    int ok = lstat(path, &buf);
    if (ok == -1) 
        return -1;
    return S_ISREG(buf.st_mode);
}

int mfr_termwidth(void) {
    struct winsize w;
    int ok = ioctl(0, TIOCGWINSZ, &w);
    if (ok == -1)
        return -1;
    return w.ws_col;
}

void l_getargs(lua_State * L, int argc, const char ** argv) {
    int i;
    lua_newtable(L);
    for (i = 0; i < argc; i++) {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");
}

int l_require(lua_State * L, const char * k) {
    lua_getglobal(L, "require");
    lua_pushstring(L, k);
    if (lua_pcall(L, 1, 1, 1)) {
        return 1;
    }
    return 0;
}

int l_traceback(lua_State * L) {
    const char * msg;
    msg = lua_tostring(L, 1);
    if (!msg)
        return 0;
    luaL_traceback(L, L, msg, 1);
    return 1;
}

int main(int argc, const char ** argv) {
    lua_State * L = luaL_newstate();
    if (!L) 
        OH_NO("Error creating Lua state");
    luaL_openlibs(L);
    lua_pushcfunction(L, l_traceback);
    l_getargs(L, argc, argv);
    if (l_require(L, "main"))
        OH_NO(lua_tostring(L, -1));
    lua_close(L);
    return 0;
}
