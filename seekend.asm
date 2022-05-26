#include   macros.inc

; ***********************************
; *** Seek file descriptor to end ***
; *** RD - file descriptor        ***
; ***********************************
           proc    seekend

scall:     equ     4
sret:      equ     5

           extrn   getfdeof
           extrn   lmpshift
           extrn   readlump
           extrn   setfddwrd
           extrn   startlump

           glo     r7                  ; save registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save registers
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save registers
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save registers
           stxd
           ghi     rf
           stxd
           ldi     0                   ; set offset to zero
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; get starting lump for file
           dw      startlump
           sep     scall               ; read next lump
           dw      readlump
seekendlp: glo     ra                  ; see if have last lump
           smi     0feh
           lbnz    seekendgo           ; jump if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    seekendgo
           sep     scall               ; get file offset
           dw      getfdeof
           glo     rf                  ; add into offset
           str     r2
           glo     r7
           add
           plo     r7
           ghi     rf
           str     r2
           ghi     r7
           adc
           phi     r7
           glo     r8
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           ldi     0
           sep     scall
           dw      setfddwrd
;           sep     scall               ; write offset to descriptor
;           dw      setfdofs
           irx                         ; recover consumed registers
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
           sep     sret                ; return to caller
seekendgo: ldi     high lmpshift       ; need to get the lump shift value
           phi     rf                  ; in order to determine how much to
           ldi     low lmpshift        ; add to the current offset
           plo     rf
           ldn     rf                  ; get the shift count
           plo     re                  ; and place into the loop counter
           ldi     02h                 ; set intial value at 512 bytes
           phi     rf
           ldi     0
           plo     rf
seeklp1:   glo     re                  ; see if done with shifts
           lbz     seekendg1           ; jump if so
           dec     re                  ; otherwise decrement count
           ghi     rf                  ; and update bytes per lump
           shl
           phi     rf
           lbr     seeklp1             ; loop until correct number of shifts
seekendg1: ghi     r7                  ; add bytes per lump to offset
           str     r2             
           ghi     rf
           add
           phi     r7
           glo     r8                  ; propagate carry
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; read value of next lump
           dw      readlump
           lbr     seekendlp           ; loop until end found

           endp

