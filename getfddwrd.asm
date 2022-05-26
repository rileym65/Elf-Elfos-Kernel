#include   macros.inc

           proc    getfddwrd

sret:      equ     5

           plo     re
           push    rd
           glo     re
           str     r2
           glo     rd
           add
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
           pop     rd
return:    sep     sret

           public  return

           endp

