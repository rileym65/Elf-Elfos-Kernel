#include   macros.inc

; ************************************
; *** Setup new file descriptor    ***
; ***    RD - descriptor to setup  ***
; *** R8:R7 - dir sector           ***
; ***    R9 - dir offset           ***
; ***    RF - pointer to dir entry ***
; ************************************
           proc    setupfd

#include   ../bios.inc

           extrn   getfdflgs
           extrn   lumptosec
           extrn   rawread
           extrn   readlump
           extrn   scratch
           extrn   setfddwrd
           extrn   setfdeof
           extrn   setfdflgs
           extrn   setfddrof

           ldi     9
           sep     scall
           dw      setfddwrd
;setupfd:   sep     scall               ; set dir sector
;           dw      setfddrsc
           sep     scall               ; set dir offset
           dw      setfddrof
           ldi     0                   ; zero current offset
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           ldi     0
           sep     scall
           dw      setfddwrd
;           sep     scall
;           dw      setfdofs            ; set offset
           ldi     0ffh                ; need -1
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           ldi     15
           sep     scall
           dw      setfddwrd
;           sep     scall               ; set current sector
;           dw      setfdsec
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           inc     rf                  ; point to starting lump
           inc     rf
           lda     rf                  ; get starting lump
           phi     ra
           lda     rf
           plo     ra
           sep     scall               ; convert to sector
           dw      lumptosec
           sep     scall               ; read the first sector of the file
           dw      rawread
           inc     rf                  ; point to flags
           inc     rf
           ldn     rf                  ; get flags
           ani     7                   ; keep only bottom 3 bits
           shl                         ; shift into correct position
           shl
           shl
           shl
           shl
           ori     08h                 ; set initial flags
           sep     scall
           dw      setfdflgs
           dec     rf                  ; move dirent pointer back to eof
           dec     rf
           sep     scall               ; get lump value
           dw      readlump
           ghi     ra                  ; check end code
           smi     0feh
           lbnz    openeof
           glo     ra
           smi     0feh
           lbnz    openeof
;           ldi     0ch                 ; signal final lump
           sep     scall                ; get flags
           dw      getfdflgs
           ori     004h                 ; signal final lump
           sep     scall
           dw      setfdflgs
openeof:   lda     rf                  ; get eof
           phi     ra
           lda     rf
           plo     rf
           ghi     ra
           phi     rf
           sep     scall               ; setup eof
           dw      setfdeof
           sep     sret                ; return to caller

           endp

