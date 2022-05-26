#include   macros.inc

; ***********************************
; *** Check for last lump and eof ***
; *** sets flags and/or eof value ***
; *** RD - file descriptor        ***
; *** RA - lump                   ***
; ***********************************
           proc    cklstlmp

scall:     equ     4
sret:      equ     5

           extrn   getfddwrd
           extrn   getfdflgs
           extrn   getfdeof
           extrn   lmpmask
           extrn   readlump
           extrn   setfdeof
           extrn   setfdflgs

           glo     r7                  ; save lump value
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save lump value
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save lump value
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save lump value
           stxd
           ghi     rf
           stxd
           sep     scall               ; read value of lump
           dw      readlump
           glo     ra                  ; see if on last lump
           smi     0feh
           lbnz    cklstno             ; jump if not last
           ghi     ra                  ; check high value as well
           smi     0feh
           lbnz    cklstno
           sep     scall               ; get descriptor flags
           dw      getfdflgs
           ori     4                   ; set last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs

           ldi     high lmpmask        ; need to get the lump mask
           phi     r8
           ldi     low lmpmask
           plo     r8
           sep     scall               ; get file offset
           dw      getfdeof
           ghi     rf                  ; store for subtraction
           str     r2                  ; store for mask operation
           ldn     r8                  ; retrieve mask
           and                         ; and mask the high byte
           stxd                        ; then store for later
           glo     rf
           stxd
           ldi     0
           sep     scall
           dw      getfddwrd
;           sep     scall               ; get file offset
;           dw      getfdofs
           glo     r7                  ; subtract eof from offset
           irx                         ; move to eof on stack
           sm                          ; perform subtract
           irx                         ; point to high byte
           ghi     r7
           sex     r8                  ; need to mask high byte
           and                         ; keep only offset portion
           sex     r2                  ; point x back to stack
           smb                         ; perform subtract of high byte
           lbnf    cklstdone           ; jump if not beyond eof
           glo     r7                  ; get offset
           plo     rf                  ; and move for eof
           ghi     r7
           sex     r8                  ; need to mask high byte
           and
           sex     r2                  ; point x back to stack
           phi     rf
           sep     scall               ; write eof back
           dw      setfdeof
           lbr     cklstdone           ; recover registers and return
cklstno:   sep     scall               ; get flags
           dw      getfdflgs
           ani     0fbh                ; clear last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs
cklstdone: irx                         ; recover registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; and return to caller

           endp

