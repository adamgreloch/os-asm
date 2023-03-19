global inverse_permutation

; Argumenty funkcji inverse_permutation:
;   rdi - wartość n
;   rsi - n-elementowa tablica p nieujemnych liczb całkowitych

section .text

inverse_permutation:
; *****************************************************************************
; Sprawdzanie poprawności wartości n
; *****************************************************************************
        cmp     rdi,0
        je      .ret_false              ; jeśli n == 0, zwróć false
        lea     r9,[rdi-1]
        cmp     r9,0x7fffffff           ; porównaj n-1 z INT_MAX
        ja      .ret_false              ; jeśli n > INT_MAX + 1, zwróć false

; *****************************************************************************
; Inkrementacja całej tablicy o 1
; *****************************************************************************
        mov     rcx,rdi                 ; zapisz n w rcx jako obecny licznik pętli
        mov     eax,1
.inc:
        ; Pętla inkrementująca liczby w p z licznikiem w rcx
        cmp     dword [rsi+4*rcx-4],edi
        jae     .undo_inc_bad           ; jeśli p[i] >= n, to p nie jest permutacją
        cmp     dword [rsi+4*rcx-4],0
        jb      .undo_inc_bad           ; jeśli p[i] < 0, to p nie jest permutacją
        inc     dword [rsi+4*rcx-4]     ; wykonaj p[i]++
        loop    .inc

        mov     r9,2                    ; r9 -> flaga dla pętli .check_dups

; *****************************************************************************
; Sprawdzenie poprawności tablicy p
;
; Poniższe instrukcje sprawdzają, czy p zawiera permutację liczb od 1 do n.
; Zawartość tablicy po wykonaniu instrukcji ma być taka, jak przed wykonaniem.
; Wynik sprawdzenia zawarty jest w buforze eax.
; 
; Flaga w buforze r9: 
;       Jeśli r9 = 1, to poniższa pętla wprowadza zmiany do tablicy
;       Jeśli r9 = 0, to odwraca wprowadzone przez siebie zmiany 
; *****************************************************************************
.dups_loop:
        dec     r9                      ; r9 = 0
        mov     rcx,rdi                 ; zapisz n w rcx jako obecny licznik pętli
.check_dups:
        mov     edx,dword [rsi+4*rcx-4] ; edx ma pełnić rolę indeksu j := p[i]
        cmp     edx,0
        jg      .skip_edx_neg           ; jeśli j > 0, przeskocz zmianę znaku
        neg     edx                     ; w.p.p. j := -j
.skip_edx_neg:
        cmp     r9,0
        je      .dups_undo              ; jeśli r9 = 0, wycofuj zmiany
.dups_do:
        cmp     dword [rsi+4*rdx-4],0
        jl      .dups_is_bad            ; jeśli p[j] < 0, to znaleziono duplikat
        jmp     .dups_neg               ; w.p.p. kontynuuj
.dups_undo:
        cmp     dword [rsi+4*rdx-4],0
        jg      .skip_p_neg             ; jeśli p[j] > 0, to nie ruszaj
.dups_neg:
        neg     dword [rsi+4*rdx-4]
.skip_p_neg:
        loop    .check_dups

        cmp     r9,0
        jg      .dups_loop               ; jeśli r9 > 0, to kontynuuj pętlę

        cmp     eax,0
        je      .undo_inc_full
        ; Jeśli eax = 0, to znaleziono duplikaty, więc wejściowa tablica jest
        ; niepoprawna, należy wycofać wszelkie zmiany za pomocą instrukcji pod
        ; etykietą .undo_inc_full i zwrócić z eax = 0.

; *****************************************************************************
; Procedura odwracania permutacji (algorytm Huanga, Knuth I, str. 182)
;
; Zakłada, że tablica p wskazuje poprawną permutację n liczb od 1 do n, oraz,
; że n jest liczbą z zakresu 1..2^31+1.
; *****************************************************************************
.huang_init:
        mov     rcx,rdi                 ; rcx -> m := n (licznik pętli)
        ; Jest gwarantowane, że rdi jest liczbą 32 bitową, więc powyższa
        ; operacja ustawia jedynie najmłodsze 32 bity.
        ; Wszystkie kolejne odwołania do zawartości rcx będą więc za
        ; pośrednictwem ecx.
        mov     ebx,-1                  ; ebx -> j := -1
.huang_next:
        mov     edx,dword [rsi+4*rcx-4] ; edx -> i := p[m-1]
        cmp     edx,0
        jl      .huang_cycle_end        ; jeśli i < 0, przeskocz do końca cyklu
.huang_invert:
        mov     dword [rsi+4*rcx-4],ebx ; p[m-1] := j
        mov     ebx,ecx                 ; (1/2) j := -m
        neg     ebx                     ; (2/2)
        xor     ecx,ecx
        add     ecx,edx                 ; m := i
        mov     edx,dword [rsi+4*rcx-4] ; i := p[m-1]
.huang_is_end:
        cmp     edx,0
        jg      .huang_invert           ; jeśli i > 0, wróć do invert
        mov     edx,ebx                 ; w.p.p. i := j
.huang_cycle_end:
        mov     dword [rsi+4*rcx-4],edx ; (1/2) p[m-1] := -i
        neg     dword [rsi+4*rcx-4]     ; (2/2)
        loop    .huang_next

.undo_inc_full: ; Wycofuje przesunięcie o 1 na całej tabeli
        mov     rcx,rdi                 ; ustaw rcx na i
.undo_inc_loop:
        dec     dword [rsi+4*rcx-4]     ; wykonaj p[i]--
        loop    .undo_inc_loop          ; jeśli i < n-1, kontynuuj pętlę
        ret

; *****************************************************************************
; Fragmenty poza normalnym biegiem instrukcji
; *****************************************************************************
 
; Zasygnalizuj niepoprawność zawartości tablicy
.dups_is_bad:
        xor     eax,eax
        jmp     .skip_p_neg

; Wycofaj zmiany wprowadzone przez pętlę .inc
.undo_inc_bad:
        xor     eax,eax
.undo_inc:
        inc     rcx
        dec     dword [rsi+4*rcx]       ; wykonaj p[i]--
        lea     r9,[rdi-1]
        cmp     rcx,r9
        jb      .undo_inc               ; jeśli i < n-1, kontynuuj pętlę
        ret

.ret_false:
        xor     eax,eax
        ret

