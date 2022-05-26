#include   macros.inc

; *******************************
; *** Make directory          ***
; *** RF - pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************
           proc    mkdir

scall:     equ     4
sret:      equ     5

           extrn   close
           extrn   create
           extrn   errexists
           extrn   error
           extrn   finddir
           extrn   freedir
           extrn   intfildes
           extrn   o_open

           glo     rf                  ; save pathname address
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save pathname address
           stxd
           ghi     rd
           stxd
           glo     r7                  ; save pathname address
           stxd
           ghi     rf                  ; copy pathname address
           phi     rd
           glo     rf
           plo     rd
mkdirlp:   lda     rd                  ; look for terminator
           lbnz    mkdirlp
           dec     rd                  ; back to char before terminator
           dec     rd
           ldn     rd                  ; and retrieve it
           smi     '/'                 ; mkdir has no final slash
           lbnz    mkdir_go            ; jump if ok
           ldi     0                   ; remove final slash
           str     rd
mkdir_go:  ldi     high intfildes      ; temporariy fildes
           phi     rd
           ldi     low intfildes
           plo     rd
           ldi     0                   ; no flags
           plo     r7
           glo     rf                  ; save pathname
           stxd
           ghi     rf
           stxd
           sep     scall               ; attempt to open the file
           dw      o_open
           irx                         ; recover pathname
           ldxa
           phi     rf
           ldx
           plo     rf
           lbdf    mkdir1              ; jump if it does not exist
           irx                         ; recover consumed registers
           ldxa
           plo     r7
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           ldi     errexists           ; signal entry exists error
           lbr     error
mkdir1:    sep     scall               ; open directory
           dw      finddir
           glo     rc                  ; save new dir name
           stxd
           ghi     rc
           stxd
           sep     scall               ; find a free dir entry
           dw      freedir
           irx                         ; recover pathname
           ldxa
           phi     rf
           ldx
           plo     rf
           ldi     high intfildes      ; temporariy fildes
           phi     rc
           ldi     low intfildes
           plo     rc
           ldi     1                   ; create as directory
           plo     r7
           sep     scall               ; create it
           dw      create
           sep     scall               ; close the new dir
           dw      close
           irx                         ; recover consumed registers
           ldxa
           plo     r7
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           ldi     0                   ; signal success
           shr
           sep     sret                ; and return to caller

           endp

