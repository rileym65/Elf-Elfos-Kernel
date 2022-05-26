#include   macros.inc
           
; *************************
; *** Execute a program ***
; *** RF - command line ***
; *************************
           proc     exec

#include   ../bios.inc

           extrn    d_reapheap
           extrn    errnotexec
           extrn    error
           extrn    heap
           extrn    intfildes
           extrn    intflags
           extrn    lowmem
           extrn    retval
           extrn    o_read
           extrn    open
           extrn    scratch

           sep      scall                ; move past any leading spaces
           dw       f_ltrim
           ldn      rf                   ; get first character
           lbz      err                  ; jump if nothing to exec
           ghi      rf                   ; transfer address to args register
           phi      ra
           glo      rf
           plo      ra
execlp:    lda      ra                   ; need to find first <= space
           smi      33
           lbdf     execlp
           plo      re                   ; save code
           dec      ra                   ; write a terminator
           ldi      0
           str      ra
           inc      ra
           glo      re                   ; recover byte
           adi      33                   ; check if it was the terminator
           lbnz     execgo1              ; jump if not
           dec      ra                   ; otherwise point args at terminator
;exec:      lda      rf                   ; need to find first <=space
;           smi      33
;           lbdf     exec                 ; loop until found
;           ghi      rf                   ; transfer to args register
;           phi      ra
;           glo      rf
;           plo      ra
;           dec      rf                   ; point back to break
;           ldn      rf                   ; was it zero
;           lbnz     execgo1              ; jump if not
;           dec      ra                   ; make args point to terminator
;execgo1:   ldi      0                    ; and place a terminator
;           str      rf
;           ldi      high keybuf          ; place address of keybuffer in R6
;           phi      rf
;           ldi      low keybuf
;           plo      rf
execgo1:
           ldi      high intfildes       ; point to internal fildes
           phi      rd
           ldi      low intfildes
           plo      rd
           ldi      0                    ; flags
           plo      r7
           sep      scall                ; attempt to open the file
           dw       open
           lbnf     opened               ; jump if it was opened
err:       ldi      9                    ; signal file not found error
           shr
           sep      sret
opened:    mov      rf,intflags          ; need to get flags
           ldn      rf                   ; retrieve them
           ani      040h                 ; is file executable
           lbz      notexec              ; jump if not exeuctable file
           ldi      high scratch         ; scratch space to read header
           phi      rf
           ldi      low scratch
           plo      rf
           ldi      0                    ; need to read 6 bytes
           phi      rc
           ldi      6
           plo      rc
           sep      scall                ; read header
           dw       o_read
;           dw       read
           ldi      high scratch         ; point to load offset
           phi      r7
           ldi      low scratch
           plo      r7

           inc      r7                   ; lsb of load size
           inc      r7
           inc      r7
           ldn      r7                   ; retrieve it
           str      r2                   ; store for add
           dec      r7                   ; lsb of load addres
           dec      r7
           lda      r7                   ; retrieve it
           add                           ; add in size lsb
           plo      rf                   ; result in rf
           ldn      r7                   ; get msb of size
           str      r2                   ; store for add
           dec      r7                   ; point to msb of load address
           dec      r7
           ldn      r7                   ; retrieve it
           adc                           ; add in msb of size
           phi      rf                   ; rf now has highest address
           mov      rb,heap+1            ; now subtract heap address
           glo      rf                   ; lsb of high address
           str      r2                   ; store for subtract
           ldn      rb                   ; get lsb of heap address
           sm                            ; and subtract
           ghi      rf                   ; msb of high address
           str      r2                   ; store for subtract
           dec      rb                   ; msb of heap
           ldn      rb                   ; get heap address
           smb                           ; and subtract
           lbdf     opengood             ; jump if enough memory
           ldi      0bh                  ; signal memory low error
           shr
           sep      sret                 ; and return to caller

opengood:  lda      r7                   ; get load address
           phi      rf
           phi      rb                   ; and make a copy
           lda      r7
           plo      rf
           plo      rb
           lda      r7                   ; get size
           phi      rc
           lda      r7
           plo      rc
           push     rf
           mov      rf,lowmem
           ghi      rc
           adi      020h
           str      rf
           inc      rf
           glo      rc
           str      rf
           pop      rf
           sep      scall                ; read program block
           dw       o_read
;           dw       read
           ldi      high progaddr        ; point to destination of call
           phi      rf
           ldi      low progaddr
           plo      rf
           lda      r7                   ; get start address
           str      rf
           inc      rf
           lda      r7
           str      rf
           ghi      rb                   ; transfer load address to rf
           phi      rf
           glo      rb
           plo      rf
           sep      scall                ; call loaded program
progaddr:  dw       0
           plo     re                   ; save return value
           mov     r7,retval            ; point to retval
           glo     re                   ; write return value
           str     r7
           sep     scall                ; cull the heap
           dw      d_reapheap
           ldi     0                    ; signal no error
           shr
           sep      sret                 ; return to caller
notexec:   ldi      errnotexec           ; signal non-executable file
           lbr      error                ; and return

           public   opened

           endp

