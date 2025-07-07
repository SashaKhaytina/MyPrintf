;: 0-Linux-nasm-64.s  
;:================================================
;: func_MyPrintf.s                   (c)ALXnd,2025
;:================================================

;-------------------------------------------------
; HELP:
; При вызове функций C/C++ на Linux первые 6 параметров передаются последовательно через регистры RDI, RSI, RDX, RCX, R8 и R9
;
; 
; nasm -f elf64 -l func_MyPrintf.lst func_MyPrintf.s  
; ld -s -o func_MyPrintf func_MyPrintf.o 
; ЗДЕСЬ -s НЕ ДАЕТ РАБОТАТЬ GDB. Чтобы gdb работал компилируйте так:
; nasm -g -f elf64 -l func_MyPrintf.lst func_MyPrintf.s  
; ld -o func_MyPrintf func_MyPrintf.o
;-------------------------------------------------


;----------------------------------------- CODE ---------------------------------------------------------------------------------

section .text

global test_print
global MyPrintf
;global _start

;_start:     
            ;----------------DEBUG----------------
            ;call test_print
            ;-------------------------------------
            ;push 11
            ;push 'A'
            ;push print_string
            ;push 'B'             ; push "B"
            ;push -123
;            push 5
            ;push 12345
;            push format_string
;            call MyPrintf

;            mov rax, 0x3C       ; exit64 (rdi)
;            xor rdi, rdi        ; exit_code ( always 0 :) )
;            syscall














;==========================================================
; Moving_arguments
;--------------------------
; INFO:
;   Move all args in stack. (Move, because Calling Convention)
;--------------------------
; ENTRY: 
;   r9  - arg 6
;   r8  - arg 5
;   rcx - arg 4
;   rdx - arg 3
;   rsi - arg 2
;   rdi - arg 1
;--------------------------
; ENTER: NONE
;--------------------------
; DESTR: 
;   r10 - return code
;==========================================================
Moving_arguments:
            pop r10

            push r9
            push r8
            push rcx
            push rdx
            push rsi
            push rdi

            push r10

            ret











;==========================================================
; MyPrintf (&format_string, first_elem)
;--------------------------
; INFO:
;   Print <first_elem> to cmd in format (this format in format_string)
;
;   Want transform all to char (is is not good idea maybe, because ("%d", 12345) - 5 chars (5 bytes) in buffer, but size of NUM - 4 byte)
;   (When %d -> (num + 48) put in buffer and print all bytes like char)
;
;   Formats:
;       %d - integer (in development)
;       %c - char
;--------------------------
; ENTRY:
;   stack - &format_string  (8 byte = 64 bit)
;   stack - first_elem      (8 byte = 64 bit)
;--------------------------
; ENTER: NONE
;--------------------------
; DESTR:
;   r14 - return code
;   r12 - stack pointer before push args
;   r8  - pointer to format string                                          (8 byte = 64 bit)
;   r9  - first elem (from stack)                                           (8 byte = 64 bit)
;   r15 - buffer pointer                                                    (8 byte = 64 bit)
;   r13 - buffer end pointer                                                (8 byte = 64 bit)
;   al  - variable for current symbol in format string                      (1 byte = 4 bit ) (one char)
;         or current symb, that will put in buffer now (use in cycles)
;
;   Other regisrts used
;   r10 (CHANGE)
;   r11 (NO CHANGE)
;   edx (NO CHANGE)
;==========================================================
MyPrintf:

            pop r14                                 ; give return code
            mov r12, rsp

            call Moving_arguments

            pop r8                                  ; pointer to format string

            mov r15, buffer_1
            mov r13, end_buffer

            _cycle_while_read_format_string:
                
                mov al, [r8]                        ; current symb f_s -> al
                cmp al, 0x00                        ; (form_str[r8] == '\0')
                je _stop_while_read_format_string   ; jz- flag null

                cmp al, 0x25                        ; if (form_str[r8] != %)
                jne _print_letter

                    _proc:
                        ;----------------DEBUG----------------
                        ;call test_print             ; DEUBG
                        ;-------------------------------------
                        inc r8                      ; pointer to format string ++ (next symbol)
                        mov al, [r8]                ; current symb f_s -> al

                        cmp al, 0x25                ; if (form_str[r8] != %)
                        jne  _c                     ; next case


                        mov [r15], al               ; buf[r15] = "%"
                        inc r15                     ; buffer pointer ++
                        inc r8                      ; pointer to format string ++

                        cmp r15, r13
                        jne no_full_buffer_proc
                            call Write_Buffer
                        no_full_buffer_proc:

                        jmp _break


                    _c:
                        
                        cmp al, 0x63                ; (if (form_str[r8] == c))
                        jne  _d                     ; next case


                        pop r9                      ; first elem
                        
                        mov [r15], r9b              ; buf[r15] = first elem (low byte) translate: младший байт, тк в r9 - 8 байт, а нам надо записать только 1 char
                        inc r15                     ; buffer pointer ++
                        inc r8                      ; pointer to format string ++

                        cmp r15, r13
                        jne no_full_buffer_c
                            call Write_Buffer
                        no_full_buffer_c:

                        jmp _break


                    _d:
                        cmp al, 0x64                ; (if (form_str[r8] == d))
                        jne  _s                     ; next case                     
 

                        pop r9                      ; first elem

                        mov rbx, 10
                        call Translate_in_other_number_system

                        inc r8                      ; pointer to format string ++

                        jmp _break



                    _s:
                        cmp al, 0x73                ; (if (form_str[r8] == s))
                        jne  _b                     ; next case                     


                        pop r9                      ; first elem

                        push rax                    ; current symb, that will put in buffer now (use in cycles)
                        mov al, 10 
                        _read_and_write_string:     ; while (al != \0)
                            
                            mov al, [r9]            ; al = elem from string (will put to buffer)
                            inc r9                  ; next letter from string
                            cmp al, 0               ; (al == 0)?
                            je _end_read_string

                            mov [r15], al
                            inc r15

                            cmp r15, r13
                            jne no_full_buffer_s
                                call Write_Buffer
                            no_full_buffer_s:

                            jmp _read_and_write_string

                        _end_read_string:

                        pop rax

                        inc r8                      ; pointer to format string ++
                        jmp _break



                    _b:                             ; Only for pozitive numbers
                        cmp al, 0x62                ; (if (form_str[r8] == b))
                        jne  _o                     ; next case                     


                        pop r9                      ; first elem

                        mov rbx, 2
                        call Translate_in_other_number_system

                        inc r8                      ; pointer to format string ++

                        jmp _break



                    _o:
                        cmp al, 0x6f                ; (if (form_str[r8] == o))
                        jne  _break                 ; last case                     


                        pop r9                      ; first elem

                        mov rbx, 8
                        call Translate_in_other_number_system

                        inc r8                      ; pointer to format string ++

                        jmp _break



                _break:
                jmp _cycle_while_read_format_string ; HERE jmp to start while

                _print_letter:
                    mov [r15], al
                    inc r15                         ; buffer pointer ++
                    inc r8                          ; pointer to format string ++

                    cmp r15, r13
                    jne no_full_buffer_end
                        call Write_Buffer
                    no_full_buffer_end:

                    jmp _cycle_while_read_format_string ; HERE jmp to start while
                
                

            _stop_while_read_format_string:


            call Write_Buffer                       ; call func write_buffer

            _clear_stack:                           ; delete the extra registers (that no args)
                cmp r12, rsp
                jle _end_func
                    pop rax
                    jmp _clear_stack
            _end_func:
            push r14                                ; put return code

            ret






;==========================================================
; Translate_in_other_number_system
;--------------------------
; INFO:
;   Func, that translate num from 10 number system to any number system 
;   and print new number in buffer
;
;   (10 CC ->  rbx) 
;   
;   In r9 - number 10 CC. In rbx - new CC. This function print 
;   number in new CC in buffer. 
;   
;   ATTENTION:
;       1) If new CC is not 10, negative number is not translate correct.
;       2) If new CC bigger than 10, this func is no correct (11, 12, ...) (func works without letters)
;--------------------------
; ENTRY: 
;   r15 - buffer pointer (CHANGE)
;   r9  - number 10 CC
;   rbx - new CC
;--------------------------
; ENTER: NONE
;--------------------------
; DESTR: 
;   r9  - number 10 CC
;   r10 - pointer to help_buffer
;   r11 - pointer to end num in help_buffer (buffer with reverse num)       (8 byte = 64 bit)
;   r15 - buffer pointer                                                    (8 byte = 64 bit) (CHANGE)
;   eax - the quotient of division                                          (4 byte = 32 bit)
;   rbx - new CC
;   rdx - remainder of division
;==========================================================
Translate_in_other_number_system:
                        push r10                ; helper variable
                        push rax            
                        push rdx
                        push r11

                        mov r11, help_buffer
                                                ; while (num / <new_CC> != 0) { buffer.add( num % <new_CC>); num /= <new_CC>; }
                        mov eax, r9d
                        
                                                ; Processing negative numbers
                        cmp eax, 0
                        jge _positive_num
                            neg eax             ; eax = -eax
                        _positive_num:

                        parsing_num_new_CC:
                            mov r10d, ebx
                            cdq
                            idiv r10d           ; частное в eax, остаток в edx

                            add edx, 48
                            mov [r11], dl       ; low byte edx
                            inc r11             ; help buffer pointer ++

                            cmp eax, 0
                            jne parsing_num_new_CC

                        cmp r9d, 0
                        jge _no_negative_num
                            xor edx, edx
                            mov dl, 0x2d
                            mov [r11], dl           ; put '-' in buffer
                            inc r11
                        _no_negative_num:

                        mov r10, help_buffer
                        sub r11, 1

                        write_ans_new_CC:
                            cmp r10, r11
                            ja stop_write_new_CC
                            

                            mov al, [r11]
                            dec r11                 
                            mov [r15], al
                            inc r15

                            cmp r15, r13
                            jne no_full_buffer_new_CC
                                call Write_Buffer
                            no_full_buffer_new_CC:
                        
                            jmp write_ans_new_CC
                        stop_write_new_CC:

                        pop r11
                        pop rdx
                        pop rax
                        pop r10

                        ret






;==========================================================
; Write_Buffer
;--------------------------
; INFO:
;   Print buffer to cmd 
;--------------------------
; ENTRY: 
;   r15 - buffer pointer
;--------------------------
; ENTER: NONE
;--------------------------
; DESTR: NO NO NO Mister Fish
;==========================================================
Write_Buffer:
            push rax
            push rdi
            push rsi
            push rdx
            push r11 ; !!!
            push r10
            push r9
            push r8


            mov rax, 1          ; write64 (rdi, rsi, rdx) ... r10, r8, r9
            mov rdi, 1          ; stdout (place where write)
            mov rsi, buffer_1
            
            sub r15, buffer_1
            mov rdx, r15        ; size (strlen)
            syscall             ; write buffer

            mov r15, buffer_1

            pop r8
            pop r9
            pop r10
            pop r11
            pop rdx
            pop rsi
            pop rdi
            pop rax

            ret




;==========================================================
; DEBUG_FUNCTION
;==========================================================
test_print:     
            push rax
            push rdi
            push rsi
            push rdx

            mov rax, 1              ; write64 (rdi, rsi, rdx) ... r10, r8, r9
            mov rdi, 1              ; command
            mov rsi, test_string
            mov rdx, test_string_len


            syscall
            
            pop rdx
            pop rsi
            pop rdi
            pop rax

            ret


;----------------------------------------- DATA ---------------------------------------------------------------------------------

section .data

test_string:        db "I work!", 10    ; size of pointer - 8 byte
test_string_len:    equ $ - test_string


format_string: db "I WORK: %% %b", 10, 0   ; format string


print_string: db "STRING!", 0



;spec_symb:      db "%"                  ; ASCII("%")  = 0x25
;spec_symb_d:    db "d"                  ; ASCII("d")  = 0x64
;spec_symb_c:    db "c"                  ; ASCII("c")  = 0x63
;spec_symb_nul:  db "\0"                 ; ASCII("\0") = 0x00

help_buffer: resb 32                        ; 32 byte (max size int < 10^12) ; (max size bin(int) - 32 numbres) 

buffer_1: resb 128                          ; 128 byte
end_buffer:
;buffer_1:   dq 0                          ; 8 byte - (8 char) (very small..)
;buffer_2:   dq 0                          ; 8 byte - (8 char) (16 byte in sum)
;buffer_3:   dq 0                          ; 8 byte - (8 char) (24 byte in sum)
;buffer_4:   dq 0                          ; 8 byte - (8 char) (32 byte in sum)