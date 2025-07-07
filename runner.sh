nasm -g -f elf64 -l func_MyPrintf.lst func_MyPrintf.s -o func_MyPrintf.o
gcc -no-pie -Wall main.c func_MyPrintf.o -o MyPrintf            # отключили PIE с помощью -no-pie
./MyPrintf





# nasm -g -f elf64 -l func_MyPrintf.lst func_MyPrintf.s
# ld -o func_MyPrintf func_MyPrintf.o # ищет стартовую _start. Без нее ошибка

# gcc main.c func_MyPrintf.o -o MyPrintf # gcc по умолчанию создает исполняемые файлы PIE, а ld создает без PIE
# (PIE - Программа загружается по случайному адресу, и все адреса вычисляются относительно текущего положения программы) 
# # gcc main.c

