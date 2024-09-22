#include <stdio.h>
#include <stdlib.h>

#define CHUNK_SIZE 1024 // Define the size of the chunk to read

void process_file(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        perror("Failed to open file");
        exit(EXIT_FAILURE);
    }

    // Skip the first 5 bytes
    if (fseek(file, 5, SEEK_SET) != 0) {
        perror("Failed to skip bytes");
        fclose(file);
        exit(EXIT_FAILURE);
    }

    unsigned int buffer[2];
    size_t bytesRead;
    while ((bytesRead = fread(buffer, sizeof(unsigned int), 2, file)) == 2) {
        printf("%u\t%u\n", buffer[0], buffer[1]);
    }

    if (ferror(file)) {
        perror("Error reading file");
    }

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return EXIT_FAILURE;
    }

    process_file(argv[1]);

    return EXIT_SUCCESS;
}
