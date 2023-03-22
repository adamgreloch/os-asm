global inverse_permutation

; Argumenty funkcji inverse_permutation:
;   rdi - wartość n
;   rsi - n-elementowa tablica p nieujemnych liczb całkowitych

inverse_permutation:
;*****************************************************************************
; Sprawdzanie poprawności wartości n
;*****************************************************************************
.check_n:
        test    rdi,rdi
        jz      .ret_false              ; jeśli n == 0, zwróć false
        bt      rdi,31                  ; sprawdź, czy n <= 2^31 + 1
        jnc     .check_range_init       ; jeśli tak, kontynuuj. w.p.p. zwróć false

.ret_false:                             ; ustaw wynik funkcji na false i zakończ 
        xor     eax,eax
        ret

;*****************************************************************************
; Sprawdzenie zawartości tablicy p pod kątem zakresu liczb
;*****************************************************************************
.check_range_init:
        mov     ecx,edi                 ; zapisz n w ecx jako obecny licznik pętli
.check_range_loop:
        cmp     [rsi+4*rcx-4],edi
        jae     .ret_false              ; jeśli p[i] >= n, to p nie jest permutacją
        cmp     dword [rsi+4*rcx-4],0
        jb      .ret_false              ; jeśli p[i] < 0, to p nie jest permutacją
        loop    .check_range_loop

;*****************************************************************************
; Sprawdzenie poprawności tablicy p pod kątem duplikatów
;
; Poniższe instrukcje sprawdzają, czy p zawiera permutację liczb od 1 do n.
; Zawartość tablicy po wykonaniu instrukcji ma być taka, jak przed wykonaniem.
; Wynik sprawdzenia zawarty jest w buforze eax.
;
; Liczby są zaznaczone jako odwiedzone za pośrednictwem nieużywanego
; najstarszego bitu.
; 
; Flaga w buforze r9: 
;       Jeśli r9 = 1, to poniższa pętla wprowadza zmiany do tablicy
;       Jeśli r9 = 0, to odwraca wprowadzone przez siebie zmiany 
;*****************************************************************************
.dups_loop_init:
        mov     r9,2                    ; r9 -> flaga dla pętli .check_dups
        mov     ax,1                    ; eax -> wstępnie ustaw poprawność na true
.dups_loop:
        dec     r9
        mov     ecx,edi                 ; zapisz n w rcx jako obecny licznik pętli
.check_dups:
        mov     edx,[rsi+4*rcx-4]       ; edx ma pełnić rolę indeksu j := p[i]
        btr     edx,31                  ; zignoruj 32-gi bit (TODO 31/32?)
        test    r9,r9
        je      .dups_undo              ; jeśli r9 = 0, wycofuj zmiany
.dups_do:
        bt      dword [rsi+4*rdx],31
        jnc     .dups_neg               ; jeśli nieodwiedzone, kontynuuj pętlę
        xor     eax,eax                 ; w.p.p. znaleziono duplikat
        jmp     .skip_p_neg
.dups_undo:
        bt      dword [rsi+4*rdx],31
        jnc     .skip_p_neg             ; jeśli ost bit = 0, to nie ruszaj
.dups_neg:
        btc     dword [rsi+4*rdx],31    ; XORuj ost bit
.skip_p_neg:
        loop    .check_dups

        test    r9,r9
        jnz     .dups_loop              ; jeśli r9 > 0, to kontynuuj pętlę

        test    eax,eax
        jz      .ret_false
        ; Jeśli eax = 0, to znaleziono duplikaty, więc wejściowa tablica jest
        ; niepoprawna.

;*****************************************************************************
; Odwrócenie permutacji (algorytm Huanga, Knuth I, str. 182)
;
; Zakłada, że tablica p wskazuje poprawną permutację n liczb od 0 do n-1, oraz,
; że n jest liczbą z zakresu 1..2^31+1.
;*****************************************************************************
.huang_init:
        mov     ecx,edi                 ; ecx -> m := n (licznik pętli)
        mov     eax,-1                  ; eax -> j := -1
.huang_inc: 
        inc     dword [rsi+4*rcx-4]
        loop    .huang_inc
        mov     ecx,edi
.huang_next:
        mov     edx,[rsi+4*rcx-4]       ; edx -> i := p[m-1]
        test    edx,edx
        jl      .huang_cycle_end        ; jeśli i < 0, przeskocz do końca cyklu
.huang_invert:
        mov     [rsi+4*rcx-4],eax       ; p[m-1] := j
        mov     eax,ecx                 ; (1/2) j := -m
        neg     eax                     ; (2/2)
        mov     ecx,edx                 ; m := i
        mov     edx,[rsi+4*rcx-4]       ; i := p[m-1]
.huang_is_end:
        test    edx,edx
        jg      .huang_invert           ; jeśli i > 0, wróć do invert
        mov     edx,eax                 ; w.p.p. i := j
.huang_cycle_end:
        mov     [rsi+4*rcx-4],edx       ; (1/2) p[m-1] := -i
        neg     dword [rsi+4*rcx-4]     ; (2/2)
        dec     dword [rsi+4*rcx-4]
        loop    .huang_next

        mov     ax,1
        ret
