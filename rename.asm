#include   macros.inc
           
; *************************************
; *** rename a file                 ***
; *** RF - filename                 ***
; *** RC - new filename             ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
           proc    rename

scall:     equ     4
sret:      equ     5

           extrn   close
           extrn   delexit
           extrn   finddir
           extrn   scratch
           extrn   readsys
           extrn   searchdir
           extrn   writesys

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
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rc                  ; save copy of destination filename
           stxd
           ghi     rc
           stxd
           sep     scall               ; find directory
           dw      finddir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    renfile             ; jump if file exists
           sep     scall               ; close the directory
           dw      close
           ldi     1                   ; signal an error
           irx                         ; drop filename from stack
           irx
           lbr     delexit             ; use exit from delete
renfile:   sep     scall               ; close the directory
           dw      close
           sep     scall               ; read driectory sector for file
           dw      readsys
           glo     r9                  ; point to filename
           adi     12
           plo     r9
           ghi     r9                  ; get offset into sector
           adci    1 
           phi     r9 
           irx                         ; recover new name
           ldxa
           phi     rf
           ldx
           plo     rf
renlp:     lda     rf                  ; get byte from name
           str     r9                  ; store into dir entry
           inc     r9                  ; point to next position
           lbnz    renlp               ; loop if a zero was not written
           sep     scall               ; write dir sector back
           dw      writesys
           ldi     0                   ; signal success
           lbr     delexit

           endp

