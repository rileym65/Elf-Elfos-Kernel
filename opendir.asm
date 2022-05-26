#include   macros.inc

; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RF - first char following dirs ***
; ***********************************************
           proc    opendir

scall:     equ     4
sret:      equ     5

           extrn   finddir

           glo     rc                  ; save consumed register
           stxd
           ghi     rc
           stxd
           sep     scall               ; call find dir routine
           dw      finddir
           ghi     rc                  ; put end if dir back into rf
           phi     rf
           glo     rc
           plo     rf
           irx                         ; recover consumed register
           ldxa
           phi     rc
           ldx
           plo     rc
           sep     sret                ; return to caller

           endp

