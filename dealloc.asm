#include    macros.inc

; **************************************
; ***** Deallocate memory          *****
; ***** RF - address to deallocate *****
; **************************************
            proc    dealloc

scall:      equ     4
sret:       equ     5
            extrn   alloc_ext
            extrn   heap
            extrn   himem

            push    r9                  ; save consumed registers
            push    rd
            push    rf
            dec     rf                  ; move to flags byte
            dec     rf
            dec     rf
            ldi     1                   ; mark block as free
            str     rf
heapgc:     push    rc
            push    rd
            ldi     heap.0              ; need start of heap
            plo     r9
            ldi     heap.1     
            phi     r9
            lda     r9                  ; retrieve heap start address
            phi     rd
            ldn     r9
            plo     rd
heapgc_s:   dec     r9
            ldn     rd                  ; see if first block was freed
            lbz     heapgc_dn           ; jump if end of heap encountered
            smi     1
            lbnz    heapgc_1            ; jump on first allocated block
            inc     rd                  ; retrieve block size
            lda     rd
            plo     re
            lda     rd
            str     r2                  ; and add to block
            glo     rd
            add
            plo     rd
            glo     re
            str     r2
            ghi     rd
            adc
            phi     rd
            str     r9                  ; write new heap start
            inc     r9
            glo     rd
            str     r9
            lbr     heapgc_s            ; loop back to check for more leading empty blocks
heapgc_1:   lda     rd                  ; retrieve flags byte
            lbz     heapgc_dn           ; return if end of heap found
            plo     re                  ; save copy of flags
            lda     rd                  ; retrieve block size
            phi     rc
            lda     rd
            plo     rc
            glo     rd                  ; RF=RD+RC, point to next block
            str     r2
            glo     rc
            add
            plo     rf
            ghi     rd
            str     r2
            ghi     rc
            adc
            phi     rf
            lda     rf                  ; retrieve flags for next block
            lbz     heapgc_dn           ; return if on last block
            ani     2                   ; is block allocated?
            lbnz    heapgc_a            ; jump if so
            glo     re                  ; check flags of current block
            ani     2                   ; is it allocated
            lbnz    heapgc_a            ; jump if so
            lda     rf                  ; retrieve next block size into RF
            plo     re
            lda     rf
            plo     rf
            glo     re
            phi     rf
            inc     rf                  ; add 3 bytes for header
            inc     rf
            inc     rf
            glo     rf                  ; RC += RF, combine sizes
            str     r2
            glo     rc
            add
            plo     rc
            ghi     rf
            str     r2
            ghi     rc
            adc
            phi     rc
            dec     rd                  ; write size of combined blocks
            glo     rc
            str     rd
            dec     rd
            ghi     rc
            str     rd
            dec     rd                  ; move back to flags byte
            lbr     heapgc_1            ; keep checking for merges
heapgc_a:   glo     rf                  ; move pointer to next block
            plo     rd
            ghi     rf
            phi     rd
            dec     rd                  ; move back to flags byte
            lbr     heapgc_1            ; and check next block
heapgc_dn:  pop     rd
            pop     rc
            pop     rf
            lbr     sethimem

sethimem:   push    rf
            push    rd
            mov     rf,heap+1
            mov     rd,himem+1
            ldn     rf
            smi     1
            str     rd
            dec     rf
            dec     rd
            ldn     rf
            smbi    0
            str     rd
            pop     rd
            pop     rf
            adi     0                   ; signal no error
            lbr     alloc_ext           ; return to caller

            public  heapgc
            public  sethimem

            endp

