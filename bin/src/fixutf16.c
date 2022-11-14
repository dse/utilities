#include <stdio.h>
#include <unistd.h>

#define BYTES 16384

int main(int argc, char** argv) {
    freopen(NULL, 'rb', stdin);
    freopen(NULL, 'wb', stdout);
    char data_buf[bytes + 2];
    size_t data_buf_offset = 0;
    size_t bytes_to_read = BYTES + 2;
    int end_of_file;
    while (1) {
        ssize_t bytes_read = read(fileno(stdin), data_buf, bytes_to_read);
        if (bytes_read == -1) {
            perror("stdin");
            exit(1);
        }
        if (bytes_read == 0) {
            break;
        }
        if (bytes_read < bytes_to_read) {
            end_of_file = 1;
        }
        size_t code_unit_count = bytes_read / 2;
        
    }
}
