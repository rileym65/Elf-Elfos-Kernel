#include   macros.inc

; *******************************************
; *** Get dir offset from file descriptor ***
; *** RD - file descriptor                ***
; *** Returns: R9 - dir offset            ***
; *******************************************
           proc    getfddrof

sret:      equ     5

           glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     r9
           ldn     rd
           plo     r9
fdminus14: glo     rd                  ; move pointer back to beginning
           smi     14
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

           public  fdminus14

           endp
