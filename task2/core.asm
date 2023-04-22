global core
; Argumenty funkcji core:
;       rdi - wartość n
;       rsi - wskaźnik p na napis definiujący obliczenie

extern get_value
; Argumenty zewnętrznej funkcji get_value:
;       rdi - wartość n

extern put_value
; Argumenty zewnętrznej funkcji put_value:
;       rdi - wartość n
;       rsi - wartość do wstawienia

;*****************************************************************************************
; Makra przygotowujące do wywołań call
;
; Kolejność wywoływania: backup_data, align_stack, call, restore_dealign zapewnia zgodność
; z ABI oraz gwarantuje bezpieczeństwo danych w rejestrach rbx, rdi, rsi, r8.
;*****************************************************************************************

%macro backup_data 0
; Zapisuje poprzednie wartości używanych rejestrów na stosie.
        push    rbx
        push    rdi
        push    rsi
        push    r8
%endmacro

%macro align_stack 0
; Wyrównuje stos do wielokrotności 16. Przechowuje wartość o którą nastąpiło wyrównanie w
; rbx. Po wykonaniu tego makra, należy wykonać restore_dealign przed następnym wywołaniem
; call / wyjściem z funkcji.
        mov     rbx,rsp
        and     rbx,15          ; Oblicz rsp % 16 jako rsp & (16 - 1).
        sub     rsp,rbx         ; Wyrównaj stos, gdyż (rsp - rsp % 16) % 16 == 0.
%endmacro

%macro restore_dealign 0
; Przywraca wskaźnik stosu do wartości sprzed align_stack. Przywraca poprzednie wartości
; używanych rejestrów na stosie.
        add     rsp,rbx
        pop     r8
        pop     rsi
        pop     rdi
        pop     rbx
%endmacro

section .bss
bufs: resq N                    ; N buforów do wymiany wartościami między rdzeniami
                                ; podczas operacji S.

section .data
s_wait: times N dq N            ; N blokad na potrzebę synchronizacji podczas operacji S.

section .text
core:
        mov     r8,rsp          ; Przechowaj poprzednią wartość rsp (przywracana w .end).

.read_loop:
;*****************************************************************************************
; Pętla wczytywania argumentów
; 
; Wczytuje kolejny znak z sekwencji wskazywanej przez rsi, porównuje ze znakami
; powiązanymi z poszczególnymi operacjami i przeskakuje do odpowiadającej operacji.
; W przypadku braku dopasowania (np. w wyniku wczytania '\0'), wychodzi z pętli i kończy
; program.
;*****************************************************************************************
        mov     al,[rsi]        ; Odczytaj następny znak z sekwencji.

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
        jl      .end            ; Jeśli numer znaku < '0', wyjdź z pętli.
        cmp     al,'9'
        jg      .end            ; Jeśli numer znaku > '9', wyjdź z pętli.

        jmp     .op_val

.end:                           ; Procedura kończąca funkcję.
        pop     rax
        mov     rsp,r8          ; Przywróć wartość rejestru rsp sprzed wywołania core.
        ret

.next_read:                     ; Procedura wykonywana po wykonaniu każdej z poniższych
                                ; procedur.
        inc     rsi             ; Przejdź do następnego znaku w sekwencji.
        jmp     .read_loop

.op_plus:                       ; Procedura implementująca operację '+'.
;*****************************************************************************************
; Operacja '+'
;
; Zdejmuje wierzchołek stosu i dodaje jego wartość do nowego wierzchołka stosu.
;*****************************************************************************************
        pop     rax
        add     [rsp],rax
        jmp     .next_read

.op_star:
;*****************************************************************************************
; Operacja '*'
;
; Zdejmuje dwie wartości ze stosu, mnoży je ze znakiem i wstawia wynik na stos.
;*****************************************************************************************
        pop     rax
        pop     rdx
        imul    rax,rdx
        push    rax
        jmp     .next_read
        
.op_neg:
;*****************************************************************************************
; Operacja '-'
;
; Neguje arytmetycznie wierzchołek stosu.
;*****************************************************************************************
        neg     qword [rsp]
        jmp     .next_read

.op_n:
;*****************************************************************************************
; Operacja n
;
; Wstawia na stos numer rdzenia.
;*****************************************************************************************
        push    rdi             ; Wstaw na stos numer rdzenia trzymany w rdi.
        jmp     .next_read

.op_B:
;*****************************************************************************************
; Operacja B
;
; Zdejmuje wierzchołek stosu. Jesli teraz wierzchołkiem jest liczba różna od zera,
; traktuje zdjętą wartość jako liczbę U2 i przesuwa wskaźnik sekwencji o tą wartość.
;*****************************************************************************************
        pop     rax
        pop     rdx
        test    rdx,rdx         ; Czy rdx == 0?
        push    rdx
        jnz     .op_B_opjump    ; Jeśli nie, dodaj do wskaźnika sekwencji wartość rax,
        jmp     .next_read      ; w.p.p. zakończ operację nie robiąc nic.
.op_B_opjump:
        add     rsi,rax
        jmp     .next_read

.op_C:
;*****************************************************************************************
; Operacja C
;
; Zdejmuje wierzchołek stosu i go porzuca.
;*****************************************************************************************
        pop     rax
        jmp     .next_read

.op_D:
;*****************************************************************************************
; Operacja D
;
; Duplikuje wierzchołek stosu.
;*****************************************************************************************
        push    qword [rsp]     
        jmp     .next_read

.op_E:
;*****************************************************************************************
; Operacja E
;
; Zdejmuje dwie wartości ze stosu i wstawia je w odwrotnej kolejności.
;*****************************************************************************************
        pop     rax
        pop     rdx
        push    rax
        push    rdx
        jmp     .next_read

.op_G:
;*****************************************************************************************
; Operacja G
;
; Wywołaj get_value. Wstaw wynik funkcji get_value na stos. Zawartość rejestrów rdi, rsi,
; r8 pozostaje bez zmian przed i po wywołaniu operacji G. Zakłada, że w rdi już znajduje
; się liczba n (pierwszy argument get_value). Korzysta z makr wspomagających zgodność z
; ABI.
;*****************************************************************************************
        backup_data
        align_stack
        call    get_value
        restore_dealign
        push    rax
        jmp     .next_read

.op_P:
;*****************************************************************************************
; Operacja P
;
; Wywołuje put_value. Zawartość rejestrów rdi, rsi, r8 pozostaje bez zmian przed i po
; wywołaniu operacji G. Zakłada, że w rdi już znajduje się liczba n (pierwszy argument
; put_value). Korzysta z makr wspomagających zgodność z ABI.
;*****************************************************************************************
        pop     r9              ; Zdejmij wartość w ze stosu.
        backup_data
        mov     rsi,r9          ; Umieść w do rsi jako drugi argument funkcji put_value.
        align_stack
        call    put_value
        restore_dealign
        jmp     .next_read

.op_val:
;*****************************************************************************************
; Operacja 0-9
;
; Wstawia na stos liczbę z przedziału [0,9]. Zakłada, że w al znajduje się znak
; reprezentujący którąś z tych liczb.
;*****************************************************************************************
        sub     al,'0'          ; Otrzymaj wartość liczbową znaku, korzystając z
                                ; uporządkowania znaków ASCII.
        movsx   rax,al          ; Rozszerz wartość do liczby 64 bitowej.
        push    rax
        jmp     .next_read

.op_S:
;*****************************************************************************************
; Operacja S
;
; Wymienia wierzchołki stosu między rdzeniami n i m. Protokół synchronizacji-wymiany
; między rdzeniami n i m z perspektywy rdzenia n:
; 1. Zdejmij numer rdzenia m ze stosu.
; 2. Umieść w bufs[a] wartość z wierzchołka własnego stosu, ustaw s_wait[a] na b
; 3. Czekaj, aż s_wait[b] == a.
; 4. Gdy s_wait[b] == a, zabierz ze bufs[b] wartość i umieść na stosie.
; 5. Ustaw s_wait[b] = N i czekaj, aż s_wait[a] == N
; 6. Zakończ operację S.
;*****************************************************************************************
        pop     rdx                     ; Zdejmij ze stosu numer rdzenia m.
        lea     rcx,[rel bufs]          ; rcx -> wskaźnik do tablicy bufs
        lea     r9,[rel s_wait]         ; r9 -> wskaźnik do tablicy zmiennych warunkowych
        pop     qword [rcx + 8*rdi]     ; Przenieś do bufs[n] wartość wierzchołka stosu.
        mov     [r9 + 8*rdi],rdx        ; Ustaw s_wait[n] := m.
.spin1:
        cmp     [r9 + 8*rdx],rdi        ; Sprawdź, czy s_wait[m] == n.
        jne     .spin1                  ; Jeśli nie, czekaj,
        push    qword [rcx + 8*rdx]     ; w.p.p. można wstawiać bufs[m] na stos.
        mov     qword [r9 + 8*rdx],N    ; Ustaw s_wait[m] := N.
.spin2:
        cmp     qword [r9 + 8*rdi],N    ; Sprawdź, czy s_wait[n] == N.
        jne     .spin2                  ; Jeśli nie, czekaj, aż m odbierze,
        jmp     .next_read              ; w.p.p. zakończ operację.

