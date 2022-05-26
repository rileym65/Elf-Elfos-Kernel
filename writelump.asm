#include   macros.inc

; **************************
; *** Write value to lat ***
; *** RA - lump          ***
; *** RF - value         ***
; **************************
           proc    writelump

scall:     equ     4
sret:      equ     5

           extrn   dta
           extrn   lmpsecofs
           extrn   rawread
           extrn   rawwrite
           extrn   sysfildes
 
           glo     ra                  ; do not allow write of lump 0
           lbnz    writelmp
           ghi     ra
           lbnz    writelmp
           sep     sret
writelmp:  glo     r7                  ; save consumed registers
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
           glo     ra
           stxd
           ghi     ra
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
           plo     ra                  ; place into pointer
           ldi     high dta
           str     r2
           ghi     r9
           adc
           phi     ra
           ghi     rf                  ; write value
           str     ra
           inc     ra
           glo     rf
           str     ra
           sep     scall
           dw      rawwrite            ; write sector back to disk
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
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

