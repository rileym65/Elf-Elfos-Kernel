#include   macros.inc

; *************************************
; *** open a file                   ***
; *** RF - filename                 ***
; *** RD - file descriptor          ***
; *** R7 - flags                    ***
; *** Returns: RD - file descriptor ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
           proc    open

#include   ../bios.inc

           extrn   close
           extrn   create
           extrn   delchain
           extrn   finddir
           extrn   freedir
           extrn   loadsec
           extrn   scratch
           extrn   searchdir
           extrn   seekend
           extrn   setupfd
           extrn   validate
           extrn   writelump

           sep     scall               ; validate filename
           dw      validate
           lbdf    noopen              ; failed
           push    r7                  ; save consumed registers
           push    r8
           push    r9
           push    ra
           push    rb
           push    rc
           push    rd
           glo     r7                  ; get copy of flags
           stxd                        ; and save
           sep     scall               ; find directory
           dw      finddir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    newfile             ; jump if file needs creation
           irx                         ; remove flags from stack
           ldx                         ; get flags
           dec     r2                  ; and keep on stack
           ani     2                   ; see if need to truncate file
           lbz     opencnt             ; jump if not
           glo     rf                  ; save buffer position
           stxd
           ghi     rf
           stxd
           inc     rf                  ; point to starting lump
           inc     rf
           lda     rf                  ; get starting lump
           phi     ra
           lda     rf
           plo     ra
           ldi     0                   ; need to zero eof
           str     rf
           inc     rf
           str     rf
           sep     scall               ; delete the files chain
           dw      delchain
           ldi     0feh                ; signal end of chain
           phi     rf
           plo     rf
           sep     scall               ; write lump value
           dw      writelump
           irx                         ; recover buffer position
           ldxa
           phi     rf
           ldx
           plo     rf
opencnt:   sep     scall               ; close the directory
           dw      close
           irx                         ; recover flags
           ldxa
           plo     re
           ldxa                        ; recover descriptr
           phi     rd
           ldx
           plo     rd
           glo     re                  ; save flags
           stxd

           sep     scall               ; setup the descriptor
           dw      setupfd

           irx                         ; recover flags
           ldx
           ani     4                   ; see if append mode
           lbz     opendone            ; jump if not
           sep     scall               ; seek to end
           dw      seekend
           sep     scall               ; load correct sector
           dw      loadsec
opendone:  ldi     0                   ; signal success
           shr
openexit:  irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller
newfile:   irx                         ; recover flags
           ldx
           plo     re                  ; keep a copy
           ani     1                   ; see if create is allowed
           lbnz    allow               ; allow the create
           ldi     1                   ; need to signal an error
           shr
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           lbr     openexit
allow:     ldi     0                   ; no file flags
           plo     r7
           glo     re
           ani     8                   ; see if executable file needs to be set
           lbz     allow2              ; jump if not
           ldi     2                   ; set flags for executable file
           plo     r7
allow2:    glo     rc                  ; save filename address
           stxd
           ghi     rc
           stxd
           glo     r7                  ; save flags
           stxd
           sep     scall               ; find a free dir entry
           dw      freedir
           irx                         ; recover flags
           ldxa
           plo     r7
           ldxa                        ; recover filename
           phi     rf
           ldxa
           plo     rf
           ldxa                        ; recover new descriptor
           phi     rc
           ldx
           plo     rc
           sep     scall               ; create the file
           dw      create
           ldi     0                   ; signal success
           shr
           lbr     openexit            ; and return
noopen:    smi     0                   ; signal file not opened
           sep     sret                ; and return

           public  noopen
           public  openexit

           endp

