global inverse_permutation

; Argumenty funkcji inverse_permutation:
;   rdi - wartość n
;   rsi - n-elementowa tablica p nieujemnych liczb całkowitych

inverse_permutation:
;*****************************************************************************************
; Sprawdzanie poprawności wartości n
;
; Poniższe instrukcje sprawdzają, czy wartość n jest poprawna, tzn. czy jest w przedziale
; [0, 2^31 + 1]. Jeśli to prawda, program przeskakuje do etykiety .check_range_init. W
; przeciwnym razie, skacze do .ret_false.
;*****************************************************************************************
.check_n:
        test    rdi,rdi                 ; Sprawdź, czy n == 0
        jz      .ret_false              ; Jeśli tak, to zwróć false
        bt      rdi,31                  ; Sprawdź, czy n <= 2^31 + 1
        jnc     .check_range_init       ; Jeśli tak, to kontynuuj. w.p.p. zwróć false

.ret_false:                             ; Zwróć false
        xor     eax,eax
        ret

;*****************************************************************************************
; Sprawdzenie zawartości tablicy p pod kątem zakresu liczb
;
; Poniższe instrukcje sprawdzają, czy liczby w tablicy p są z zakresu [0, n-1]. Jeśli to
; prawda, program kontynuuje wykonywanie instrukcji spod etykiety .dups_loop_init. W
; przeciwnym razie skacze do .ret_false.
;*****************************************************************************************
.check_range_init:
        mov     ecx,edi                 ; ecx -> i := n (licznik pętli)
.check_range_loop:
        cmp     [rsi+4*rcx-4],edi
        jae     .ret_false              ; Jeśli p[i] >= n, to p nie jest permutacją.
        cmp     dword [rsi+4*rcx-4],0
        jb      .ret_false              ; Jeśli p[i] < 0, to p nie jest permutacją.
        loop    .check_range_loop

;*****************************************************************************************
; Sprawdzenie poprawności tablicy p pod kątem duplikatów
;
; Poniższe instrukcje sprawdzają, czy p zawiera permutację liczb od 0 do n-1. Zawartość
; tablicy po wykonaniu instrukcji ma być taka, jak przed wykonaniem. Wynik sprawdzenia
; mieści się w buforze eax (0 - są duplikaty, 1 - nie ma).
;
; Liczby są zaznaczone jako odwiedzone za pośrednictwem nieużywanego najstarszego bitu.
; 
; Flaga w buforze r9: 
;       Jeśli r9 = 1, to poniższa pętla wprowadza zmiany do tablicy.
;       Jeśli r9 = 0, to odwraca wprowadzone przez siebie zmiany.
;
; Jeśli po wykonaniu sprawdzenia znaleziono duplikaty, skacze do .ret_false. W przeciwnym
; razie kontynuuje program.
;*****************************************************************************************
.dups_loop_init:
        mov     r9,2                    ; r9 -> flaga dla pętli .check_dups
        mov     ax,1                    ; Załóż, że nie ma duplikatów.
.dups_loop:
        dec     r9
        mov     ecx,edi                 ; rcx -> i := n (licznik pętli)
.check_dups:
        mov     edx,[rsi+4*rcx-4]       ; edx -> j := p[i]
        btr     edx,31                  ; Zignoruj 31-szy bit.
        test    r9,r9
        je      .dups_undo              ; Jeśli r9 = 0, to wycofaj zmiany.
.dups_do:
        bt      dword [rsi+4*rdx],31    ; Sprawdź, czy p[j] = p[p[i]] odwiedzone.
        jnc     .dups_neg               ; Jeśli nieodwiedzone, kontynuuj pętlę
        xor     eax,eax                 ; w.p.p. znaleziono duplikat.
        jmp     .skip_p_neg
.dups_undo:
        bt      dword [rsi+4*rdx],31
        jnc     .skip_p_neg             ; Jeśli znak dodatni, to nie odwracaj.
.dups_neg:
        btc     dword [rsi+4*rdx],31    ; Odwróć najstarszy bit.
.skip_p_neg:
        loop    .check_dups

        test    r9,r9
        jnz     .dups_loop              ; Jeśli r9 > 0, to kontynuuj pętlę.

        test    eax,eax
        jz      .ret_false

;*****************************************************************************************
; Odwrócenie permutacji (algorytm Huanga, Knuth I, str. 182)
;
; Zakłada, że tablica p wskazuje poprawną permutację n liczb od 0 do n-1, oraz, że n jest
; liczbą z zakresu 1..2^31+1.
;
; Pod etykietą .huang_inc następuje tymczasowa inkrementacja elementów tablicy o 1, aby
; wyeliminować zero z permutacji. Po odwróceniu elementów cyklu inkrementacja ta jest
; cofana instrukcjami spod etykiety .huang_cycle_end.
;
; Poniższe procedury zawsze kończą się poprawnym odwróceniem tablicy i zwróceniem true.
;*****************************************************************************************
.huang_init:
        mov     ecx,edi                 ; ecx -> m := n (licznik pętli)
        mov     eax,-1                  ; eax -> j := -1
.huang_inc: 
        inc     dword [rsi+4*rcx-4]     ; p[m]++
        loop    .huang_inc
        mov     ecx,edi                 ; ecx -> m := n (licznik pętli)
.huang_next:
        mov     edx,[rsi+4*rcx-4]       ; edx -> i := p[m-1]
        test    edx,edx
        jl      .huang_cycle_end        ; Jeśli i < 0, to przeskocz do końca cyklu.
.huang_invert:
        mov     [rsi+4*rcx-4],eax       ; p[m-1] := j
        mov     eax,ecx                 ; (1/2) j := -m
        neg     eax                     ; (2/2)
        mov     ecx,edx                 ; m := i
        mov     edx,[rsi+4*rcx-4]       ; i := p[m-1]
.huang_is_end:
        test    edx,edx
        jg      .huang_invert           ; Jeśli i > 0, to wróć do invert
        mov     edx,eax                 ; w.p.p. i := j.
.huang_cycle_end:
        mov     [rsi+4*rcx-4],edx       ; (1/2) p[m-1] := -i
        neg     dword [rsi+4*rcx-4]     ; (2/2)
        dec     dword [rsi+4*rcx-4]
        loop    .huang_next             ; Jeśli m > 0, to kontynuuj algorytm.

.ret_true:                              ; Zwróć true.
        mov     ax,1
        ret

; vim: tw=90
