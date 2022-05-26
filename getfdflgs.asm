#include   macros.inc

; **************************************
; *** Get flags from file descriptor ***
; *** RD - file descriptor           ***
; *** Returns D - flags              ***
; **************************************
           proc    getfdflgs

sret:      equ     5

           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags
fdminus8:  plo     re                  ; save D
           glo     rd                  ; move pointer back to beginning
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           glo     re                  ; recover D
           sep     sret                ; and return to caller

           public  fdminus8
    
           endp

