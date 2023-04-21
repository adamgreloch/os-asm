global core
extern get_value
extern put_value

%macro backup_data 0
        push    rbx
        push    rdi
        push    rsi
        push    r8
%endmacro

%macro restore_dealign 0
        add     rsp,rbx
        pop     r8
        pop     rsi
        pop     rdi
        pop     rbx
%endmacro

%macro align_stack 0
        mov     rbx,rsp
        and     rbx,15          ; oblicz rsp % 16 jako rsp & (16 - 1)
        sub     rsp,rbx         ; wyrównaj stos, gdyż (rsp - rsp % 16) % 16 == 0
%endmacro

section .bss
bufs:                           ; N buforów do wymiany wartościami między rdzeniami podczas
        resq    N               ; operacji S

section .data
s_wait:                         ; tablica rozmiaru N na cel operacji S
        times N dq N

section .text

; Argumenty funkcji core:
;       rdi - wartość n
;       rsi - wskaźnik p na napis definiujący obliczenie
core:
        mov     r8,rsp

.read_loop:
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

        cmp     al,'0'
        jl      .end
        cmp     al,'9'
        jg      .end

        jmp     .op_val

.end:
        pop     rax
        mov     rsp,r8
        ret

.next_read:
        inc     rsi
        jmp     .read_loop

.op_plus:
        pop     rax
        add     [rsp],rax
        jmp     .next_read

.op_star:
        pop     rax
        pop     rdx
        imul    rax,rdx
        push    rax
        jmp     .next_read
        
.op_neg:
        neg     qword [rsp]
        jmp     .next_read

.op_n:
        push    rdi
        jmp     .next_read

.op_B:
        pop     rax
        pop     rdx
        test    rdx,rdx
        push    rdx
        jnz     .op_B_opjump
        jmp     .next_read

.op_B_opjump:
        add     rsi,rax
        jmp     .next_read

.op_C:
        pop     rax
        jmp     .next_read

.op_D:
        push    qword [rsp]
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
        call    get_value       ; w rdi już znajduje się liczba n
        restore_dealign
        push    rax
        jmp     .next_read
.op_P:
        pop     r9              ; zdejmij wartość w
        backup_data
        mov     rsi,r9          ; umieść w jako drugi argument funkcji put_value
        align_stack
        call    put_value       ; w rdi już znajduje się liczba n
        restore_dealign
        push    rax
        jmp     .next_read
.op_val:
        sub     al,'0'
        movsx   rax,al
        push    rax
        jmp     .next_read

.op_S:
;*****************************************************************************************
; Operacja S
;
; Protokół synchronizacji i wymiany między rdzeniami a oraz b, gdzie a < b.
;
; Rdzeń a (protokół A):
; 1. Zdejmij numer rdzenia m ze stosu.
; 2. Umieść w bufs[a] wartość z wierzchołka własnego stosu, ustaw s_wait[a] na b
; 3. Czekaj, aż s_wait[b] == a.
; 4. Gdy s_wait[b] == a, zabierz ze bufs[b] wartość i umieść na stosie.
; 5. Ustaw s_wait[a] = N i czekaj, aż s_wait[b] == N
; 6. Zakończ operację S.
;*****************************************************************************************

        pop     rdx                     ; zdejmij ze stosu numer rdzenia m
        lea     rcx,[rel bufs]          ; rcx -> wskaźnik do tablicy bufs
        lea     r9,[rel s_wait]         ; r9 -> wskaźnik do tablicy zmiennych warunkowych
        pop     qword [rcx + 8*rdi]     ; przenieś do bufs[n] wartość wierzchołka stosu
        mov     [r9 + 8*rdi],rdx        ; ustaw s_wait[n] := m
.spin1:
        cmp     [r9 + 8*rdx],rdi        ; sprawdź, czy s_wait[m] == n
        jne     .spin1                  ; jeśli nie, czekaj
        push    qword [rcx + 8*rdx]     ; jeśli tak, bufs[m] już gotowe - umieść je na stosie
        mov     qword [r9 + 8*rdx],N    ; ustaw s_wait[m] := N
.spin2:
        cmp     qword [r9 + 8*rdi],N    ; sprawdź, czy s_wait[n] == N
        jne     .spin2                  ; jeśli nie, czekaj, aż m odbierze
        jmp     .next_read              ; jeśli tak, zakończ operację

