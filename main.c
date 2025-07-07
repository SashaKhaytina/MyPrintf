#include <stdio.h>

void test_print(); // asm function
void MyPrintf(const char* format_string, ...);

int main()
{
    test_print();

    char strin[20] = "STRING!";

    MyPrintf("I WORK: %% %b %d %c - symbols %% %s %c %o \n", 5, -123, 'B', strin, 'A', 11);
}