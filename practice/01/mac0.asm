; mac0.asm - funkcja mac0, która oblicza wartość a + x * y modulo 2 do potęgi
; 64 i która ma w języku C deklarację:
;   uint64_t mac0(uint64_t a, uint64_t x, uint64_t y);

global mac0

; Argumenty funkcji mac0:
;   rdi - wartość a
;   rsi - wartość x
;   rdx - wartość y

mac0:
        imul    rsi,rdx
        lea     rax,[rdi + rsi]   ; Kalkulacja sumy zawartości rejestrów rdi,rsi
                                  ; wykonywana jest przez układ adresujący
        ret                       ; Wynik powinien być w rejestrze rax
