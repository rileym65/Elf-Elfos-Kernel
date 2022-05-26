#include   macros.inc

; ******************************
; *** Get next lump in chain ***
; *** RA - lump              ***
; *** Returns: RA - lump     ***
; ******************************
           proc    readlump

scall:     equ     4
sret:      equ     5

           extrn   dta
           extrn   lmpsecofs
           extrn   rawread
           extrn   sysfildes
         
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs
           ldi     high sysfildes      ; get system dta
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawread
           ldi     low dta             ; get dta
           str     r2                  ; add in offset
           glo     r9
           add
           plo     rf                  ; place into pointer
           ldi     high dta
           str     r2
           ghi     r9
           adc
           phi     rf
           lda     rf                  ; get value
           phi     ra
           ldn     rf
           plo     ra
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

           endp

