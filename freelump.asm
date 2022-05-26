#include   macros.inc

; **************************************
; *** Get a free lump                ***
; *** Returns: RA - lump             ***
; ***          DF=0 - lump found     ***
; ***          DF=1 - lump not found *** 
; **************************************
           proc    freelump

scall:     equ     4
sret:      equ     5

           extrn   dta
           extrn   rawread
           extrn   secofslmp
           extrn   sector0
           extrn   sysfildes

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
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; read sector 0
           dw      sector0
           ldi     low dta             ; point to sector
           adi     5                   ; add 261, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           lda     rf                  ; get sector value
           phi     rb
           lda     rf
           plo     rb
           ldi     0                   ; zero high word
           phi     ra
           plo     ra
           phi     r8                  ; set search sector
           plo     r8
           phi     r7
           ldi     17
           plo     r7
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
freelump1: glo     rb                  ; check if end of lat table
           str     r2
           glo     r7
           sm
           lbnz    freelump2           ; jump if not
           ghi     rb                  ; check if end of lat table
           str     r2
           ghi     r7
           sm
           lbnz    freelump2           ; jump if not
           glo     ra                  ; check if end of lat table
           str     r2
           glo     r8
           sm
           lbnz    freelump2           ; jump if not
           ghi     ra                  ; check if end of lat table
           str     r2
           ghi     r8
           sm
           lbnz    freelump2           ; jump if not
           ldi     1                   ; signal no lump was found
freelumpe: shr                         ; shift result
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
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
freelump2: sep     scall               ; read next allocation sector
           dw      rawread
           ldi     high dta            ; point to dta
           phi     r9
           ldi     low dta
           plo     r9
           ldi     1                   ; 256 entries per sector
           phi     rc
           ldi     0
           plo     rc
freelump3: lda     r9                  ; get value from table
           lbnz    freelump4           ; jump if nonzero
           ldn     r9                  ; check low value
           lbnz    freelump4           ; jump if nonzero
           dec     r9                  ; reset offset
           ghi     r9                  ; subtract out buffer address
           smi     1
           phi     r9
           sep     scall               ; convert sector,offset to lump
           dw      secofslmp
           ldi     0                   ; signal a lump was found
           lbr     freelumpe           ; and return
freelump4:
           inc     r9                  ; point to next entry
           dec     rc                  ; decrement count
           glo     rc                  ; check if end
           lbnz    freelump3           ; loop back if more to check
           inc     r7                  ; increment sector number
           glo     r7                  ; see if rollover happened
           lbnz    freelump1           ; loop to sector if not
           ghi     r7                  ; see if rollover happened
           lbnz    freelump1           ; loop to sector if not
           inc     r8                  ; carry over increment
           lbr     freelump1

           endp

