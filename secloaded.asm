#include   macros.inc

; ************************************************
; *** Determine if sector is already in buffer ***
; *** R8:R7 - Request sector                   ***
; ***    RD - File descriptor                  ***
; *** Returns: DF=1 - Sector already loaded    ***
; ***          DF=0 - Sector not loaded        ***
; ************************************************
           proc    secloaded

sret:      equ     5

           glo     rd                  ; save descriptor address
           stxd
           adi     15                  ; point to current sector
           plo     rd
           ghi     rd
           stxd
           adci    0                   ; propagate carry
           phi     rd
           lda     rd                  ; get byte from descriptor
           str     r2                  ; place onto stack
           ghi     r8                  ; high,high of sector
           sm                          ; compare against descriptor
           lbnz    secnot              ; jump if no match
           lda     rd                  ; get next byte
           str     r2
           glo     r8                  ; high,low of sector
           sm
           lbnz    secnot
           lda     rd                  ; get next byte
           str     r2
           ghi     r7                  ; low,high of sector
           sm
           lbnz    secnot
           lda     rd                  ; last byte from descriptor
           str     r2
           glo     r7                  ; low,low of sector
           sm
           lbnz    secnot
           ldi     1                   ; need to set df, sector is loaded
seccont:   shr                         ; shift result into df
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller
secnot:    ldi     0                   ; need to reset df, sector not loaded
           lbr     seccont             ; continue

           endp

