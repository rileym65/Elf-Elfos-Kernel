#include   macros.inc

; ****************************************************
; ***** Deallocate any non-permanent heap blocks *****
; ****************************************************
            proc    reapheap

            extrn   heap
            extrn   heapgc

            push    r9                  ; save consumed registers
            push    rd
            push    rf
            ldi     heap.0              ; need start of heap
            plo     rd
            ldi     heap.1    
            phi     rd
            lda     rd                  ; retrieve heap start address
            phi     rf
            ldn     rd
            plo     rf
hpcull_lp:  ldn     rf                  ; get flags byte
            lbz     heapgc              ; If end, garbage collect the heap
            ani     4                   ; check for permanent block
            lbnz    hpcull_nx           ; jump if allocated and permanent
            ldi     1                   ; mark block as free
            str     rf
hpcull_nx:  inc     rf                  ; get block size
            lda     rf
            plo     re
            lda     rf
            str     r2                  ; and add to pointer
            glo     rf
            add
            plo     rf
            glo     re
            str     r2
            ghi     rf
            adc
            phi     rf
            lbr     hpcull_lp           ; loop until end of heap

            endp

