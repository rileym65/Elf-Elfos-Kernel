#include   macros.inc

; *************************************
; *** Load sector 0                 ***
; *************************************
           proc    sector0

scall:     equ     4
sret:      equ     5

           extrn   readsys

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           ldi     0                   ; need to read sector 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; read system sector
           dw      readsys
           irx                         ; restore consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

           endp

