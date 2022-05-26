#include   macros.inc

; ***************************************
; *** Check for valid file descriptor ***
; *** RD - file descriptor            ***
; *** Returns: DF=0 - valid FILDES    ***
; ***          DF=1 - Invalid FILDES  ***
; ***************************************
           proc    chkvld

sret:      equ     5

           push    rd                  ; save file descriptor position
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           plo     re                  ; save it for a moment
           pop     rd                  ; recover file descriptor
           glo     re                  ; recover flags
           ani     08h                 ; if FILDES marked valid
           lbz     chkvldno            ; jump if not
           ldi     0                   ; mark good
           shr
           sep     sret                ; and return
chkvldno:  ldi     1                   ; mark invalid
           shr
           sep     sret                ; and return

           endp

