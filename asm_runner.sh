nasm -f elf64 -l func_MyPrintf.lst func_MyPrintf.s  
ld -s -o func_MyPrintf func_MyPrintf.o
./func_MyPrintf