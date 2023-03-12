; mac2.asm - funkcja mac2, która do liczby wskazywanej przez a dodaje iloczyn
; liczb wskazywanych przez x i y (modulo 2 do potęgi 128) i która w języku C ma
; deklarację:
;   void mac2(uint128_t *a, uint128_t const *x, uint128_t const *y);

global mac2

; Argumenty funkcji mac2:
;   rdi - wskaźnik do a
;   rsi - wskaźnik do x
;   rdx - wskaźnik do y
;
; stąd:
;   [rdi] - a.lo, [rdi + 8] - a.hi
;   [rsi] - x.lo, [rsi + 8] - x.hi
;   [rdx] - y.lo, [rdx + 8] - y.hi

mac2:
        mov     rcx,[rdx]         ; y.lo
        mov     rax,[rsi + 8]     ; x.hi
        imul    rax,rcx           ; Mnożenie y.lo przez x.hi, wynik w rax
        add     [rdi + 8],rax     ; Dodaj wynik imul do a.hi
        mov     rdx,[rdx + 8]     ; y.hi
        mov     rax,[rsi]         ; x.lo (potrzebne do mul)
        imul    rdx,rax           ; Mnożenie x.lo przez y.hi, wynik w rdx
        add     [rdi + 8],rdx     ; Dodaj wynik imul do a.hi
        mul     rcx               ; Mnożenie x.lo przez y.lo (wynik w rdx:rax)
        add     [rdi], rax        ; Dodawanie rax do a.lo
        adc     [rdi + 8], rdx    ; Dodawanie rdx do a.hi
        ret                       ; Wynik jest w a.hi:a.lo
