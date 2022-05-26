#include   macros.inc
           
; *******************************
; *** Remove a directory      ***
; *** RF - Pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************
           proc    rmdir

scall:     equ     4
sret:      equ     5

           extrn   delexit
           extrn   delgo
           extrn   errdirnotempty
           extrn   errnoffnd
           extrn   error
           extrn   finalsl
           extrn   getfddrof
           extrn   getfddwrd
           extrn   o_opendir
           extrn   o_read
           extrn   readsys
           extrn   scratch

           sep     scall               ; check for final slash
           dw      finalsl
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
           ghi     ra
           phi     rf
           glo     ra
           plo     rf
           sep     scall               ; open the directory
           dw      o_opendir
           lbnf    rmdirlp             ; jump if dir opened
           ldi     errnoffnd           ; signal not found error
rmdirerr:  shl
           ori     1
           shr
           lbr     delexit             ; and return
rmdirlp:   ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           ldi     high scratch        ; where to put it
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; read the bytes
           dw      o_read
;           dw      read
           glo     rc                  ; see if eof was hit
           smi     32
           lbnz    rmdireof            ; jump if dir was empty
           ldi     high scratch        ; point to buffer
           phi     rf
           ldi     low scratch
           plo     rf
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lbr     rmdirlp             ; read rest of dir
rmdirno:   ldi     errdirnotempty      ; indicate not empty error
           lbr     rmdirerr            ; and error out
rmdireof:  ldi     9
           sep     scall
           dw      getfddwrd
;rmdireof:  sep     scall               ; get direcotry info from descriptor
;           dw      getfddrsc
           sep     scall               ; get direcotry info from descriptor
           dw      getfddrof
           sep     scall
           dw      readsys
           ghi     r9                  ; get offset into sector
           adi     1
           phi     r9
           inc     r9                  ; point to starting lump
           inc     r9
           lbr     delgo               ; and delete the dir

           endp

