#include   macros.inc

; ********************************
; *** Set eof file descriptor  ***
; *** RD - file descriptor     ***
; *** RF - eof                 ***
; ********************************
           proc    setfdeof

           extrn   fdminus7

           glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     rf
           str     rd
           inc     rd
           glo     rf
           str     rd
           lbr     fdminus7

           endp
