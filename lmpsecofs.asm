#include   macros.inc

; ********************************************
; *** Convert lump to latSector, latOffset ***
; *** RA - lump                            ***
; *** Returns: R8:R7 - lat sector          ***
; ***             R9 - lat offset          ***
; ********************************************
           proc    lmpsecofs

sret:      equ     5

           glo     ra                  ; get low byte of lump
           shl                         ; multiply by 2
           plo     r9                  ; put into offset
           ldi     0
           shlc                        ; propagate carry
           phi     r9                  ; R9 now has lat offset
           ghi     ra                  ; get high byte of lump
           adi     17                  ; add in base of lat table
           plo     r7                  ; place into r7
           ldi     0
           adci    0                   ; propagate the carry
           phi     r7
           ldi     0                   ; need to zero R8
           phi     r8
           plo     r8
           sep     sret                ; return to caller

           endp

