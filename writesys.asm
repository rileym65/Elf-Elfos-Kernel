#include   macros.inc

; *************************************
; *** write sector using sysfildes  ***
; *** R8:R7 - sector to write       ***
; *************************************
           proc    writesys

scall:     equ     4
sret:      equ     5

           extrn   rawwrite
           extrn   sysfildes

           glo     rd
           stxd
           ghi     rd
           stxd
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawwrite
           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller

           endp

