#include   macros.inc

; *************************************
; *** Change/view current directory ***
; *** RF - pathname                 ***
; ***      first byte 0 to view     ***
; *** Returns: DF=0 - success       ***
; ***          DF=1 - error         ***
; *************************************
           proc    chdir

scall:     equ     4
sret:      equ     5

           extrn   error
           extrn   finalsl
           extrn   finddir
           extrn   path

           ldn     rf                  ; get first byte of pathname
           lbz     viewdir             ; jump if to view
           sep     scall               ; check for final slash
           dw      finalsl
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           sep     scall               ; find directory
           dw      finddir
           plo     re                  ; save result code
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rc
           ldx
           plo     rc
           lbdf    chdirerr            ; jump on error
           glo     ra                  ; save consumed register
           stxd
           ghi     ra
           stxd
           ldi     high path           ; point to current dir storage
           phi     ra
           ldi     low path
           plo     ra
           ldn     rf                  ; get first byte of path
           smi     '/'                 ; check for absolute
           lbz     chdirlp             ; jump if so
chdirlp2:  lda     ra                  ; find way to end of path
           lbnz    chdirlp2
           dec     ra                  ; back up to terminator
chdirlp:   lda     rf                  ; get byte from path
           str     ra                  ; store into path
           inc     ra
           smi     33                  ; loof for terminators
           lbdf    chdirlp             ; loop until terminator found
           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldx
           plo     ra
           ldi     0                   ; indicate success
           shr
           sep     sret                ; and return to caller
chdirerr:  glo     re                  ; recover error
           lbr     error               ; and return with error
viewdir:   glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           ldi     high path           ; get current dir
           phi     ra
           ldi     low path
           plo     ra
viewdirlp: lda     ra                  ; get byte from current dir
           str     rf                  ; write to output
           inc     rf
           lbnz    viewdirlp           ; loop until terminator found
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rf
           ldx
           plo     rf
           ldi     0                   ; indicate success
           shr
           sep     sret                ; and return to caller

           endp

