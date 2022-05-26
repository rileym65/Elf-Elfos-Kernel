#include    macros.inc

; *******************************************
; ***** Allocate memory                 *****
; ***** RC - requested size             *****
; ***** R7.0 - Flags                    *****
; *****      0 - Non-permanent block    *****
; *****      4 - Permanent block        *****
; ***** R7.1 - Alignment                *****
; *****      0 - no alignment           *****
; *****      1 - Even address           *****
; *****      3 - 4-byte boundary        *****
; *****      7 - 8-byte boundary        *****
; *****     15 - 16-byte boundary       *****
; *****     31 - 32-byte boundary       *****
; *****     63 - 64-byte boundary       *****
; *****    127 - 128-byte boundary      *****
; *****    255 - Page boundary          *****
; ***** Returns: RF - Address of memory *****
; *****          RC - Size of block     *****
; *******************************************
            proc    alloc

scall:      equ     4
sret:       equ     5
            extrn   checkeom
            extrn   heap
            extrn   return
            extrn   sethimem

            push    r9                  ; save consumed registers
            push    rd
            ldi     heap.0              ; get heap address
            plo     r9
            ldi     heap.1 
            phi     r9
            lda     r9
            phi     rd
            ldn     r9
            plo     rd
            dec     r9                  ; leave pointer at heap address
            ghi     r7
            lbnz    alloc_aln           ; jump if aligned block requested
alloc_1:    lda     rd                  ; get flags byte
            lbz     alloc_new           ; need new if end of table
            plo     re                  ; save flags
            lda     rd                  ; get block size
            phi     rf
            lda     rd
            plo     rf
            glo     re                  ; is block allocated?
            ani     2
            lbnz    alloc_nxt           ; jump if so
            glo     rc                  ; subtract size from block size
            str     r2
            glo     rf
            sm
            plo     rf
            ghi     rc
            str     r2
            ghi     rf
            smb
            phi     rf                  ; RF now has difference
            lbnf    alloc_nxt2          ; jumpt if block is too small
            ghi     rf                  ; see if need to split block
            lbnz    alloc_sp            ; jump if so
            glo     rf                  ; get low byte of difference
            ani     0f8h                ; want to see if at least 8 extra bytes
            lbnz    alloc_sp            ; jump if so
alloc_2:    glo     rd                  ; set address for return
            plo     rf
            ghi     rd
            phi     rf
            dec     rd                  ; move back to flags byte
            dec     rd
            dec     rd
            glo     r7                  ; get passed flags
            ori     2                   ; mark block as used
            str     rd
            inc     rd                  ; get allocated block size
            lda     rd
            phi     rc
            lda     rd
            plo     rc
            adi     0                   ; clear df
alloc_ext:
            pop     rd                  ; recover consumed registers
            pop     r9
            sep     sret                ; and return to caller
alloc_sp:   ghi     rd                  ; save this address
            stxd
            glo     rd
            stxd
            dec     rd                  ; move to lsb of block size
            glo     rc                  ; write requested size
            str     rd
            dec     rd
            ghi     rc                  ; write msb of size
            str     rd
            inc     rd                  ; move back to data
            inc     rd
            glo     rc                  ; now add size
            str     r2
            glo     rd
            add
            plo     rd
            ghi     rd
            str     r2
            ghi     rc
            adc
            phi     rd                  ; rd now points to new block
            ldi     1                   ; mark as a free block
            str     rd
            inc     rd
            dec     rf                  ; remove 3 bytes from block size
            dec     rf
            dec     rf
            ghi     rf                  ; and write into block header
            str     rd
            inc     rd
            glo     rf
            str     rd
            irx                         ; recover address
            ldxa
            plo     rd
            ldx
            phi     rd
            lbr     alloc_2             ; finish allocating
alloc_nxt2: glo     rc                  ; put rf back 
            str     r2
            glo     rf
            add
            plo     rf
            ghi     rc
            str     r2
            ghi     rf
            adc
            phi     rf
alloc_nxt:  glo     rf                  ; add block size to address
            str     r2
            glo     rd
            add
            plo     rd
            ghi     rf
            str     r2
            ghi     rd
            adc
            phi     rd
            lbr     alloc_1             ; check next cell
alloc_new:  lda     r9                  ; retrieve start of heap
            phi     rd
            ldn     r9
            plo     rd
            glo     rc                  ; subtract req. size from pointer
            str     r2
            glo     rd
            sm
            plo     rd
            ghi     rc
            str     r2
            ghi     rd
            smb
            phi     rd
            dec     rd
            dec     rd
            dec     rd
            sep     scall               ; check for out of memory
            dw      checkeom
            lbdf    alloc_ext           ; return to caller on error
            inc     rd                  ; point to lsb of block size
            inc     rd
            glo     rc                  ; write size
            str     rd
            dec     rd
            ghi     rc
            str     rd
            dec     rd
            glo     r7                  ; get passed flags
            ori     2                   ; mark as allocated block
            str     rd
            glo     rd                  ; set address
            plo     rf
            ghi     rd
            phi     rf
            inc     rf                  ; point to actual data space
            inc     rf
            inc     rf
            glo     rd                  ; write new heap address
            str     r9
            dec     r9
            ghi     rd
            str     r9
            lbr     sethimem
            sep     sret                ; return to caller
alloc_aln:  glo     rd                  ; keep copy of heap head in RF
            plo     rf
            ghi     rd
            phi     rf
            glo     rc                  ; subtract size from heap head
            str     r2
            glo     rd
            sm
            plo     rd
            ghi     rc
            str     r2
            ghi     rd
            smb
            phi     rd                  ; rd now pointing at head-size
            ghi     r7                  ; get alignement type
            xri     0ffh                ; invert the bits
            str     r2                  ; need to AND with address
            glo     rd
            and
            plo     rd                  ; RD now has aligned address
            str     r2                  ; now subtract new address from original to get block size
            glo     rf
            sm
            plo     rf
            ghi     rd
            str     r2
            ghi     rf
            smb
            phi     rf                  ; RF now holds new block size
            dec     rd
            dec     rd
            dec     rd
            sep     scall               ; check for out of memory
            dw      checkeom
            lbdf    return              ; return to caller on error
            inc     rd                  ; point to lsb of block size
            inc     rd
            glo     rf                  ; store block size in header
            str     rd
            dec     rd
            ghi     rf
            str     rd
            dec     rd                  ; rd now pointing to flags byte
            ldi     1                   ; mark as unallocated
            str     rd
            ghi     rd                  ; write new start of heap address
            str     r9
            inc     r9
            glo     rd
            str     r9
            dec     r9
            lbr     alloc_1             ; now allocate the block

            public  alloc_ext
            endp

