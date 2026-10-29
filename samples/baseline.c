#include <stdio.h>

int main(void) {
    int count = 12;
    const char *message = "ordinary ASCII baseline";
    char grade = 'A';
    printf("%s %d %c\n", message, count, grade);
    return 0;
}
