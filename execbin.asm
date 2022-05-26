#include   macros.inc

; *************************************
; *** exec a file from /bin         ***
; *** RF - filename                 ***
; *** RA - pointer to arguments     ***
; *** Returns: RD - file descriptor ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
           proc    execbin

scall:     equ     4
sret:      equ     5

           extrn   close
           extrn   errnoffnd
           extrn   execdir
           extrn   intfildes
           extrn   opened
           extrn   openexit
           extrn   scratch
           extrn   searchdir
           extrn   setupfd

           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           sep     scall               ; find directory
           dw      execdir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    execfail            ; jump if failed to get dir
           sep     scall               ; close the directory
           dw      close
           ldi     high intfildes       ; point to internal fildes
           phi     rd
           ldi     low intfildes
           plo     rd
           sep     scall               ; setup the descriptor
           dw      setupfd
           ldi     0                   ; signal success
           shr
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           lbr     opened
execfail:  ldi     1                   ; signal error
           shr
           ldi     errnoffnd
           lbr     openexit            ; then return

           endp

