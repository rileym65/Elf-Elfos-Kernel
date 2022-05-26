#include   macros.inc

           proc    kinit

scall:     equ     4
sret:      equ     5

           extrn   d_idereset
           extrn   lmpsize
           extrn   o_alloc
           extrn   path
           extrn   stackaddr

           sep     scall               ; get free memory
           dw      d_idereset
           ldi     high path           ; set path
           phi     rf
           ldi     low path
           plo     rf
           ldi     '/'
           str     rf
           inc     rf
           ldi     0
           str     rf

           mov     rc,252              ; want to allocate 252 bytes on the heap
           mov     r7,00004            ; allocate as a permanent block
           sep     scall               ; allocate the memory
           dw      o_alloc
           mov     r7,stackaddr+1      ; point to allocation pointer
           ldi     1                   ; mark interrupts enabled
           lsie                        ; skip if interrupts are enabled
           ldi     0                   ; mark interrupts disabled
           plo     re                  ; save IE flag
           ldi     023h                ; setup for DIS
           str     r2
           dis                         ; disable interrupts
           dec     r2
           glo     rf                  ; SP needs to be end of heap block
           adi     251
           str     r7                  ; write to pointer
           dec     r7
           plo     r2                  ; and into R2
           ghi     rf                  ; process high byte
           adci    0
           str     r7
           phi     r2
           glo     re                  ; recover IE flag
           lbz     kinit2              ; jump if interrupts disabled
           ldi     023h                ; setup for RET
           str     r2
           ret                         ; re-enable interrupts
           dec     r2
kinit2:    dec     r2                  ; need 2 less
           dec     r2
           sep     scall               ; get shift count for lump size
           dw      lmpsize
           sep     sret                ; return to caller

           endp

