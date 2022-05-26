#include   macros.inc

; *****************************************
; *** search directory for an entry     ***
; *** RD - file descriptor (dir)        ***
; *** RF - Where to put directory entry ***
; *** RC - filename (asciiz)            ***
; *** Returns: R8:R7 - Dir Sector       ***
; ***             R9 - Dir Offset       ***
; ***          DF=0  - entry found      ***
; ***          DF=1  - entry not found  ***
; *****************************************
           proc    searchdir

#include   ../bios.inc

           extrn   getsecofs
           extrn   o_read

           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           ghi     rf                  ; save buffer position
           phi     ra
           glo     rf
           plo     ra
           ghi     rc                  ; save filename
           phi     rb
           glo     rc
           plo     rb
searchlp:  sep     scall               ; get current sector, offset
           dw      getsecofs
           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf
           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; perform read
           dw      o_read
;           dw      read
           glo     rc                  ; see if enough bytes were read
           smi     32
           lbnz    searchno            ; jump if end of dir was hit
           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf
           lda     rf                  ; see if entry is valid
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lbr     searchlp            ; entry was no good, try again
entrygood: glo     rd                  ; save descriptor
           stxd
           ghi     rd
           stxd
           ghi     rb                  ; get filename
           phi     rd
           glo     rb
           plo     rd
           glo     ra                  ; recover buffer
           adi     12                  ; pointing at filename
           plo     rf
           ghi     ra                  ; recover buffer
           adci    0
           phi     rf
           sep     scall               ; compare the strings
           dw      f_strcmp
           plo     re                  ; save result
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           glo     re                  ; get result
           lbz     searchyes           ; entry was found
           lbr     searchlp            ; and keep looking
searchyes:
           ldi     0                   ; indicate entry was found
           lbr     searchex            ; and return
searchno:  ldi     1                   ; indicate not found
searchex:  shr
           ghi     rb                  ; recover filename
           phi     rc
           glo     rb
           plo     rc
           ghi     ra                  ; recover buffer
           phi     rf
           glo     ra
           plo     rf
           irx                         ; recover used registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldx
           plo     rb
           sep     sret                ; return to caller

           endp

