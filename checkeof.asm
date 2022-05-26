#include   macros.inc

; **********************************
; *** Check if at end of file    ***
; *** RD - file descriptor       ***
; *** Returns: DF=0 - not at end ***
; ***          DF=1 - At end     ***
; **********************************
           proc    checkeof

scall:     equ     4
sret:      equ     5

           extrn   lmpmask

           glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd
           ldi     high lmpmask        ; need to get lmpmask
           phi     rf
           ldi     low lmpmask 
           plo     rf
           ldn     rf                  ; retrieve it
           plo     re                  ; and save it here
           glo     rd                  ; save rd
           stxd
           adi     8                   ; and move to flags
           plo     rd
           plo     rf
           ghi     rd
           stxd
           adci    0
           phi     rd
           phi     rf
           ldn     rd                  ; get flags
           ani     4                   ; see if in final lump
           lbz     noeof               ; jump if not
           dec     rf                  ; move rf to eof low byte
           dec     rd                  ; move rd to current offset
           dec     rd
           dec     rd
           dec     rd
           dec     rd
; ******************************************************************
; *** This was original code which compared for the offset being ***
; *** equal to the eof field.                                    ***
; ******************************************************************
;           ldn     rd                  ; get byte from offset
;           str     r2
;           ldn     rf                  ; get eof byte
;           sm                          ; compare them
;           lbnz    noeof               ; jump if no match
;           dec     rf                  ; move to previous byte
;           dec     rd
;           ldn     rf                  ; get byte from eof
;           str     r2                  ; this byte needs to be masked
;           glo     re                  ; get mask
;           and                         ; and apply to the value
;           stxd                        ; keep value on the stack
;           ldn     rd                  ; get byte from offset
;           str     r2                  ; this value must also be masked
;           glo     re                  ; obtain mask
;           and                         ; and perform the masking
;           irx                         ; move back to the last byte
;           sm                          ; compare values
;           lbnz    noeof               ; jump if not at eof
; ******************************************************************
; *** Replaced with the following code which sees if the current ***
; *** offset is equal OR greater than the eof byte               ***
; ******************************************************************
           ldn     rf                  ; get byte from eof
           str     r2                  ; store for comparison
           ldn     rd                  ; get byte from offset
           sm                          ; and subtract
           dec     rf                  ; move to msb of eof
           dec     rd                  ; move to next most byte of offset
           ldn     rf                  ; get byte from eof
           str     r2                  ; this byte needs to be masked
           glo     re                  ; get lump mask
           and                         ; and mask eof byte
           stxd                        ; save it for now
           ldn     rd                  ; get offset byte
           str     r2                  ; this must also be masked
           glo     re                  ; get the mask
           and                         ; and mask offset byte
           irx                         ; point x back to masked eof byte
           smb                         ; and continue subtraction
           lbnf    noeof               ; jump if not at or past eof
; ***********************
; *** End of new code ***
; ***********************
ateof:     ldi     1                   ; signal at end
checkeofe: shr                         ; shift result into df
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller
noeof:     ldi     0                   ; signal not at eof
           lbr     checkeofe

           endp

