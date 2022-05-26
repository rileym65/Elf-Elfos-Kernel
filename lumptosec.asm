#include   macros.inc

; *******************************
; *** Convert lump to sector  ***
; *** RA - lump               ***
; *** Returns: R8:R7 - Sector ***
; *******************************
           proc    lumptosec

sret:      equ     5

           extrn   lmpshift

           ldi     high lmpshift       ; need to see how many shifts are needed
           phi     r8
           ldi     low lmpshift
           plo     r8
           ldn     r8                  ; get shift count
           plo     re                  ; and put into shift counter
           glo     ra                  ; transfer lump to sector
           plo     r7
           ghi     ra
           phi     r7
           ldi     0                   ; zero high word
           phi     r8
           plo     r8
sectolmp1: glo     r7                  ; perform shift
           shl
           plo     r7
           ghi     r7
           shlc
           phi     r7
           glo     r8
           shlc
           plo     r8
           dec     re                  ; decrement shift count
           glo     re                  ; check for completion
           lbnz    sectolmp1           ; loop back if more shifts needed
           sep     sret                ; return to caller

           endp

