#include   macros.inc

; ********************************
; *** Get eof file descriptor  ***
; *** RD - file descriptor     ***
; *** Returns: RF - eof offset ***
; ********************************
           proc    getfdeof

sret:      equ     5

           glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     rf
           ldn     rd
           plo     rf
fdminus7:  glo     rd                  ; move pointer back to beginning
           smi     7
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

           public  fdminus7

           endp

