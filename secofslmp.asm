#include   macros.inc

; *******************************************
; *** Convert latSector,latOffset to lump ***
; *** R8:R7 - lat Sector                  ***
; ***    R9 - lat Offset                  ***
; *** Returns: RA - lump                  ***
; *******************************************
           proc    secofslmp

sret:      equ     5

           glo     r7                  ; subtract 17 from sector number
           smi     17
           phi     ra                  ; place into ra (* 256)
           ghi     r9                  ; offset divided by 2
           shr
           glo     r9
           shrc
           plo     ra
           sep     sret                ; return to caller

           endp

