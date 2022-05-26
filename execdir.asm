#include   macros.inc

; *****************
; *** Open /BIN ***
; *****************
           proc    execdir

scall:     equ     4
sret:      equ     5

           extrn   defdir
           extrn   findcont
           extrn   openmd

           sep     scall               ; open the master dir
           dw      openmd
           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd
           ldi     high defdir         ; point to default dir
           phi     rf
           ldi     low defdir
           plo     rf
           lbr     findcont            ; continue with normal find

           endp

