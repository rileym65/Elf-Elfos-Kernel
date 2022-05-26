#include   macros.inc

; **********************************
; *** Create a new file          ***
; *** RD - dir descriptor        ***
; *** RC - descriptro to fill in ***
; *** RF - filename              ***
; *** R7 - Flags                 ***
; ***      1-subdir              ***
; ***      2-executable          ***
; *** Returns: RD - new file     ***
; **********************************
           proc    create

scall:     equ     4
sret:      equ     5

           extrn   close
           extrn   freelump
           extrn   getsecofs
           extrn   lumptosec
           extrn   o_write
           extrn   rawread
           extrn   scratch
           extrn   setfddwrd
           extrn   setfdeof
           extrn   setfdflgs
           extrn   setfddrof
           extrn   writelump

           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r7
           stxd
           ghi     r7
           stxd
           glo     r7                  ; put copy of flags on stack
           stxd
           ldi     high scratch        ; get buffer address
           phi     rb
           ldi     low scratch
           plo     rb
           sep     scall               ; get a lump
           dw      freelump
           ldi     0                   ; setup starting lump
           str     rb
           inc     rb
           str     rb
           inc     rb
           ghi     ra
           str     rb
           inc     rb
           glo     ra
           str     rb
           inc     rb
           ldi     0                   ; set eof at zero
           str     rb
           inc     rb
           str     rb
           inc     rb
           irx                         ; recover create flags
           ldx
           str     rb                  ; and save
           inc     rb
           ldi     5                   ; need 5 zeroes
           plo     re
create1:   ldi     0
           str     rb
           inc     rb
           dec     re
           glo     re
           lbnz    create1
create2:   lda     rf                  ; get character from filename
           str     rb                  ; store into buffer
           inc     rb
           lbnz    create2             ; loop back until zero is found
           sep     scall               ; get dir sector and offset
           dw      getsecofs
           ldi     high scratch        ; get buffer address
           phi     rf
           ldi     low scratch
           plo     rf
           glo     rc                  ; save destination descriptor
           stxd
           ghi     rc
           stxd
           ldi     0                   ; 32 bytes to write
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; write the dir entry
           dw      o_write
;           dw      write
           sep     scall               ; close the directory
           dw      close
           irx                         ; recover new descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           ldi     9
           sep     scall
           dw      setfddwrd
;           sep     scall               ; write dir sector
;           dw      setfddrsc
           sep     scall               ; write dir offset
           dw      setfddrof
           ldi     0                   ; need to set current offset to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           ldi     0
           sep     scall
           dw      setfddwrd
;           sep     scall               ; write current offset
;           dw      setfdofs
           ldi     0ffh                ; need to set current sector to -1
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           ldi     15
           sep     scall
           dw      setfddwrd
;           sep     scall               ; write current offset
;           dw      setfdsec
           ldi     0ch                 ; set flags
           sep     scall
           dw      setfdflgs
           ldi     0                   ; need to set eof to 0
           phi     rf
           plo     rf
           sep     scall
           dw      setfdeof
           ldi     0feh                ; need to set end of chain
           phi     rf
           plo     rf
           sep     scall
           dw      writelump
           sep     scall               ; convert lump to sector
           dw      lumptosec
           sep     scall               ; read the sector
           dw      rawread
           irx                         ; recover consumed registers
           ldxa
           phi     r7
           ldxa
           plo     r7
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldx
           plo     ra
           sep     sret                ; return to caller
   
           endp

