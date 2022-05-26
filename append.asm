#include   macros.inc

; *************************************
; *** Append a lump to current file ***
; *** RD - file descriptor          ***
; *** Returns DF=0 - success        ***
; ***         DF=1 - failed         ***
; *************************************
           proc    append

scall:     equ     4
sret:      equ     5

           extrn   freelump
           extrn   getfdflgs
           extrn   readlump
           extrn   setfdflgs
           extrn   startlump
           extrn   writelump

           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           sep     scall               ; find a free lump
           dw      freelump
           lbnf    append1             ; jump if one was found
           ldi     1                   ; signal an error
appende:   shr                         ; shift into df
           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldx
           plo     ra
           sep     sret                ; and return to caller
append1:   glo     rb                  ; save additional registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save additional registers
           stxd
           ghi     rc
           stxd
           glo     rf                  ; save additional registers
           stxd
           ghi     rf
           stxd
           ghi     ra                  ; move new lump
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; get first lump of file
           dw      startlump
           ghi     ra                  ; copy start lump to temp
           phi     rb
           glo     ra
           plo     rb
append2:   glo     ra                  ; get for end of chain code
           smi     0feh
           lbnz    append3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    append3
           lbr     append4             ; end found
append3:   ghi     ra                  ; copy lump to temp
           phi     rb
           glo     ra
           plo     rb
           sep     scall               ; get next lump
           dw      readlump
           lbr     append2             ; loop until last lump is found
append4:   ghi     rb                  ; transfer lump
           phi     ra
           glo     rb
           plo     ra
           ghi     rc                  ; transfer new lump
           phi     rf
           glo     rc
           plo     rf
           sep     scall               ; write new lump value
           dw      writelump
           ghi     rc                  ; get new lump
           phi     ra
           glo     rc
           plo     ra
           ldi     0feh                ; end of chain code
           phi     rf
           plo     rf
           sep     scall               ; write new lump value
           dw      writelump
           sep     scall               ; get file descriptor flags
           dw      getfdflgs
           ani     0fbh                ; indicat current sector is not last
           sep     scall               ; and write back
           dw      setfdflgs
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldx
           plo     rb
           ldi     0                   ; indicate success
           lbr     appende             ; and return

           endp

