#include   macros.inc

; ******************************************
; *** Write bytes to file                ***
; *** RD - file descriptor               ***
; *** RC - Number of bytes to write      ***
; *** RF - Buffer of bytes to write      ***
; *** Returns: RC - actual bytes written ***
; ***          DF=0 - no errors          ***
; ***          DF=1 - error              ***
; ***                 D - Error code     ***
; ******************************************
           proc    write

scall:     equ     4
sret:      equ     5

           extrn   append
           extrn   checkeof
           extrn   incofs
           extrn   settrx

           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd                  ; get copy of descriptor
           adi     8                   ; pointing at flags
           plo     ra
           ghi     rd
           adci    0
           phi     ra
           ldn     ra                  ; get flags
           ani     2                   ; see if file is read only
           lbnz    writeer             ; exit if so
           ldn     ra                  ; get flags
           ani     8                   ; check for valid FILDES
           lbz     writeer2            ; jump if not
           sep     scall               ; setup transfer address
           dw      settrx
           ldi     0                   ; clear bytes read counter
           phi     rb
           plo     rb
writelp:   glo     rc                  ; see if more bytes to read
           lbnz    write1              ; jump if so
           ghi     rc
           lbnz    write1
           ghi     rb                  ; move bytes read
           phi     rc
           glo     rb
           plo     rc
           ldi     0
           shr                         ; clear DF
writeex:   plo     re                  ; save result code
           irx                         ; recover consumed registers
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldx
           plo     rb
           glo     re                  ; recover error result
           sep     sret                ; and return to caller
writeer:   ldi     1                   ; signal error
           shr                         ; shift into DF
           ldi     1                   ; signal read-only error
           lbr     writeex             ; then exit
writeer2:  ldi     1                   ; signal error
           shr                         ; shift into DF
           ldi     2                   ; signal invalid FILDES
           lbr     writeex             ; then exit
write1:    ldn     ra                  ; get flags byte
           ori     011h                ; set written flags
           str     ra                  ; and put back
           lda     rf                  ; get byte from buffer
           str     r9                  ; write into dta
           inc     r9
           inc     rb                  ; increment byte count
           dec     rc                  ; decrement to write count
           sep     scall               ; check for eof
           dw      checkeof
           lbnf    write2              ; jump if not at end
           dec     ra                  ; point to low byte of eof
           ldn     ra                  ; retrieve it
           adi     1                   ; add 1 to it
           str     ra                  ; and put it back
           dec     ra                  ; point to high byte
           ldn     ra                  ; retrieve it
           adci    0                   ; propagate the carry
           ani     0fh                 ; clear high nybble
           str     ra                  ; and put back
           inc     ra                  ; move back to flags
           inc     ra
           lbnz    write2              ; loop back if high byte is nonzero
           dec     ra                  ; retrieve low byte of eof
           lda     ra
           lbnz    write2              ; loop back if nonzero
           sep     scall               ; append a new lump
           dw      append
write2:    sep     scall               ; increment offset
           dw      incofs
           lbnf    writelp             ; and loop back if not a new sector
           sep     scall               ; setup transfer address
           dw      settrx
           lbr     writelp             ; then continue

           endp

