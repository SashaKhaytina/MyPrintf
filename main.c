#include <stdio.h>

void test_print(); 
void MyPrintf(const char* format_string, ...);

int main()
{
    test_print();

    char string[20] = "STRING!";

    MyPrintf("I WORK: %% %b %d %c - symbols %% %s %c %o \n", 5, -123, 'B', string, 'A', 11);
}