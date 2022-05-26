#include   macros.inc

; ***************************************
; *** Follow a directory tree         ***
; *** RD - Dir descriptor             ***
; *** RF - Pathname                   ***
; *** Returns: RD - final dir in path ***
; ***          DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************
           proc    follow

scall:     equ     4
sret:      equ     5

           extrn   errinvdir
           extrn   errnoffnd
           extrn   error
           extrn   findsep
           extrn   scratch
           extrn   searchdir
           extrn   setupfd

           sep     scall               ; check for dirname
           dw      findsep
           lbdf    founddir            ; jump if no more dirnames
           glo     rc                  ; save name after sep
           stxd
           ghi     rc
           stxd
           ghi     rf                  ; move pathname
           phi     rc
           glo     rf
           plo     rc
           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; search for name
           dw      searchdir
           irx                         ; recover pathname
           ldxa
           phi     rc
           ldx
           plo     rc
           dec     rc                  ; replace the /
           ldi     '/'
           str     rc
           inc     rc
           lbnf    finddir1            ; jump if entry was found
           ldi     errnoffnd           ; signal an error
           lbr     error
finddir1:  glo     rf                  ; point to flags
           adi     6
           plo     rf
           ghi     rf
           adci    0
           phi     rf
           ldn     rf                  ; get flags
           plo     re                  ; save it
           glo     rf                  ; put rf back
           smi     6
           plo     rf
           ghi     rf
           smbi    0
           phi     rf
           glo     re                  ; recover flags
           ani     1                   ; see if entry is a dir
           lbnz    finddir2            ; jump if so
           ldi     errinvdir           ; invalid directory error
           lbr     error
finddir2:  sep     scall               ; set fd to new directory
           dw      setupfd
           ghi     rc                  ; get next part of path
           phi     rf
           glo     rc
           plo     rf
           lbr     follow              ; and get next
founddir:  ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller

           endp

