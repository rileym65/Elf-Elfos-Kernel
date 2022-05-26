#include   macros.inc

; **************************************************
; *** Set shift count for current disk lump size ***
; **************************************************
           proc    lmpsize

scall:     equ     4
sret:      equ     5

           extrn   lmpmask
           extrn   lmpshift
           extrn   sector0
          
           sep     scall               ; need system sector
           dw      sector0
           ldi     02                  ; need value at 20Ah in system buffer
           phi     rf
           ldi     0ah
           plo     rf
           ldn     rf                  ; now have sectors per lump
           plo     rf                  ; set here
           ldi     0                   ; signify no shifts done
           plo     re                  ; re will be shift counter
lmpsize1:  inc     re                  ; increment shift count
           glo     rf                  ; shift count
           shr
           plo     rf
           lbnz    lmpsize1            ; loop until count is zero
           dec     re                  ; correct for zero shifts
           ldi     high lmpshift       ; need to store value
           phi     rf
           ldi     low lmpshift
           plo     rf
           glo     re                  ; get shift count
           str     rf                  ; and save it

           ldi     01h                 ; initial mask
           plo     rf                  ; setup mask
lmpsize2:  glo     re                  ; see if done with shifts
           lbz     lmpsize3            ; jump if so
           dec     re                  ; decrement shift count
           glo     rf                  ; shift mask left
           shl
           ori     1                   ; set low bit
           plo     rf                  ; and put back
           lbr     lmpsize2            ; loop back to finish shifts
lmpsize3:  glo     rf                  ; transfer result
           plo     re
           ldi     high lmpmask        ; need to get lmpshift
           phi     rf
           ldi     low lmpmask
           plo     rf
           glo     re                  ; retrieve mask
           str     rf                  ; and store it.
           sep     sret                ; return to caller

           endp

