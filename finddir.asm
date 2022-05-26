#include   macros.inc

; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RC - first char following dirs ***
; ***          DF=0 - dir was found           ***
; ***          DF=1 - nonexistant dir         ***
; ***********************************************
           proc    finddir

scall:     equ     4
sret:      equ     5

           extrn   error
           extrn   follow
           extrn   openmd
           extrn   path

           sep     scall               ; open the master dir
           dw      openmd
           ldn     rf                  ; get first byte of pathname
           smi     '/'                 ; check for absolute path
           lbz     findabs             ; jump if so
           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd
           ldi     high path           ; point to current dir
           phi     rf
           ldi     low path
           plo     rf
findcont:  ldn     rf                  ; get first byte
           smi     '/'                 ; check for slash
           lbnz    finddirg            ; jump if not
           inc     rf                  ; move past leading slash
finddirg:  sep     scall               ; follow path in current dir
           dw      follow
           plo     re                  ; save result code
           irx                         ; recover original path
           ldxa
           phi     rf
           ldx
           plo     rf
           glo     re                  ; get result code back
           lbdf    error               ; jump on error
           lbr     findrel
findabs:   inc     rf                  ; move past first slash
findrel:   sep     scall               ; follow dirs
           dw      follow
           lbdf    error               ; jump on error
           ghi     rf                  ; transfer name
           phi     rc
           glo     rf
           plo     rc
           ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller

           public  findcont

           endp

