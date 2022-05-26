#include   macros.inc
           
; *************************************
; *** delete a file                 ***
; *** RF - filename                 ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
           proc    delete

scall:     equ     4
sret:      equ     5

           extrn   close
           extrn   delchain
           extrn   errisdir
           extrn   finddir
           extrn   readsys
           extrn   scratch
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
           sep     scall               ; find directory
           dw      finddir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    delfile             ; jump if file exists
           sep     scall               ; close the directory
           dw      close
           ldi     1                   ; signal an error
delexit:   shr                         ; shift result into DF
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rd
           ldxa
           plo     rd
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
           sep     sret                ; return to caller
delfile:   sep     scall               ; close the directory
           dw      close
           sep     scall               ; read driectory sector for file
           dw      readsys
           ghi     r9                  ; get offset into sector
           adi     1 
           phi     r9 
           inc     r9                  ; point to flags
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           ldn     r9                  ; get flags
           ani     1                   ; see if directory
           lbnz    delfildir           ; jump if so
           dec     r9                  ; point to starting lump
           dec     r9
           dec     r9
           dec     r9
delgo:     ldn     r9                  ; retrieve it
           phi     ra
           ldi     0                   ; and zero in dir entry
           str     r9
           inc     r9
           ldn     r9
           plo     ra
           ldi     0
           str     r9
           sep     scall               ; write dir sector back
           dw      writesys
           sep     scall               ; delete the chain
           dw      delchain
           ldi     0                   ; signal success
           lbr     delexit
delfildir: ldi     1                   ; setup error code
           shr
           ldi     errisdir
           shlc
           lbr     delexit             ; and return

           public  delexit
           public  delgo

           endp

