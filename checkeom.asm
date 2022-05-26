#include    macros.inc

; ****************************************
; ***** Check for out of memory      *****
; ***** DF=1 if allocation too large *****
; ****************************************
            proc    checkeom

scall:      equ     4
sret:       equ     5
            extrn   heap
            extrn   lowmem

            push    rc
            push    r9
            ldi     lowmem.0            ; get lowmem
            plo     r9
            ldi     lowmem.1
            phi     r9
            lda     r9                  ; retrieve variable table end
            phi     rc
            lda     r9
            plo     rc
            ldi     heap.0              ; point to heap start
            plo     r9
            ldi     heap.1     
            phi     r9
            inc     r9                  ; point to lsb
            ldn     r9                  ; get heap
            str     r2
            glo     rc                  ; subtract from variable table end
            sm
            dec     r9                  ; point to msb
            ldn     r9                  ; retrieve it
            str     r2
            ghi     rc                  ; subtract from variable table end
            smb
            lbdf    oom                 ; jump of out of memory
            adi     0                   ; clear df
oomret:     pop     r9
            pop     rc
            sep     sret                ; and return to caller
oom:        smi     0                   ; set df 
            lbr     oomret

            endp
