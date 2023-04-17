global core
extern get_value
extern put_value

%macro backup_data 0
        push    rbx
        push    rdi
        push    rsi
%endmacro

%macro restore_dealign 0
        add     rsp,rbx
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
prev_rsp:                       ; zmienna na wartość rsp sprzed wywołania core
        resq    1
s_wait:                         ; tablica rozmiaru N na cel operacji S
        resq    N
bufs:                           ; N buforów do wymiany wartościami między rdzeniami podczas
        resq    N               ; operacji S

section .text

core:
; Argumenty funkcji core:
;       rdi - wartość n
;       rsi - wskaźnik p na napis definiujący obliczenie

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

        cmp     al,'0'
        jl      .end
        cmp     al,'9'
        jg      .end

        jmp     .op_val

.end:
        mov     rsp,[rel prev_rsp]
        ret

.next_read:
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
        jnz     .op_B_opjump
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
        call    get_value       ; w rdi już znajduje się liczba n
        restore_dealign
        push    rax
        jmp     .next_read
.op_P:
        pop     r8              ; zdejmij wartość w
        backup_data
        mov     rsi,r8          ; umieść w jako drugi argument funkcji put_value
        align_stack
        call    put_value       ; w rdi już znajduje się liczba n
        restore_dealign
        push    rax
        jmp     .next_read
.op_val:
        sub     al,'0'
        push    ax
        jmp     .next_read

.op_S:
;*****************************************************************************************
; Operacja S
;
; Protokół synchronizacji i wymiany między rdzeniami a oraz b, gdzie a < b.
;
; Rdzeń a (protokół A):
; 1. Zdejmij numer rdzenia m ze stosu.
; 2. Umieść w bufs[a] wartość z wierzchołka własnego stosu.
; 3. Skoro a < b, ustaw s_wait[a] na b i czekaj, aż s_wait[b] == a.
; 4. Gdy s_wait[b] == a, zabierz ze bufs[b] wartość i umieść na stosie.
; 5. Ustaw s_wait[a] = 0
; 6. Zakończ operację S.
;
; Rdzeń a (protokół B):
; 1. Zdejmij numer rdzenia n ze stosu.
; 2. Umieść w bufs[b] wartość z wierzchołka stosu
; 3. Skoro b > a, to czekaj, aż s_wait[a] == b
; 4. Jeśli s_wait[a] == b, zabierz ze bufs[a] wartość, wstaw na swój stos.
; 5. Ustaw s_wait[b] == a i czekaj, aż s_wait[a] == 0
; 6. Gdy s_wait[a] == 0, ustaw s_wait[b] = 0
; 7. Zakończ operację S.
;*****************************************************************************************

        pop     rcx                     ; zdejmij ze stosu numer rdzenia m
        lea     r8,[rel bufs]           ; r8 -> wskaźnik do tablicy bufs
        lea     r9,[rel s_wait]         ; r9 -> wskaźnik do tablicy zmiennych warunkowych
        pop     qword [rdx + rdi]       ; przenieś do bufs[n] wartość wierzchołka stosu
        cmp     rdi,rcx                 ; porównaj numery rdzeniów n i m
        jg      .pr_B                   ; mając wyższy numer, wykonaj protokół B
.pr_A:                                  ; w.p.p. wykonuj protokół A
.pr_A_spin:
        mov     [r9 + rdi],rcx          ; ustaw s_wait[n] := m
        cmp     [r9 + rcx],rdi          ; czy można wykonać krok 4?
        jne     .pr_A_spin              ; skocz, jeśli s_wait[m] != n, czyli gdy nie można
        push    qword [r8 + rcx]        ; umieść bufs[m] na stosie
        mov     qword [r9 + rdi],0      ; ustaw s_wait[n] := 0
        jmp     .next_read
.pr_B:
.pr_B_spin1:
        cmp     [r9 + rcx],rdi          ; czy można wykonać krok 4?
        jne     .pr_B_spin1             ; skocz, jeśli s_wait[m] != n, czyli gdy nie można
        push    qword [r8 + rcx]        ; umieść bufs[m] na stosie
        mov     [r9 + rdi],rcx          ; ustaw s_wait[n] := m
.pr_B_spin2:
        cmp     qword [r9 + rcx],0      ; czy można wykonać krok 6?
        jne     .pr_B_spin2             ; skocz, jeśli s_wait[m] != 0, czyli gdy nie można
        mov     qword [r9 + rdi],0      ; ustaw s_wait[n] := 0
        jmp     .next_read

