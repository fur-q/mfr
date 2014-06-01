#include <sys/stat.h>

int mfr_isfile(const char * path) {
    struct stat buf;
    int ok = lstat(path, &buf);
    if (ok == -1) 
        return -1;
    return S_ISREG(buf.st_mode);
}

