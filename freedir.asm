#include   macros.inc
           
; *******************************************
; *** Get a free directory entry          ***
; *** RD - directory descriptor           ***
; *** Returns: RD - positioned descriptor ***
; ***          DF=0 - success             ***
; ***          DF=1 - Error               ***
; *******************************************
           proc    freedir

scall:     equ     4
sret:      equ     5

           extrn   o_read
           extrn   scratch
           extrn   seek

           ldi     0                   ; need to seek to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           plo     rc                  ; seek from start
           sep     scall               ; perform file seek
           dw      seek
           ldi     0                   ; offset
           phi     ra
           plo     ra
           phi     rb
           plo     rb
newfilelp: ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; read next record
           dw      o_read
;           dw      read
           glo     rc                  ; see if record was read
           smi     32
           lbnz    neweof              ; jump if eof hit
           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lbr     neweof              ; found an entry
newnot:    lda     rd                  ; get current offset
           phi     rb
           lda     rd
           plo     rb
           lda     rd
           phi     ra
           ldn     rd
           plo     ra
           dec     rd                  ; restore pointer
           dec     rd
           dec     rd
           lbr     newfilelp           ; keep looking
neweof:    ghi     rb                  ; transfer offset for seek
           phi     r8
           glo     rb
           plo     r8
           ghi     ra
           phi     r7
           glo     ra
           plo     r7
           ldi     0                   ; seek from beginning
           plo     rc
           sep     scall               ; perform seek
           dw      seek
           ldi     0                   ; indicate no error
           sep     sret                ; and return to caller

           endp

