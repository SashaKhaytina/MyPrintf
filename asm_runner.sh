nasm -g -f elf64 -l func_MyPrintf.lst func_MyPrintf.s  
ld -o func_MyPrintf func_MyPrintf.o
./func_MyPrintf