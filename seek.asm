#include   macros.inc

; ************************************************
; *** Perform file seek                        ***
; *** R8:R7 - offset                           ***
; ***    RD - file descriptor                  ***
; ***    RC - Whence 0-start, 1-current, 2-eof ***
; *** Returns: R8:R7 - original position       ***
; ************************************************
           proc    seek

scall:     equ     4
sret:      equ     5

           extrn   checkeof
           extrn   chkvld
           extrn   lmpmask
           extrn   loadsec
           extrn   seekend

           sep     scall               ; check for valid FILDES
           dw      chkvld
           lbnf    seekgo              ; jump if FILDES is good
           ldi     2                   ; signal invalid FILDES
           sep     sret                ; and return
seekgo:    inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           glo     rc                  ; get whence
           lbnz    seeknot0            ; jump if not 0
seekcont2: ghi     r8                  ; check for negative offset
           shl
           lbnf    seekgo2             ; jump if offset is positive
           ldi     00dh                ; signal error
           shr
           dec     rd                  ; restore rd
           dec     rd
           dec     rd
           sep     sret                ; and return
seekgo2:   glo     r7                  ; transfer new offset

           str     rd
           dec     rd
           ghi     r7
           str     rd
           dec     rd
           glo     r8
           str     rd
           dec     rd
           ghi     r8
           str     rd

;           plo     re
;           ldn     rd
;           plo     r7
;           glo     re
;           str     rd
;           dec     rd
;           ghi     r7                  ; transfer new offset
;           plo     re
;           ldn     rd
;           phi     r7
;           glo     re
;           str     rd
;           dec     rd
;           glo     r8                  ; transfer new offset
;           plo     re
;           ldn     rd
;           plo     r8
;           glo     re
;           str     rd
;           dec     rd
;           ghi     r8                  ; transfer new offset
;           plo     re
;           ldn     rd
;           phi     r8
;           glo     re
;           str     rd

seekcont:  sep     scall               ; read the corresponding sector
           dw      loadsec
; *****************************************************
; *** Code added to check for seek past end of file ***
; *****************************************************
           sep     scall               ; check if pointer is at or past eof
           dw      checkeof
           lbnf    seekret             ; return to caller if not
           glo     rd                  ; save rd
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd
           ldi     high lmpmask        ; need to get lmpmask
           phi     rf
           ldi     low lmpmask 
           plo     rf
           ldn     rf                  ; retrieve it
           str     r2                  ; save it
           inc     rd                  ; point 2nd lsb of ofs
           inc     rd
           lda     rd                  ; get msb of lump offset
           and                         ; and mask it
           phi     rf                  ; save into rf
           lda     rd                  ; get low byte of lump offset
           plo     rf                  ; rf now holds new eof
           inc     rd                  ; move past dta field
           inc     rd
           ghi     rf                  ; write new eof
           str     rd
           inc     rd                  ; point to lsb of eof
           glo     rf                  ; and write rest of eof
           str     rd
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldx
           plo     rd
; *****************************************************
seekret:   lda     rd                  ; retrieve file pointer into R8:R7
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
           dec     rd                  ; restore RD
           dec     rd
           dec     rd
           adi     0                   ; clear DF
           sep     sret                ; and return to caller
seeknot0:  smi     1                   ; check for seek from current
           lbnz    seeknot1            ; jump if not

seekct2:   glo     r7                  ; add file position to offset
           str     r2
           ldn     rd
           add
           plo     r7
           dec     rd
           ghi     r7
           str     r2
           ldn     rd
           adc
           phi     r7
           dec     rd
           glo     r8
           str     r2
           ldn     rd
           adc
           plo     r8
           dec     rd
           ghi     r8
           str     r2
           lda     rd
           adc
           phi     r8
           inc     rd                  ; put rd back at lsb
           inc     rd
           lbr     seekcont2           ; and then perform seek


;seekct2:   glo     r7                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           plo     r7                  ; keep copy
;           add                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           ghi     r7                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           phi     r7                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           glo     r8                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           plo     r8                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           dec     rd                  ; point to previous byte
;           ghi     r8                  ; add offset to current offset
;           str     r2                  ; place into memory for add
;           ldn     rd                  ; get value from descriptor
;           phi     r8                  ; keep copy
;           adc                         ; add new offset
;           str     rd                  ; store new offset
;           lbr     seekcont            ; load new sector
seeknot1:  smi     1                   ; check for seek from end
           lbnz    seeknot2
           dec     rd                  ; move to beginning of descriptor
           dec     rd
           dec     rd
           sep     scall               ; move pointer to end of file
           dw      seekend
           inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           lbr     seekct2
seeknot2:  dec     rd                  ; restore descriptor
           dec     rd
           dec     rd
           ldi     0fh                 ; signal error
           shr
           sep     sret                ; and return to caller

           endp

