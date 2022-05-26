#include   macros.inc

; **********************************
; *** Get current sector, offset ***
; *** RD - file descriptor       ***
; *** Returns R8:R7 - sector     ***
; ***            R9 - offset     ***
; **********************************
           proc    getsecofs

sret:      equ     5

           inc     rd                  ; move to low word of offset
           inc     rd
           lda     rd                  ; get high byte
           ani     1                   ; strip upper bits
           phi     r9                  ; place into offset
           lda     rd                  ; get low byte
           plo     r9                  ; r9 now has offset
           glo     rd                  ; move pointer to current sector
           adi     11
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; retrieve current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; restore descriptor pointer
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; return to caller

           endp

