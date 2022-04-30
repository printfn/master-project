#include <stdio.h>

int main(int argc, char *argv[]) {
    if (argc <= 1) {
        fprintf(stderr, "Usage: ./ascii-check <file...>\n");
        return 1;
    }
    int returncode = 0;
    for (int i = 1; i < argc; ++i) {
        FILE *file = fopen(argv[i], "rb");
        int line = 1;
        int col = 0;
        int charidx = 0;
        int ci;
        while ((ci = fgetc(file)) != EOF) {
            char ch = (char)ci;
            if (ch > 0x7e || (ch < 0x20 && ch != '\n' && ch != '\t')) {
                printf("%s: invalid char %02x at idx %i, line %i, col %i\n", argv[i], ci, charidx, line, col);
                returncode = 1;
            }
            ++charidx;
            ++col;
            if (ch == '\n') {
                ++line;
                col = 0;
            }
        }
        fclose(file);
    }
    return returncode;
}
