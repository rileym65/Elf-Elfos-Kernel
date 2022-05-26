#include   macros.inc

           proc    setfddwrd

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
           inc     rd
           inc     rd
           inc     rd
           sex     rd
           glo     r7
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           str     rd
           sex     r2
           pop     rd
           sep     sret

           endp

