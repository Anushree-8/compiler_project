#include <stdio.h>

int main(void) {
    int total = 0;
    const char *quoted = "text with // and /* markers, plus an escaped quote: \"";
    char mark = ';';
    // A line comment ends at this newline; punctuation here is comment text: { } ;
    total += 1;

    /* This block comment spans several physical lines.
       It contains braces { }, operators + - *, quotes " and punctuation ;.
       A safe chunk boundary must not make these comment characters into tokens.
       The comment ends here: */
    total += 2;
    printf("%s %c %d\n", quoted, mark, total);
    return total;
}
