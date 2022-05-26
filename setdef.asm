#include   macros.inc

; ***************************************
; *** Set default execution directory ***
; *** RF - path                       ***
; *** Returns: DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************
           proc    setdef

scall:     equ     4
sret:      equ     5
           extrn   defdir
           extrn   finalsl
           extrn   opendir

           ldn     rf                  ; get first byte
           lbz     getdef              ; jump if empty
           sep     scall               ; be sure name has a final slash
           dw      finalsl
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           sep     scall               ; attempt to open directory
           dw      opendir
           irx    
           ldxa
           phi     rf
           ldx
           plo     rf
           lbdf    setdefer            ; jump if it did not exist
           ldi     high defdir         ; point to default directory
           phi     rd
           ldi     low defdir
           plo     rd
setdeflp:  lda     rf                  ; copy byte from path
           str     rd                  ; to default directory
           inc     rd
           lbnz    setdeflp            ; loop back until all bytes copied
getdefex:  ldi     0                   ; signal success
           lskp
setdefer:  ldi     1                   ; need 1 for error code
setdefex:  shr                         ; shift result into df
           irx                         ; recover consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; and return to caller
getdef:    glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           ldi     high defdir         ; get address of default directory
           phi     rd
           ldi     low defdir
           plo     rd
getdeflp:  lda     rd                  ; read byte from default path
           str     rf                  ; store into users buffer
           inc     rf
           lbnz    getdeflp            ; loop until full path copied
           lbr     getdefex            ; return to caller

           endp

