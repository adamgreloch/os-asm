; mac1.asm - funkcja mac1, która oblicza wartość a + x * y modulo 2 do potęgi
; 128 i która w języku C ma deklarację: 
;   uint128_t mac1(uint128_t a, uint64_t x, uint64_t y);

global mac1

; Argumenty funkcji mac1:
;   rdi - a.lo
;   rsi - a.hi
;   rdx - x
;   rcx - y

mac1:
        mov     rax,rdx
        mul     rcx
        add     rax,rdi
        adc     rdx,rsi
        ret
