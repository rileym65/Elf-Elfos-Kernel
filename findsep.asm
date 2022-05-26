#include   macros.inc

; ****************************************
; *** Split pathname at separator      ***
; *** RF - pathname                    ***
; *** returns: RF - orignal path       ***
; ***          RC - path following sep ***
; ***          DF=0 - separator found  ***
; ***          DF=1 - ne separator     ***
; ****************************************
           proc    findsep

sret:      equ     5

           ghi     rf                  ; copy path to rc
           phi     rc
           glo     rf
           plo     rc
findseplp: lda     rc                  ; get byte from pathname
           plo     re                  ; keep a copy
           smi     33                  ; check for space or less
           lbnf    findsepno           ; no separator
           glo     re                  ; recover value
           smi     '/'                 ; check for separator
           lbnz    findseplp           ; keep looping if not found
           dec     rc                  ; need to write a terminator
           ldi     0
           str     rc
           inc     rc                  ; point rc back to following name
           ldi     0                   ; signal separator found
           shr
           sep     sret                ; and return to caller
findsepno: ldi     1                   ; signal no separator
           shr
           sep     sret                ; return to caller

           endp

