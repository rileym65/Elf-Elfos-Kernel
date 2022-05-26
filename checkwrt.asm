#include   macros.inc

; *****************************************
; *** See if sector needs to be written ***
; *** RD - file descriptor              ***
; *****************************************
           proc    checkwrt

scall:     equ     4
sret:      equ     5

           extrn   rawwrite

           glo     rd                  ; need to point to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags

           shr                         ; shift first bit into DF
           lbdf    checkwrt1           ; jump if bet was set

;           ani     1                   ; see if sector has been written to
;           lbnz    checkwrt1           ; jump if so
           glo     rd                  ; restore descriptor
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller
checkwrt1: glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     rd                  ; point descripter to current sector
           adi     7
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; place descriptor back at beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     scall               ; write the sector
           dw      rawwrite
           irx                         ; recover consumed registers
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

