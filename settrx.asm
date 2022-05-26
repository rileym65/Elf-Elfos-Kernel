#include   macros.inc

; **********************************************
; *** Set R9 to current offset + DTA address ***
; *** RD - file descripter                   ***
; *** Returns: R9 - address in DTA           ***
; **********************************************
           proc    settrx

sret:      equ     5

           inc     rd                  ; point to low bytes of offset
           inc     rd
           lda     rd                  ; get high byte
           ani     1                   ; strip high info
           phi     r9
           lda     rd                  ; get low byte
           plo     r9
           inc     rd                  ; point to low byte of dta
           ldn     rd                  ; get low of dta
           str     r2                  ; store for add
           glo     r9
           add
           plo     r9
           dec     rd                  ; point to high byte of dta
           ldn     rd
           str     r2
           ghi     r9
           adc
           phi     r9                  ; r9 now has transfer address
           dec     rd                  ; move descriptor back to beginningglo     re                  ; recover flags
           
           dec     rd
           dec     rd
           dec     rd
           sep     sret                ; return to caller

           endp

