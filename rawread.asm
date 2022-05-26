#include   macros.inc

; ***************************************
; *** Read raw sector                 ***
; *** R8:R7 - Sector address to write ***
; ***    RD - File descriptor         ***
; ***************************************
           proc    rawread

#include   ../bios.inc

           extrn   checkwrt
           extrn   d_ideread
           extrn   secloaded

           sep     scall               ; see if requested sector is already in
           dw      secloaded
           lbnf    rawread1            ; jump if not
           sep     sret                ; otherwise return to caller
rawread1:  sep     scall               ; see if loaded sector needs writing
           dw      checkwrt
           glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save consumed register
           stxd
           adi     4                   ; also point to dta
           plo     rd
           ghi     rd
           stxd
           adci    0
           phi     rd
           lda     rd                  ; get dta
           phi     rf                  ; and place into rf
           lda     rd
           plo     rf
           ghi     r8                  ; save r8
           stxd
           ori     0e0h                ; force lba mode
           phi     r8
           sep     scall               ; call bios to read sector
           dw      d_ideread
           irx                         ; recover high r8
           ldx
           phi     r8
           inc     rd                  ; point to flags byte
           inc     rd
           ldn     rd                  ; get flags
           ani     0feh                ; clear written flag
           str     rd                  ; and put back
           glo     rd                  ; move to current sector
           adi     7
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r8                  ; write current sector into descriptor
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           irx
           ldxa                        ; recover consumed registers
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

           endp

