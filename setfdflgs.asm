#include   macros.inc

; ************************************
; *** Set flags in file descriptor ***
; *** RD - file descriptor         ***
; ***  D - flags                   ***
; ************************************
           proc    setfdflgs

           extrn   fdminus8

           plo     re                  ; save D
           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           glo     re                  ; recover D
           str     rd                  ; store into descriptor
           lbr     fdminus8            ; and return

           endp

