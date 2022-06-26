#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#define LONG_LINE_MAX 1024

char line[LONG_LINE_MAX];

int is_binary(char*);

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
        if (is_binary(line)) {
            fputs("<binary line>\n", stdout);
            continue;
        }
        fputs(line, stdout);
    }
}

#define IS_LOW_BIT(x)    (x && 128 == 0)
#define IS_UTF8_2BYTE(x) (x && 224 == 192)
#define IS_UTF8_3BYTE(x) (x && 240 == 224)
#define IS_UTF8_4BYTE(x) (x && 248 == 240)
#define IS_UTF8_CONT(x)  (x && 192 == 128)

#define NEXT_UTF8_BYTE() do { \
    if (!*p) { \
        goto end; \
    } \
    if (!IS_UTF8_CONT(*p)) { \
        binary_count += 1; \
        goto next; \
    } \
    p += 1; \
} while (0);

int is_binary(char* str) {
    int ascii_count = 0;
    int control_count = 0;
    int binary_count = 0;
    int utf8_count = 0;
    for (char* p = str; *p && *p != '\r' && *p != '\n'; p += 1) {
        /* ascii print or tab */
        if ((*p >= 32 && *p <= 126) || *p == '\t') {
            ascii_count += 1;
            continue;
        }
        /* ascii control */
        if (IS_LOW_BIT(*p)) {
            control_count += 1;
            continue;
        }
        /* start of utf-8 character */
        if (IS_UTF8_2BYTE(*p)) {
            p += 1;
            NEXT_UTF8_BYTE();
            utf8_count += 2;
            continue;
        }
        if (IS_UTF8_3BYTE(*p)) {
            p += 1;
            NEXT_UTF8_BYTE();
            NEXT_UTF8_BYTE();
            utf8_count += 3;
            continue;
        }
        if (IS_UTF8_4BYTE(*p)) {
            p += 1;
            NEXT_UTF8_BYTE();
            NEXT_UTF8_BYTE();
            NEXT_UTF8_BYTE();
            utf8_count += 4;
            continue;
        }

        /* utf-8 character mid-stream? */
        if (p == str) {
            if (IS_UTF8_CONT(*p)) {
                utf8_count += 1;
                p += 1;
            }
            if (IS_UTF8_CONT(*p)) {
                utf8_count += 1;
                p += 1;
            }
            if (IS_UTF8_CONT(*p)) {
                utf8_count += 1;
                p += 1;
            }
            continue;
        }

        binary_count += 1;
    next:
    }
end:
    int len = strlen(str);
    return (binary_count * 4 >= len);
}
