/* Focused audit demonstration. The marked identifiers below contain Unicode. */
int password = 1;
int pаssword = 2;       // the second character of pаssword is Cyrillic U+0430
int lοgin = 3;          // the second character of lοgin is Greek U+03BF
int Δvalue = 4;         // non-ASCII identifier; requires review, not automatically a warning of intent
int safe​Name = 5;      // contains U+200B ZERO WIDTH SPACE inside the identifier bytes
/* Other configured invisibles in this comment: U+200C‌ U+200D‍ U+2060⁠ U+FEFF﻿ */
int main(void) {
    return password + pаssword + lοgin + Δvalue + safe​Name;
}
