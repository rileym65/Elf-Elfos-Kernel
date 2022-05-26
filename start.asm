#include   macros.inc

           proc    start

#include   ../bios.inc

           extrn   bootmsg
           extrn   crlf
           extrn   d_progend
           extrn   d_reapheap
           extrn   errnf
           extrn   exec
           extrn   execbin
           extrn   heap
           extrn   himem
           extrn   initprg
           extrn   keybuf
           extrn   kinit
           extrn   o_exec
           extrn   o_inputl
           extrn   o_msg
           extrn   o_setbd
           extrn   prompt
           extrn   retval
           extrn   shellprg
           extrn   stackaddr

           sep     scall               ; get free memory
           dw      f_freemem
           ldi     0                   ; put end of heap marker
           str     rf
           mov     r7,heap             ; point to hi memory pointer
           ghi     rf                  ; store highest memory address
           str     r7                  ; and store it
           inc     r7
           glo     rf
           str     r7
           dec     rf                  ; himem is heap-1
           ldi     himem.0
           plo     r7
           ghi     rf                  ; store highest memory address
           str     r7                  ; and store it
           inc     r7
           glo     rf
           str     r7
           sep     scall               ; call rest of kernel setup
           dw      kinit

           ldi     high initprg        ; point to init program command line
           phi     rf
           ldi     low initprg
           plo     rf
           sep     scall               ; attempt to execute it
           dw      o_exec
           lbnf    welcome             ; jump if no error
#ifndef ELF2K
default:   sep     scall               ; get terminal baud rate
           dw      o_setbd
#endif
welcome:   ldi     high bootmsg
           phi     rf
           ldi     low bootmsg
           plo     rf
           sep     scall
           dw      o_msg
     
warmboot:  plo     re                  ; save return value
           mov     rf,retval           ; point to retval
           glo     re                  ; write return value
           str     rf
           sex     r2                  ; be sure r2 points to stack
           ldi     1                   ; signal interrupts enabled
           lsie                        ; skip if interrupts are enabled
           ldi     0                   ; signal interupts are not enab led
           plo     re                  ; save interrupts flag
           ldi     023h                ; setup for DIS
           str     r2
           dis                         ; disable interrupts during change of R2
           dec     r2
           mov     rc,stackaddr        ; point to system stack address
           lda     rc                  ; and reset R2
           phi     r2
           lda     rc
           plo     r2
           glo     re                  ; recover interrupts flag
           lbz     warm2               ; jump if interrupts are not enabled
           ldi     023h                ; setup for RET
           str     r2
           ret                         ; re-enable interrupts
           dec     r2
           
;           ldi     high stack          ; reset the stack
;           phi     r2
;           ldi     low stack
;           plo     r2
warm2:     sep     scall               ; cull the heap
           dw      d_reapheap
           lbr     d_progend
warm3:     ldi     high shellprg       ; point to command shell name
           phi     rf
           ldi     low shellprg
           plo     rf
           sep     scall               ; and attempt to execute it
           dw      exec
; *************************
; *** Main command loop ***
; *************************
cmdlp:     ldi      high prompt          ; get address of prompt into R6
           phi      rf
           ldi      low prompt
           plo      rf
           sep      scall
           dw       o_msg                ; function to print a message


           ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf
           ldi      07fh                 ; limit keyboard input to 127 bytes
           plo      rc
           ldi      0
           phi      rc
           sep      scall
           dw       o_inputl             ; function to get keyboard input
           ldi      high crlf            ; get address of prompt into R6
           phi      rf
           ldi      low crlf  
           plo      rf
           sep      scall
           dw       o_msg                ; function to print a message

           ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf

           sep      scall                ; call exec function
           dw       exec
           lbdf     curerr               ; jump on error
           lbr      cmdlp                ; loop back for next command
 

curerr:    ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf

           sep      scall                ; call exec function
           dw       execbin
           lbdf     loaderr              ; jump on error
           lbr      cmdlp                ; loop back for next command
loaderr:   ldi      high errnf           ; point to not found message
           phi      rf
           ldi      low errnf
           plo      rf
           sep      scall                ; display it
           dw       o_msg
           lbr      cmdlp                ; loop back for next command

           public   warm3
           public   warmboot

           endp

