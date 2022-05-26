#include    macros.inc

; *****************************************
; *** Increment current offset          ***
; *** RD - file descriptor              ***
; *** Returns: DF=1 - new sector loaded ***
; *****************************************
           proc    incofs

scall:     equ     4
sret:      equ     5

           extrn   lmpmask
           extrn   lumptosec
           extrn   rawread
           extrn   readlump
           extrn   sectolump

           inc     rd                  ; move to last byte of offset
           inc     rd
           inc     rd
           ldn     rd                  ; get offset
           adi     1                   ; increment it
           str     rd                  ; and put back
           plo     re                  ; keep copy of this byte
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           glo     re                  ; get first byte
           lbz     incofs1             ; jump if it is zero
incofse1:  ldi     0
           shr
           sep     sret                ; return to caller
incofs1:   inc     rd                  ; move to 3rd byte
           inc     rd
           ldn     rd                  ; retrieve it
           dec     rd                  ; move back to beginning
           dec     rd
           plo     re                  ; keep a copy
           ani     1
           lbnz    incofse1            ; jump if not zero
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           ldi     high lmpmask        ; need to get lump mask
           phi     r8
           ldi     low lmpmask
           plo     r8
           ldn     r8                  ; retrieve lump mask
           str     r2                  ; need to mask with byte 2 
           glo     re                  ; of the current file pointer
           and                         ; combine with mask
           plo     re                  ; and keep in re
           glo     rd                  ; move descriptor to current sector
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; move descriptor back to beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           glo     re                  ; recover byte 3rd byte of file pointer
           lbz     incofslmp           ; need a new lump
           inc     r7                  ; increment count
           glo     r7                  ; see if rollover happened
           lbnz    incofs2             ; jump if not
           ghi     r7
           lbnz    incofs2
           inc     r8                  ; propagate the incrment
incofs2:   sep     scall               ; read the new sector
           dw      rawread
incofse2:  irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           ldi     1
           shr
           sep     sret                ; return to caller
incofslmp:
           glo     ra                  ; save additional consumed registers
           stxd
           ghi     ra
           stxd
           sep     scall               ; convert sector to lump
           dw      sectolump
           sep     scall               ; get next lump
           dw      readlump
           sep     scall               ; get first sector of next lump
           dw      lumptosec
           sep     scall               ; read the next sector in
           dw      rawread
           sep     scall               ; get next lump
           dw      readlump
           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           glo     ra                  ; check for ending lump
           smi     0feh                ; check for end of chain code
           lbnz    incofs3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    incofs3
           ldn     rd                  ; get flags
           ori     4                   ; indicate last lump loaded
incofs4:   str     rd                  ; put it back
           glo     rd                  ; move descriptor back
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldx
           plo     ra
           lbr     incofse2
incofs3:   ldn     rd                  ; get flags
           ani     0fbh                ; indicate not last lump
           lbr     incofs4             ; and continue

           public  incofs1

           endp

