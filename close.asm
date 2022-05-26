#include   macros.inc
       
; **************************************
; *** Close a file                   ***
; *** RD - file descriptor           ***
; *** Returns: DF=0 - success        ***
; ***          DF=1 - error          ***
; ***                 D - Error code ***
; **************************************
           proc    close

scall:     equ     4
sret:      equ     5

           extrn   checkwrt
           extrn   chkvld
           extrn   dta
           extrn   ff_archive
           extrn   gettmdt
           extrn   readsys
           extrn   writesys

           sep     scall               ; make sure FILDES is valid
           dw      chkvld
           lbnf    closego             ; jump if good
           ldi     1                   ; otherwise signal error
           shr
           ldi     2                   ; invalid FILDES error
           sep     sret                ; return to caller
closego:   sep     scall               ; see if sector needs to be written
           dw      checkwrt
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           ani     16                  ; see if file was written to
           lbnz    close1              ; jump if so
closeex:   glo     rd                  ; restore descriptor
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           ldi     0                   ; signal no error
           shr
           sep     sret                ; return to caller
close1:    inc     rd                  ; point to dir sector
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           lda     rd                  ; retrieve dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           sep     scall               ; read the sector
           dw      readsys
           lda     rd                  ; get dir offset high byte
           stxd                        ; place into memory
           lda     rd                  ; get low byte
           str     r2                  ; and keep for add
           ldi     low dta             ; get system dta
           add                         ; add in diroffset
           plo     r9
           irx                         ; point to high byte of offset
           ldi     high dta
           adc
           phi     r9                  ; r9 now has dir offset
           inc     r9                  ; point to eof field
           inc     r9
           inc     r9
           inc     r9
           glo     rd                  ; move descriptor to eof field
           smi     9 
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           lda     rd                  ; get high byte of eof
           str     r9                  ; store into dir entry
           inc     r9
           lda     rd 
           str     r9
           inc     r9
           ldn     r9                  ; get flags
           ori     ff_archive          ; set archive bit
           str     r9                  ; and write it back
           inc     r9                  ; move past flags
           sep     scall               ; get current date/time
           dw      gettmdt
           ghi     ra                  ; write date/time to dir entry
           str     r9
           inc     r9
           glo     ra
           str     r9
           inc     r9
           ghi     rb                  ; write date/time to dir entry
           str     r9
           inc     r9
           glo     rb
           str     r9
           sep     scall               ; write the sector back
           dw      writesys
           irx                         ; recover consumed registers
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
           lbr     closeex             ; and exit

           endp

