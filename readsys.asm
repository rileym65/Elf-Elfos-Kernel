#include   macros.inc

; *************************************
; *** read sector using sysfildes   ***
; *** R8:R7 - sector to read        ***
; *************************************
           proc    readsys

scall:     equ     4
sret:      equ     5

           extrn   rawread
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
           dw      rawread
           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller

           endp

