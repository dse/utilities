#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#define LONG_LINE_MAX 1024

char line[LONG_LINE_MAX];

int main(int argc, char** argv) {
    char* s;
    size_t i;
    int long_line_flag = 0;
    while (1) {
        s = fgets(line, LONG_LINE_MAX, stdin);
        if (!s) {
            if (feof(stdin)) {
                break;
            }
            perror("exlong");
        }
        i = strlen(line);
        if (i) {
            if (line[i-1] != '\n') {
                if (!long_line_flag) {
                    fputs("<long line>\n", stdout);
                }
                long_line_flag = 1;
                continue;
            }
            if (long_line_flag) {
                long_line_flag = 0;
                continue;
            }
        }
        fputs(line, stdout);
    }
}
