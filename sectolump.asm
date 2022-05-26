#include   macros.inc

; ******************************
; *** Convert sector to lump ***
; *** R8:R7 - Sector         ***
; *** Returns: RA - Lump     ***
; ******************************
           proc    sectolump

sret:      equ     5

           extrn   lmpshift

           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           ldi     high lmpshift       ; need to see how many shifts are needed
           phi     rb
           ldi     low lmpshift
           plo     rb
           ldn     rb                  ; retrieve shift count
           plo     re                  ; and set into shift counter
           glo     r8                  ; move sector to lump
           plo     rb
           ghi     r8
           phi     rb
           ghi     r7
           phi     ra
           glo     r7
           plo     ra
lmptosec1: ghi     rb                  ; perform shift
           shr
           phi     rb
           glo     rb
           shrc
           plo     rb
           ghi     ra
           shrc
           phi     ra
           glo     ra
           shrc
           plo     ra
           dec     re                  ; decrement shift count
           glo     re                  ; see if at end
           lbnz    lmptosec1           ; loop back if more shifts needed
           irx                         ; recover consumed registers
           ldxa
           phi     rb
           ldx
           plo     rb
           sep     sret                ; return to caller

           endp

