#include   macros.inc

; ************************************************
; *** Initialize all vectors and data pointers ***
; ************************************************
           proc    coldboot

           extrn   o_initcall
           extrn   start
      
           ldi     high start          ; get return address for setcall
           phi     r6
           ldi     low start
           plo     r6
           ldi     020h                ; setup temporary stack
           phi     r2
           ldi     255
           plo     r2
           sex     r2                  ; point x to stack
           lbr     o_initcall          ; setup call and return

           endp

