#include   macros.inc

; *************************************
; *** Open master directory         ***
; *** Returns: RD - file descriptor ***
; *************************************
           proc    openmd

scall:     equ     4
sret:      equ     5

           extrn   dta
           extrn   mddta
           extrn   mdfildes
           extrn   rawread
           extrn   sector0

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; read sector 0
           dw      sector0
           ldi     high mdfildes       ; point to mdfildes
           phi     rd
           ldi     low mdfildes
           plo     rd
           ldi     low dta             ; point to eof of master dir
           adi     48                  ; add 304, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           ldi     0                   ; set current offset to zero
           str     rd
           inc     rd
           str     rd
           inc     rd
           str     rd
           inc     rd
           str     rd
           inc     rd
           ldi     high mddta          ; next dta
           str     rd
           inc     rd
           ldi     low mddta
           str     rd
           inc     rd
           lda     rf                  ; next eof
           str     rd
           inc     rd
           lda     rf
           str     rd
           inc     rd
           ldi     0ch                 ; next flags
           str     rd
           inc     rd
           ldi     4                   ; 6 bytes to copy
           plo     re
openmdlp1: ldi     0                   ; need to set 0
           str     rd
           inc     rd
           dec     re                  ; decrement count
           glo     re
           lbnz    openmdlp1           ; loop until done
           ldi     1                   ; dir offset is 300
           str     rd
           inc     rd
           ldi     44
           str     rd
           inc     rd
           ldi     4                   ; 4 bytes to copy
           plo     re
openmdlp2: ldi     0ffh                ; need to set -1
           str     rd
           inc     rd
           dec     re                  ; decrement count
           glo     re
           lbnz    openmdlp2           ; loop until done
           glo     rd                  ; move desriptor back to beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           ldi     0
           phi     r8
           plo     r8
           ldi     low mdfildes
           plo     rd
           ldi     low dta             ; point to sector
           adi     5                   ; add 261, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           lda     rf                  ; get starting sector
           phi     r7
           lda     rf
           plo     r7
           sep     scall               ; read first sector
           dw      rawread
           irx                         ; recover used registers
           ldxa
           phi     rf
           ldxa
           plo     rf
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

