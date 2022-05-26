#include   macros.inc

; *****************************
; *** Validate filename     ***
; *** RF - filename         ***
; *** Returns: DF=1 invalid ***
; ***          DF=0 valid   ***
; *****************************
           proc    validate

#include   ../bios.inc

           ldn     rf                  ; check for zero length
           lbz     invalid             ; jump on invalid entry
           glo     rf                  ; save position
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
slash:     ldi     0                   ; setup character count
           plo     rc
valid_lp:  lda     rf                  ; get next byte
           lbz     isvalid             ; jump if terminator found
           inc     rc                  ; increment count
           sep     scall               ; see if alphanumeric
           dw      f_isalnum
           lbdf    valid_lp
           plo     re                  ; save a copy
           smi     '-'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '_'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '.'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '/'                 ; check other valid characters
           lbnz    invalid             ; otherwise invalid
           lbr     slash               ; reset counter on directory separator
isvalid:   glo     rc                  ; get count
           lbz     invalid             ; zero lenght is invalid
           smi     19                  ; must be under 19 characters
           lbdf    invalid
           adi     0                   ; indicate valid filename
           lskp                        ; recover filename address
invalid:   smi     0                   ; indicate invalid file
val_ret:   irx                         ; recover rf
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return

           endp

