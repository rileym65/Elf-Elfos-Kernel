#include   macros.inc

; *********************************
; *** Load corresponding sector ***
; *** RD - file descriptor      ***
; *********************************
           proc    loadsec

scall:     equ     4
sret:      equ     5

           extrn   append
           extrn   cklstlmp
           extrn   lmpshift
           extrn   lumptosec
           extrn   rawread
           extrn   readlump
           extrn   sectolump
           extrn   setfdeof
           extrn   startlump

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           lda     rd                  ; get current offset
           shr                         ; need to shift by 9
           plo     r8                  ; perform shift by 8
           lda     rd
           shrc
           phi     r7
           ldn     rd
           shrc
           plo     r7
           dec     rd                  ; move descriptor back to beginning
           dec     rd
           ldi     0                   ; clear high of sector address
           phi     r8
           sep     scall               ; get lump count
           dw      sectolump
           ghi     ra                  ; transfer to count
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; get starting lump for file
           dw      startlump
ldseclp:   ghi     rc                  ; see if done
           lbnz    ldsecgo             ; more to do
           glo     rc
           lbnz    ldsecgo
ldsecct:   ldi     high lmpshift       ; need to build mask
           phi     r8                  ; to figure relative sector in lump
           ldi     low lmpshift
           plo     r8
           ldn     r8                  ; get the shift count
           plo     r8                  ; R8.0 will be the count
           ldi     0                   ; will user R8.1 to build mask
           phi     r8
ldsctlp1:  glo     r8                  ; see if more shifts are needed
           lbz     ldsectg1            ; jump if not
           ghi     r8                  ; otherwise perform a shift
           shl
           ori     1                   ; set low bit
           phi     r8                  ; put it back
           dec     r8                  ; decrement the shift count
           lbr     ldsctlp1            ; loop back until shifts are done
ldsectg1:  ghi     r8                  ; get mask
           str     r2                  ; and put in memory for use
           glo     r7                  ; get sector offset
           and                         ; mask out lump portion
           plo     rc                  ; save it
           sep     scall               ; convert lump to sector
           dw      lumptosec
           glo     rc                  ; get offset
           str     r2                  ; and add to sector
           glo     r7
           add
           plo     r7
           ghi     r7
           adci    0
           phi     r7
           glo     r8
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; now read the sector
           dw      rawread
           sep     scall               ; check for final lump/eof
           dw      cklstlmp
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
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
ldsecgo2:  dec     rc                  ; decrement lump count
           irx                         ; remove saved lump from stack
           irx
           lbr     ldseclp             ; and keep looking
ldsecgo:   glo     ra                  ; save lump number
           stxd
           ghi     ra
           stxd
           sep     scall               ; get next lump in chain
           dw      readlump
           glo     ra                  ; see if have last lump of file
           smi     0feh
           lbnz    ldsecgo2            ; jump if not
           ghi     ra                  ; check high byte
           smi     0feh
           lbnz    ldsecgo2
           irx                         ; recover last lump number
           ldxa
           phi     ra
           ldx
           plo     ra
ldsecadlp: sep     scall               ; append a lump to the file
           dw      append
           sep     scall               ; read new lump value
           dw      readlump
           dec     rc                  ; decrement the count
           glo     rc                  ; get count
           lbnz    ldsecadlp           ; jump if need to add more
           ghi     rc                  ; check high byte as well
           lbnz    ldsecadlp
           glo     rf                  ; save RF
           stxd
           ghi     rf
           stxd
           ldi     0                   ; set eof for new lump
           phi     rf
           plo     rf
           sep     scall               ; write to descriptor
           dw      setfdeof
           irx                         ; recover RF
           ldxa
           phi     rf
           ldx
           plo     rf
           lbr     ldsecct             ; then continue

           endp

