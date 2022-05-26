#include   macros.inc

; ***************************
; *** Delete a lump chain ***
; *** RA - starting lump  ***
; ***************************
           proc    delchain

scall:     equ     4
sret:      equ     5

           extrn   readlump
           extrn   writelump

           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
delchlp:   ghi     ra                  ; make copy of lump
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; read lump value
           dw      readlump
           ghi     ra                  ; move to rb
           phi     rb
           glo     ra
           plo     rb
           ghi     rc                  ; transfer original copy back to ra
           phi     ra
           glo     rc
           plo     ra
           ldi     0                   ; need to zero it
           phi     rf
           plo     rf
           sep     scall               ; write the lump
           dw      writelump
           ghi     rb                  ; move next lump value to ra
           phi     ra
           glo     rb
           plo     ra
           smi     0feh                ; check for end of chain
           lbnz    delchlp             ; loop back if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    delchlp
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

           endp

