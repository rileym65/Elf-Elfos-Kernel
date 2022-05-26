#include   macros.inc

; ***************************************
; *** Read bytes from file            ***
; *** RD - file descriptor            ***
; *** RC - Number of bytes to read    ***
; *** RF - Buffer to store bytes in   ***
; *** Returns: RC - actual bytes read ***
; ***          DF=0 - no errors       ***
; ***          DF=1 - error           ***
; ***                 D - Error code  ***
; ***************************************
           proc    read

scall:     equ     4
sret:      equ     5

           extrn   checkeof
           extrn   chkvld
           extrn   incofs
           extrn   settrx

           sep     scall               ; check for valid FILDES
           dw      chkvld
           lbnf    readgo              ; jump if good
           ldi     2                   ; Signal invalid FILDES
           sep     sret                ; and return
readgo:    glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           sep     scall               ; setup transfer address
           dw      settrx
           ldi     0                   ; clear bytes read counter
           phi     rb
           plo     rb
readlp:    glo     rc                  ; see if more bytes to read
           lbnz    read1               ; jump if so
           ghi     rc
           lbnz    read1
           ghi     rb                  ; move bytes read
           phi     rc
           glo     rb
           plo     rc
           irx                         ; recover consumed registers
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     rb
           ldx
           plo     rb
           ldi     0                   ; signal no error
           shr
           sep     sret                ; and return to caller
read1:     sep     scall               ; check for eof
           dw      checkeof
           lbnf    read2               ; jump if not at end
           ldi     0                   ; clear the bytes left
           phi     rc
           plo     rc
           lbr     readlp              ; and loop back
read2:     lda     r9                  ; get byte from dta
           str     rf                  ; store into buffer
           inc     rf
           inc     rb                  ; increment byte count
           dec     rc                  ; decrement count
           sep     scall               ; increment offset
           dw      incofs
           lbnf    readlp              ; and loop back if not a new sector
           sep     scall               ; setup transfer address
           dw      settrx
           lbr     readlp              ; then continue
 
           endp

