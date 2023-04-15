global core
extern get_value
extern put_value

%macro backup_data
        push    rbx
        push    rdi
        push    rsi
%endmacro

%macro restore_dealign
        add     rsp,rbx
        pop     rsi
        pop     rdi
        pop     rbx
%endmacro

%macro align_stack
        mov     rbx,rsp
        and     rbx,15          ; oblicz rsp % 16 jako rsp & (16 - 1)
        dec     rsp,rbx         ; wyrównaj stos, gdyż (rsp - rsp % 16) % 16 == 0
%endmacro

; Argumenty funkcji core:
;       rdi - wartość N
;       rsi - wskaźnik p na napis definiujący obliczenie

section .data
prev_rsp: dq 0

section .text

core:
.read_loop:
        mov     [rel prev_rsp],rsp
        mov     al,[rsi]        ; odczyt pierwszego znaku napisu
        cmp     al,'+'
        je      .op_plus

        cmp     al,'*'
        je      .op_star

        cmp     al,'-'
        je      .op_neg

        cmp     al,'n'
        je      .op_n

        cmp     al,'B'
        je      .op_B

        cmp     al,'C'
        je      .op_C

        cmp     al,'D'
        je      .op_D

        cmp     al,'E'
        je      .op_E

        cmp     al,'G'
        je      .op_G

        cmp     al,'P'
        je      .op_P

        cmp     al,'S'
        je      .op_S

        cmp     al,'\0'
        jne     .op_val
        
        mov     rsp,[rel prev_rsp]
        ret

.next_read
        inc     rdi
        jmp     .read_loop

.op_plus:
        pop     rax
        pop     rdx
        add     rax,rdx
        push    rax
        jmp     .next_read

.op_star:
        pop     rax
        pop     rdx
        imul    rax,rdx
        push    rax
        jmp     .next_read
        
.op_neg:
        pop     rax
        neg     rax
        push    rax
        jmp     .next_read

.op_n:
        push    rdi
        jmp     .next_read

.op_B:
        pop     rax
        pop     rdx
        test    rdx,rdx
        jnz     .op_B_opjump:
        push    rdx
        jmp     .next_read

.op_B_opjump:
        neg     rax
        sub     rsi,rax
        jmp     .next_read

.op_C:
        pop     rax
        jmp     .next_read

.op_D:
        pop     rax
        push    rax
        push    rax
        jmp     .next_read

.op_E:
        pop     rax
        pop     rdx
        push    rax
        push    rdx
        jmp     .next_read

.op_G:
        backup_data
        align_stack
        call    get_value       ; w rdi już znajduje się liczba N
        restore_dealign
        push    rax
.op_P:
        pop     r8              ; zdejmij wartość w
        backup_data
        mov     rsi,r8          ; umieść w jako drugi argument funkcji put_value
        align_stack
        call    put_value       ; w rdi już znajduje się liczba N
        restore_dealign
        push    rax
.op_S:
.op_val:

; vim: sw=8 ts=8 tw=90
