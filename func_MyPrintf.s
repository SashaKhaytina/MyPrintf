;:================================================
;: 0-Linux-nasm-64.s                   (c)Ded,2012
;:================================================

; nasm -f elf64 -l 1-nasm.lst 1-nasm.s  ;  ld -s -o 1-nasm 1-nasm.o


;section .text

;global _start                  ; predefined entry point name for ld

;_start:     mov rax, 0x01      ; write64 (rdi, rsi, rdx) ... r10, r8, r9
;            mov rdi, 1         ; stdout
;            mov rsi, Msg
;            mov rdx, MsgLen    ; strlen (Msg)
;            syscall
;            
;            mov rax, 0x3C      ; exit64 (rdi)
;            xor rdi, rdi
;            syscall
            
;section     .data
            
;Msg:        db "__Hllwrld", 0x0a
;MsgLen      equ $ - Msg





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
;-------------------------------------------------


;----------------------------------------- CODE ---------------------------------------------------------------------------------

section .text

;global test_print
global _start

_start:     
            ;----------------DEBUG----------------
            call test_print
            ;-------------------------------------

            push 'B'             ; push "B"
            push 'A'
            push format_string
            call MyPrintf

            mov rax, 0x3C       ; exit64 (rdi)
            xor rdi, rdi        ; exit_code ( always 1 :) )
            syscall






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
;   r8  - pointer to format string                      (8 byte = 64 bit)
;   r9  - first elem                                    (8 byte = 64 bit)
;   r15 - buffer pointer                                (8 byte = 64 bit)
;   eax - variable for save symbol                      (4 byte = 32 bit) (while enough) translate: пока нам этого хватит
;   al  - variable for current symbol in format string  (1 byte = 4 bit ) (one char)
;==========================================================
MyPrintf:
            pop r14         ; give return code
            pop r8          ; pointer to format string
            ; Give elem we can in cycle? when we have %. Return code we can save in r14, and push it in the end of function 
            ;pop r9          ; first elem
            ;push r14        ; return code

            mov r15, buffer_1

            ; Это должно быть в while !!!!!!!

            _cycle_while_read_format_string:
                
                mov al, [r8]            ; current symb f_s -> al
                cmp al, 0x00            ; (form_str[r8] == '\0')
                je _stop_while_read_format_string ;jz- flag null

                ;cmp [spec_symb], [r8]   ; if (form_str[r8] != %) ([spec_symb] = ASCII("%"))  ???????????????????????????????????/
                cmp al, 0x25            ; if (form_str[r8] != %)
                jne _print_letter

                    ; (if (form_str[r8] == %))
                    _proc:
                        ;----------------DEBUG----------------
                        call test_print             ; DEUBG
                        ;-------------------------------------
                        inc r8                      ; pointer to format string ++ (next symbol)
                        mov al, [r8]                ; current symb f_s -> al

                        ;cmp [spec_symb], [r8]       ; (if (form_str[r8] == %))
                        cmp al, 0x25                ; if (form_str[r8] != %)
                        jne  _c                     ; next case

                        ;mov [r15], [spec_symb]      ; buf[r15] = "%"
                        mov [r15], al               ; buf[r15] = "%"
                        inc r15                     ; buffer pointer ++
                        inc r8                      ; pointer to format string ++

                        jmp _break


                    _c:
                        pop r9          ; first elem - 
                        ;----------------DEBUG----------------
                        call test_print             ; DEUBG 
                        ;-------------------------------------
                        
                        ;inc r8                      ; pointer to format string ++ (next symbol)
                        ;mov al, [r8]                ; current symb f_s -> al

                        ;cmp [spec_symb_c], [r8]     ; (if (form_str[r8] == c))
                        cmp al, 0x63                ; (if (form_str[r8] == c))
                        jne  _b                     ; next case

                        ;call test_print

                        ;----------------DEBUG----------------
                        cmp r9b, 66                 ; 'B's
                        jne METKA
                            call test_print         ; DEUBG (NO)
                        METKA:
                        ;-------------------------------------

                        mov [r15], r9b              ; buf[r15] = first elem (low byte) translate: младший байт, тк в r9 - 8 байт, а нам надо записать только 1 char
                        inc r15                     ; buffer pointer ++
                        inc r8                      ; pointer to format string ++

                        jmp _break


                    _b:
                        ;inc r8
                        ;mov al, [r8]                ; current symb f_s -> al

                        cmp al, 0x62     ; (if (form_str[r8] == b))
                        jne  _break                 ; last case

                        ; Тут надо в while брать остаток от 10, прибавлять 48 и запихивать в буффер.

                        jmp _break

                _break:
                jmp _cycle_while_read_format_string ; HERE jmp to start while

                _print_letter:
                    ;mov [r15], [r8]
                    mov [r15], al
                    inc r15                         ; buffer pointer ++
                    inc r8                          ; pointer to format string ++

                    jmp _cycle_while_read_format_string ; HERE jmp to start while
                

            _stop_while_read_format_string:
            ;add r8, 1
            ;mov [r15], spec_symb_nul                ; put in end buffer "\0" (null) (this is no need)


            call Write_Buffer                       ; call func write_buffer

            push r14        ; put return code

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
            mov rax, 1          ; write64 (rdi, rsi, rdx) ... r10, r8, r9
            mov rdi, 1          ; stdout (place where write)
            mov rsi, buffer_1
            
            sub r15, buffer_1
            mov rdx, r15        ; size (strlen)
            syscall             ; write buffer

            ret
            




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


format_string: db "I WORK: %% %c %c - symbols %%", 10, 0   ; format string

spec_symb:      db "%"                  ; ASCII("%")  = 0x25
spec_symb_b:    db "b"                  ; ASCII("b")  = 0x62
spec_symb_c:    db "c"                  ; ASCII("c")  = 0x63
spec_symb_nul:  db "\0"                 ; ASCII("\0") = 0x00

buffer_1: resb 128
;buffer_1:   dq 0                          ; 8 byte - (8 char) (very small..)
;buffer_2:   dq 0                          ; 8 byte - (8 char) (16 byte in sum)
;buffer_3:   dq 0                          ; 8 byte - (8 char) (24 byte in sum)
;buffer_4:   dq 0                          ; 8 byte - (8 char) (32 byte in sum)