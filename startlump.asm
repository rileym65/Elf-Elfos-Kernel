#include   macros.inc

; **********************************
; *** Get starting lump for file ***
; *** RD - file descriptor       ***
; *** Returns: RA - lump         ***
; **********************************
           proc    startlump

scall:     equ     4
sret:      equ     5

           extrn   dta
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
           glo     rd                  ; point to dirSector
           adi     9
           stxd                        ; and save on stack
           plo     rd
           ghi     rd
           adci    0
           stxd
           phi     rd
           lda     rd                  ; retrieve dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the directory sector
           dw      rawread
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           inc     rd                  ; point to end of offset
           inc     rd
           inc     rd
           inc     rd
           inc     rd
           ldi     low dta             ; get system dta
           str     r2                  ; add in offset
           ldn     rd
           dec     rd
           add
           plo     r7                  ; use r7 as pointer
           ldi     high dta
           str     r2
           ldn     rd
           adc
           phi     r7
           inc     r7                  ; move to starting lump
           inc     r7
           lda     r7                  ; get starting lump
           phi     ra
           ldn     r7
           plo     ra
           irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           glo     rd                  ; restore rd to beginning
           smi     13
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

           endp

