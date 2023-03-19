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
; Sprawdzanie poprawności tablicy p
; Inkrementuje całą tablicę o 1. Następnie sprawdza, czy tablica p jest
; permutacją liczb 1..n.
; *****************************************************************************
        mov     rcx,rdi                 ; zapisz n w rcx jako obecny licznik pętli
        mov     eax,1

.inc:
; ::::: Pętla inkrementująca liczby w p z licznikiem w rcx
        cmp     dword [rsi+4*rcx-4],edi
        jae     .undo_inc_bad           ; jeśli p[i] >= n, to p nie jest permutacją
        cmp     dword [rsi+4*rcx-4],0
        jb      .undo_inc_bad           ; jeśli p[i] < 0, to p nie jest permutacją
        inc     dword [rsi+4*rcx-4]     ; wykonaj p[i]++
        loop    .inc

        mov     rcx,rdi                 ; zapisz n-1 w rcx jako obecny licznik pętli
.check_dups:
; ::::: Pętla sprawdzająca, czy w p istnieją duplikaty
        mov     edx,dword [rsi+4*rcx-4] ; rdx ma pełnić rolę indeksu j := p[i]
        cmp     edx,0
        jg      .dups_invert            ; jeśli rdx > 0, odwróć p[j-1]
        jmp     .dups_neg_invert        ; jeśli rdx < 0, zmień znak j, odwróć p[j-1]
.check_dups_ctd:
        loop    .check_dups

        mov     rcx,rdi                 ; zapisz n w rcx jako obecny licznik pętli
.undo_dups:
; ::::: Pętla cofająca modyfikacje w znakach wprowadzone podczas .check_dups
        mov     edx,dword [rsi+4*rcx-4] ; rdx ma pełnić rolę indeksu j := p[i]
        cmp     edx,0
        jg      .dups_revert            ; jeśli rdx > 0, odwróć p[j-1]
        jmp     .dups_neg_revert        ; jeśli rdx < 0, zmień znak j, odwróć p[j-1]
.undo_dups_ctd:
        loop    .undo_dups
        cmp     eax,0
        je      .undo_inc_full          ; jeśli znaleziono duplikaty, sprzątaj

; *****************************************************************************
; Procedura odwracania permutacji (algorytm Huanga, Knuth I, str. 182)
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
        jl      .huang_cycle_end        ; jesli i < 0, przeskocz do końca cyklu
.huang_invert:
        mov     dword [rsi+4*rcx-4],ebx ; p[m-1] := j
        mov     ebx,ecx                 ; (1/2) j := -m
        neg     ebx                     ; (2/2)
        xor     ecx,ecx
        add     ecx,edx                 ; m := i
        mov     edx,dword [rsi+4*rcx-4] ; i := p[m-1]
.huang_is_end:
        cmp     edx,0
        jg      .huang_invert           ; jesli i > 0, wróć do invert
        mov     edx,ebx                 ; w.p.p. i := j
.huang_cycle_end:
        mov     dword [rsi+4*rcx-4],edx ; (1/2) p[m-1] := -i
        neg     dword [rsi+4*rcx-4]     ; (2/2)
        loop    .huang_next

        jmp     .undo_inc_full

; *****************************************************************************
; Fragmenty poza normalnym biegiem instrukcji
; *****************************************************************************
 
; ::::: INVERT
.dups_neg_invert:                       ; odwrócenie, gdy rdx jest ujemne
        neg     edx
.dups_invert:                           ; odwrócenie, gdy rdx jest dodatnie
        cmp     dword [rsi+4*rdx-4],0
        jl      .dups_is_bad
        neg     dword [rsi+4*rdx-4]
        jmp     .check_dups_ctd

; ::::: REVERT
.dups_neg_revert:                       ; odwrócenie, gdy rdx jest ujemne
        neg     edx
.dups_revert:                           ; odwrócenie, gdy rdx jest dodatnie
        cmp     dword [rsi+4*rdx-4],0
        jg      .undo_dups_ctd
        neg     dword [rsi+4*rdx-4]
        jmp     .undo_dups_ctd

; ::::: Zaznacz niepoprawność zawartości tablicy
.dups_is_bad:
        xor     eax,eax
        jmp     .check_dups_ctd

; ::::: Wycofaj zmiany wprowadzone przez pętlę .inc
.undo_inc_bad:
        xor     eax,eax
.undo_inc:
        inc     rcx
        dec     dword [rsi+4*rcx]       ; wykonaj p[i]--
        lea     r9,[rdi-1]
        cmp     rcx,r9
        jb      .undo_inc               ; jeśli i < n-1, kontynuuj pętlę
        ret

; ::::: Wycofaj przesunięcie o 1 na całej tabeli
.undo_inc_full:
        mov     rcx,rdi                 ; ustaw rcx na i
.undo_inc_loop:
        dec     dword [rsi+4*rcx-4] ; wykonaj p[i]--
        loop    .undo_inc_loop          ; jeśli i < n-1, kontynuuj pętlę
        ret

.ret_false:
        xor     eax,eax
        ret
