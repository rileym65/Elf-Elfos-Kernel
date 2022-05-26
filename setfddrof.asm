#include   macros.inc

; *******************************************
; *** Set dir offset in file descriptor   ***
; *** RD - file descriptor                ***
; *** R9 - dir offset                     ***
; *******************************************
           proc    setfddrof

           extrn   fdminus14

           glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r9
           str     rd
           inc     rd
           glo     r9
           str     rd
           lbr     fdminus14

           endp
