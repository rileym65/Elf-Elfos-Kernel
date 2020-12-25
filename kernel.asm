; *******************************************************************
; *** This software is copyright 2006 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; #define  ELF2K

         org     300h
         include  bios.inc
scratch: equ     0
keybuf:  equ     0380h
dta:     equ     100h

vcursec:   equ     00f0h
vsecbuf:   equ     00f4h
vhighmem:  equ     00feh

errexists: equ     1
errnoffnd: equ     2
errinvdir: equ     3
errisdir:  equ     4
errdirnotempty: equ   5

o_cdboot:  lbr     coldboot
o_wrmboot: lbr     warmboot
o_open:    lbr     open
o_read:    lbr     read
o_write:   lbr     write
o_seek:    lbr     seek
o_close:   lbr     close
o_opendir: lbr     opendir
o_delete:  lbr     delete
o_rename:  lbr     rename
o_exec:    lbr     exec
o_mkdir:   lbr     mkdir
o_chdir:   lbr     chdir
o_rmdir:   lbr     rmdir
o_rdlump:  lbr     readlump
o_wrtlump: lbr     writelump
o_type:    lbr     d_type
o_msg:     lbr     d_msg
o_readkey: lbr     d_readkey
o_input:   lbr     d_input
o_prtstat: lbr     d_pstat
o_print:   lbr     d_print
o_execdef: lbr     execbin
o_setdef:  lbr     setdef
o_kinit:   lbr     kinit

error:     shl                         ; move error over
           ori     1                   ; signal error condition
           shr                         ; shift over and set DF
           sep     sret                ; return to caller

           org     400h
version:   db      0,3,0

include    build.inc
include    date.inc

sysfildes: db      0,0,0,0             ; current offset
           dw      0100h               ; dta
           dw      0                   ; eof
           db      0                   ; flags
           db      0,0,0,0             ; dir sector
           dw      0                   ; dir offset
           db      255,255,255,255     ; current sector
mdfildes:  db      0,0,0,0             ; current offset
           dw      mddta               ; dta
           dw      0                   ; eof
           db      0                   ; flags
           db      0,0,0,0             ; dir sector
           dw      0                   ; dir offset
           db      255,255,255,255     ; current sector
intfildes: db      0,0,0,0             ; current offset
           dw      intdta              ; dta
           dw      0                   ; eof
           db      0                   ; flags
           db      0,0,0,0             ; dir sector
           dw      0                   ; dir offset
           db      255,255,255,255     ; current sector
himem:     dw      0
d_type:    lbr     f_type              ; jump to bios type routine
d_msg:     lbr     f_msg               ; jump to bios msg routine
           db      0,0,0,0,0,0,0,0,0,0
d_readkey: lbr     f_read              ; jump to bios read routine
d_input:   lbr     f_input             ; jump to bios input routine
           db      0,0,0,0,0,0,0,0,0,0
d_pstat:   lbr     return              ; jump to bios read routine
d_print:   lbr     return              ; jump to bios input routine
           db      0,0,0,0,0,0,0,0,0,0
curdrive:  db      0
date_time: db      7,31,34,0,0,0
path2:     ds      128

           org     0500h

; ***************************************
; *** Get offset from file descriptor ***
; *** RD - file descriptor            ***
; *** Returns: R8:R7 - current offset ***
; ***************************************
getfdofs:  lda     rd                  ; retrieve offset
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
fdminus3:  dec     rd                  ; restore pointer
           dec     rd
           dec     rd
return:    sep     sret                ; return to caller

; ***************************************
; *** Set offset from file descriptor ***
; *** RD - file descriptor            ***
; *** R8:R7 - current offset          ***
; ***************************************
setfdofs:  ghi     r8                  ; save offset into descriptor
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           br      fdminus3

; ************************************
; *** Get dta from file descriptor ***
; *** RD - file descriptor         ***
; *** Returns: RF - dta            ***
; ************************************
getfddta:  inc     rd                  ; move descriptor to dta
           inc     rd
           inc     rd
           inc     rd
           lda     rd                  ; get high byte of dta
           phi     rf                  ; store into result
           ldn     rd                  ; get low byte
           plo     rf                  ; and store
fdminus5:  dec     rd                  ; restore descriptor
           dec     rd
           dec     rd
           dec     rd
           dec     rd
           sep     sret                ; and return to caller

; **********************************
; *** Set dta in file descriptor ***
; *** RD - file descriptor       ***
; *** RF - dta                   ***
; **********************************
setfddta:  inc     rd                  ; move descriptor to dta
           inc     rd
           inc     rd
           inc     rd
           ghi     rf                  ; write dta to descriptor
           str     rd
           inc     rd
           glo     rf
           str     rd
           br      fdminus5            ; and return

; ********************************
; *** Get eof file descriptor  ***
; *** RD - file descriptor     ***
; *** Returns: RF - eof offset ***
; ********************************
getfdeof:  glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     rf
           ldn     rd
           plo     rf
fdminus7:  glo     rd                  ; move pointer back to beginning
           smi     7
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; ********************************
; *** Set eof file descriptor  ***
; *** RD - file descriptor     ***
; *** RF - eof                 ***
; ********************************
setfdeof:  glo     rd                  ; move descriptor to eof
           adi     6
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     rf
           str     rd
           inc     rd
           glo     rf
           str     rd
           br      fdminus7

; **************************************
; *** Get flags from file descriptor ***
; *** RD - file descriptor           ***
; *** Returns D - flags              ***
; **************************************
getfdflgs: glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags
fdminus8:  plo     re                  ; save D
           glo     rd                  ; move pointer back to beginning
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           glo     re                  ; recover D
           sep     sret                ; and return to caller

; ************************************
; *** Set flags in file descriptor ***
; *** RD - file descriptor         ***
; ***  D - flags                   ***
; ************************************
setfdflgs: plo     re                  ; save D
           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           glo     re                  ; recover D
           str     rd                  ; store into descriptor
           br      fdminus8            ; and return

; *******************************************
; *** Get dir sector from file descriptor ***
; *** RD - file descriptor                ***
; *** Returns: R8:R7 - dir sector         ***
; *******************************************
getfddrsc: glo     rd                  ; move descriptor to flags
           adi     9
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
fdminus12: glo     rd                  ; move pointer back to beginning
           smi     12
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; *******************************************
; *** Set dir sector in file descriptor   ***
; *** RD - file descriptor                ***
; *** R8:R7 - dir sector                  ***
; *******************************************
setfddrsc: glo     rd                  ; move descriptor to flags
           adi     9
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r8                  ; store dir sector
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           br      fdminus12           ; and return

; *******************************************
; *** Get dir offset from file descriptor ***
; *** RD - file descriptor                ***
; *** Returns: R9 - dir offset            ***
; *******************************************
getfddrof: glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get dir sector
           phi     r9
           ldn     rd
           plo     r9
fdminus14: glo     rd                  ; move pointer back to beginning
           smi     14
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; *******************************************
; *** Set dir offset in file descriptor   ***
; *** RD - file descriptor                ***
; *** R9 - dir offset                     ***
; *******************************************
setfddrof: glo     rd                  ; move descriptor to flags
           adi     13
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r9
           str     rd
           inc     rd
           glo     r9
           str     rd
           br      fdminus14

; *******************************************
; *** Get cur sector from file descriptor ***
; *** RD - file descriptor                ***
; *** Returns: R8:R7 - cur sector         ***
; *******************************************
getfdsec:  glo     rd                  ; move descriptor to flags
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           ldn     rd
           plo     r7
fdminus18: glo     rd                  ; move pointer back to beginning
           smi     18
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; *******************************************
; *** Set cur sector in file descriptor   ***
; *** RD - file descriptor                ***
; *** R8:R7 - cur sector                  ***
; *******************************************
setfdsec:  glo     rd                  ; move descriptor to flags
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r8                  ; store current sector
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           br      fdminus18           ; and return

; ******************************
; *** Convert sector to lump ***
; *** R8:R7 - Sector         ***
; *** Returns: RA - Lump     ***
; ******************************
sectolump: glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           ldi     high lmpshift       ; need to see how many shifts are needed
           phi     rb
           ldi     low lmpshift
           plo     rb
           ldn     rb                  ; retrieve shift count
           plo     re                  ; and set into shift counter
           glo     r8                  ; move sector to lump
           plo     rb
           ghi     r8
           phi     rb
           ghi     r7
           phi     ra
           glo     r7
           plo     ra
lmptosec1: ghi     rb                  ; perform shift
           shr
           phi     rb
           glo     rb
           shrc
           plo     rb
           ghi     ra
           shrc
           phi     ra
           glo     ra
           shrc
           plo     ra
           dec     re                  ; decrement shift count
           glo     re                  ; see if at end
           lbnz    lmptosec1           ; loop back if more shifts needed
           irx                         ; recover consumed registers
           ldxa
           phi     rb
           ldx
           plo     rb
           sep     sret                ; return to caller

; *******************************
; *** Convert lump to sector  ***
; *** RA - lump               ***
; *** Returns: R8:R7 - Sector ***
; *******************************
lumptosec: ldi     high lmpshift       ; need to see how many shifts are needed
           phi     r8
           ldi     low lmpshift
           plo     r8
           ldn     r8                  ; get shift count
           plo     re                  ; and put into shift counter
           glo     ra                  ; transfer lump to sector
           plo     r7
           ghi     ra
           phi     r7
           ldi     0                   ; zero high word
           phi     r8
           plo     r8
sectolmp1: glo     r7                  ; perform shift
           shl
           plo     r7
           ghi     r7
           shlc
           phi     r7
           glo     r8
           shlc
           plo     r8
           dec     re                  ; decrement shift count
           glo     re                  ; check for completion
           lbnz    sectolmp1           ; loop back if more shifts needed
           sep     sret                ; return to caller

; *******************************************
; *** Convert latSector,latOffset to lump ***
; *** R8:R7 - lat Sector                  ***
; ***    R9 - lat Offset                  ***
; *** Returns: RA - lump                  ***
; *******************************************
secofslmp: glo     r7                  ; subtract 17 from sector number
           smi     17
           phi     ra                  ; place into ra (* 256)
           ghi     r9                  ; offset divided by 2
           shr
           glo     r9
           shrc
           plo     ra
           sep     sret                ; return to caller

; ********************************************
; *** Convert lump to latSector, latOffset ***
; *** RA - lump                            ***
; *** Returns: R8:R7 - lat sector          ***
; ***             R9 - lat offset          ***
; ********************************************
lmpsecofs: glo     ra                  ; get low byte of lump
           shl                         ; multiply by 2
           plo     r9                  ; put into offset
           ldi     0
           shlc                        ; propagate carry
           phi     r9                  ; R9 now has lat offset
           ghi     ra                  ; get high byte of lump
           adi     17                  ; add in base of lat table
           plo     r7                  ; place into r7
           ldi     0
           adci    0                   ; propagate the carry
           phi     r7
           ldi     0                   ; need to zero R8
           phi     r8
           plo     r8
           sep     sret                ; return to caller

; ************************************************
; *** Determine if sector is already in buffer ***
; *** R8:R7 - Request sector                   ***
; ***    RD - File descriptor                  ***
; *** Returns: DF=1 - Sector already loaded    ***
; ***          DF=0 - Sector not loaded        ***
; ************************************************
secloaded: glo     rd                  ; save descriptor address
           stxd
           adi     15                  ; point to current sector
           plo     rd
           ghi     rd
           stxd
           adci    0                   ; propagate carry
           phi     rd
           lda     rd                  ; get byte from descriptor
           str     r2                  ; place onto stack
           ghi     r8                  ; high,high of sector
           sm                          ; compare against descriptor
           bnz     secnot              ; jump if no match
           lda     rd                  ; get next byte
           str     r2
           glo     r8                  ; high,low of sector
           sm
           bnz     secnot
           lda     rd                  ; get next byte
           str     r2
           ghi     r7                  ; low,high of sector
           sm
           bnz     secnot
           lda     rd                  ; last byte from descriptor
           str     r2
           glo     r7                  ; low,low of sector
           sm
           bnz     secnot
           ldi     1                   ; need to set df, sector is loaded
seccont:   shr                         ; shift result into df
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller
secnot:    ldi     0                   ; need to reset df, sector not loaded
           br      seccont             ; continue

; ***************************************
; *** Write raw sector                ***
; *** R8:R7 - Sector address to write ***
; ***    RD - File descriptor         ***
; ***************************************
rawwrite:
           ghi     r8                  ; check for valid sector
           smi     0ffh
           lbnz    rawwrite1
           glo     r8
           smi     0ffh
           lbnz    rawwrite1
           ghi     r7
           smi     0ffh
           lbnz    rawwrite1
           glo     r7
           smi     0ffh
           lbnz    rawwrite1
           sep     sret                ; sector not valid, return
rawwrite1: glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save consumed register
           stxd
           adi     4                   ; also point to dta
           plo     rd
           ghi     rd
           stxd
           adci    0
           phi     rd
           lda     rd                  ; get dta
           phi     rf                  ; and place into rf
           lda     rd
           plo     rf
           ghi     r8                  ; save r8
           stxd
           ori     0e0h                ; force lba mode
           phi     r8
           sep     scall               ; call bios to write sector
           dw      f_idewrite
           irx                         ; recover high r8
           ldxa
           phi     r8
           inc     rd                  ; point to flags byte
           inc     rd
           ldn     rd                  ; get flags
           ani     0feh                ; clear written flag
           str     rd                  ; and put back
           glo     rd                  ; move to current sector
           adi     7
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r8                  ; write current sector into descriptor
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           ldxa                        ; recover consumed registers
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

; *****************************************
; *** See if sector needs to be written ***
; *** RD - file descriptor              ***
; *****************************************
checkwrt:
           glo     rd                  ; need to point to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags

           shr                         ; shift first bit into DF
           lbdf    checkwrt1           ; jump if bet was set

;           ani     1                   ; see if sector has been written to
;           lbnz    checkwrt1           ; jump if so
           glo     rd                  ; restore descriptor
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller
checkwrt1: glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     rd                  ; point descripter to current sector
           adi     7
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; place descriptor back at beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     scall               ; write the sector
           dw      rawwrite
           irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

; ***************************************
; *** Read raw sector                 ***
; *** R8:R7 - Sector address to write ***
; ***    RD - File descriptor         ***
; ***************************************
rawread:
           sep     scall               ; see if requested sector is already in
           dw      secloaded
           lbnf    rawread1            ; jump if not
           sep     sret                ; otherwise return to caller
rawread1:  sep     scall               ; see if loaded sector needs writing
           dw      checkwrt
           glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd
           glo     rd                  ; save consumed register
           stxd
           adi     4                   ; also point to dta
           plo     rd
           ghi     rd
           stxd
           adci    0
           phi     rd
           lda     rd                  ; get dta
           phi     rf                  ; and place into rf
           lda     rd
           plo     rf
           ghi     r8                  ; save r8
           stxd
           ori     0e0h                ; force lba mode
           phi     r8
           sep     scall               ; call bios to read sector
           dw      f_ideread
           irx                         ; recover high r8
           ldx
           phi     r8
           inc     rd                  ; point to flags byte
           inc     rd
           ldn     rd                  ; get flags
           ani     0feh                ; clear written flag
           str     rd                  ; and put back
           glo     rd                  ; move to current sector
           adi     7
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ghi     r8                  ; write current sector into descriptor
           str     rd
           inc     rd
           glo     r8
           str     rd
           inc     rd
           ghi     r7
           str     rd
           inc     rd
           glo     r7
           str     rd
           irx
           ldxa                        ; recover consumed registers
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

; *************************************
; *** write sector using sysfildes  ***
; *** R8:R7 - sector to write       ***
; *************************************
writesys:  glo     rd
           stxd
           ghi     rd
           stxd
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawwrite
           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller

; *************************************
; *** read sector using sysfildes   ***
; *** R8:R7 - sector to read        ***
; *************************************
readsys:   glo     rd
           stxd
           ghi     rd
           stxd
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawread
           irx                         ; restore consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; return to caller

; *************************************
; *** Load sector 0                 ***
; *************************************
sector0:
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           ldi     0                   ; need to read sector 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; read system sector
           dw      readsys
           irx                         ; restore consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

; **************************************************
; *** Set shift count for current disk lump size ***
; **************************************************
lmpsize:   sep     scall               ; need system sector
           dw      sector0
           ldi     02                  ; need value at 20Ah in system buffer
           phi     rf
           ldi     0ah
           plo     rf
           ldn     rf                  ; now have sectors per lump
           plo     rf                  ; set here
           ldi     0                   ; signify no shifts done
           plo     re                  ; re will be shift counter
lmpsize1:  inc     re                  ; increment shift count
           glo     rf                  ; shift count
           shr
           plo     rf
           lbnz    lmpsize1            ; loop until count is zero
           dec     re                  ; correct for zero shifts
           ldi     high lmpshift       ; need to store value
           phi     rf
           ldi     low lmpshift
           plo     rf
           glo     re                  ; get shift count
           str     rf                  ; and save it

           ldi     01h                 ; initial mask
           plo     rf                  ; setup mask
lmpsize2:  glo     re                  ; see if done with shifts
           lbz     lmpsize3            ; jump if so
           dec     re                  ; decrement shift count
           glo     rf                  ; shift mask left
           shl
           ori     1                   ; set low bit
           plo     rf                  ; and put back
           lbr     lmpsize2            ; loop back to finish shifts
lmpsize3:  glo     rf                  ; transfer result
           plo     re
           ldi     high lmpmask        ; need to get lmpshift
           phi     rf
           ldi     low lmpmask
           plo     rf
           glo     re                  ; retrieve mask
           str     rf                  ; and store it.
           sep     sret                ; return to caller
        


; **********************************
; *** Get starting lump for file ***
; *** RD - file descriptor       ***
; *** Returns: RA - lump         ***
; **********************************
startlump:
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     rd                  ; point to dirSector
           adi     9
           stxd                        ; and save on stack
           plo     rd
           ghi     rd
           adci    0
           stxd
           phi     rd
           lda     rd                  ; retrieve dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the directory sector
           dw      rawread
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           inc     rd                  ; point to end of offset
           inc     rd
           inc     rd
           inc     rd
           inc     rd
           ldi     low dta             ; get system dta
           str     r2                  ; add in offset
           ldn     rd
           dec     rd
           add
           plo     r7                  ; use r7 as pointer
           ldi     high dta
           str     r2
           ldn     rd
           adc
           phi     r7
           inc     r7                  ; move to starting lump
           inc     r7
           lda     r7                  ; get starting lump
           phi     ra
           ldn     r7
           plo     ra
           irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           glo     rd                  ; restore rd to beginning
           smi     13
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; and return to caller

; **************************
; *** Write value to lat ***
; *** RA - lump          ***
; *** RF - value         ***
; **************************
writelump: glo     ra                  ; do not allow write of lump 0
           lbnz    writelmp
           ghi     ra
           lbnz    writelmp
           sep     sret
writelmp:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs
           ldi     high sysfildes      ; get system dta
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawread
           ldi     low dta             ; get dta
           str     r2                  ; add in offset
           glo     r9
           add
           plo     ra                  ; place into pointer
           ldi     high dta
           str     r2
           ghi     r9
           adc
           phi     ra
           ghi     rf                  ; write value
           str     ra
           inc     ra
           glo     rf
           str     ra
           sep     scall
           dw      rawwrite            ; write sector back to disk
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rd
           ldxa
           plo     rd
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

; ******************************
; *** Get next lump in chain ***
; *** RA - lump              ***
; *** Returns: RA - lump     ***
; ******************************
readlump:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs
           ldi     high sysfildes      ; get system dta
           phi     rd
           ldi     low sysfildes
           plo     rd
           sep     scall               ; read the sector
           dw      rawread
           ldi     low dta             ; get dta
           str     r2                  ; add in offset
           glo     r9
           add
           plo     rf                  ; place into pointer
           ldi     high dta
           str     r2
           ghi     r9
           adc
           phi     rf
           lda     rf                  ; get value
           phi     ra
           ldn     rf
           plo     ra
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
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

; ***************************
; *** Delete a lump chain ***
; *** RA - starting lump  ***
; ***************************
delchain:  glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
delchlp:   ghi     ra                  ; make copy of lump
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; read lump value
           dw      readlump
           ghi     ra                  ; move to rb
           phi     rb
           glo     ra
           plo     rb
           ghi     rc                  ; transfer original copy back to ra
           phi     ra
           glo     rc
           plo     ra
           ldi     0                   ; need to zero it
           phi     rf
           plo     rf
           sep     scall               ; write the lump
           dw      writelump
           ghi     rb                  ; move next lump value to ra
           phi     ra
           glo     rb
           plo     ra
           smi     0feh                ; check for end of chain
           lbnz    delchlp             ; loop back if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    delchlp
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller

; ***********************************
; *** Check for last lump and eof ***
; *** sets flags and/or eof value ***
; *** RD - file descriptor        ***
; *** RA - lump                   ***
; ***********************************
cklstlmp:  glo     r7                  ; save lump value
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save lump value
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save lump value
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save lump value
           stxd
           ghi     rf
           stxd
           sep     scall               ; read value of lump
           dw      readlump
           glo     ra                  ; see if on last lump
           smi     0feh
           lbnz    cklstno             ; jump if not last
           ghi     ra                  ; check high value as well
           smi     0feh
           lbnz    cklstno
           sep     scall               ; get descriptor flags
           dw      getfdflgs
           ori     4                   ; set last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs

           ldi     high lmpmask        ; need to get the lump mask
           phi     r8
           ldi     low lmpmask
           plo     r8
           sep     scall               ; get file offset
           dw      getfdeof
           ghi     rf                  ; store for subtraction
           str     r2                  ; store for mask operation
           ldn     r8                  ; retrieve mask
           and                         ; and mask the high byte
           stxd                        ; then store for later
           glo     rf
           stxd
           sep     scall               ; get file offset
           dw      getfdofs
           glo     r7                  ; subtract eof from offset
           irx                         ; move to eof on stack
           sm                          ; perform subtract
           irx                         ; point to high byte
           ghi     r7
           sex     r8                  ; need to mask high byte
           and                         ; keep only offset portion
           sex     r2                  ; point x back to stack
           smb                         ; perform subtract of high byte
           lbnf    cklstdone           ; jump if not beyond eof
           glo     r7                  ; get offset
           plo     rf                  ; and move for eof
           ghi     r7
           sex     r8                  ; need to mask high byte
           and
           sex     r2                  ; point x back to stack
           phi     rf
           sep     scall               ; write eof back
           dw      setfdeof
           lbr     cklstdone           ; recover registers and return
cklstno:   sep     scall               ; get flags
           dw      getfdflgs
           ani     0fbh                ; clear last lump flag
           sep     scall               ; and write it back
           dw      setfdflgs
cklstdone: irx                         ; recover registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; and return to caller


; *********************************
; *** Load corresponding sector ***
; *** RD - file descriptor      ***
; *********************************
loadsec:   glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           lda     rd                  ; get current offset
           shr                         ; need to shift by 9
           plo     r8                  ; perform shift by 8
           lda     rd
           shrc
           phi     r7
           ldn     rd
           shrc
           plo     r7
           dec     rd                  ; move descriptor back to beginning
           dec     rd
           ldi     0                   ; clear high of sector address
           phi     r8
           sep     scall               ; get lump count
           dw      sectolump
           ghi     ra                  ; transfer to count
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; get starting lump for file
           dw      startlump
ldseclp:   ghi     rc                  ; see if done
           lbnz    ldsecgo             ; more to do
           glo     rc
           lbnz    ldsecgo
ldsecct:   ldi     high lmpshift       ; need to build mask
           phi     r8                  ; to figure relative sector in lump
           ldi     low lmpshift
           plo     r8
           ldn     r8                  ; get the shift count
           plo     r8                  ; R8.0 will be the count
           ldi     0                   ; will user R8.1 to build mask
           phi     r8
ldsctlp1:  glo     r8                  ; see if more shifts are needed
           lbz     ldsectg1            ; jump if not
           ghi     r8                  ; otherwise perform a shift
           shl
           ori     1                   ; set low bit
           phi     r8                  ; put it back
           dec     r8                  ; decrement the shift count
           lbr     ldsctlp1            ; loop back until shifts are done
ldsectg1:  ghi     r8                  ; get mask
           str     r2                  ; and put in memory for use
           glo     r7                  ; get sector offset
           and                         ; mask out lump portion
           plo     rc                  ; save it
           sep     scall               ; convert lump to sector
           dw      lumptosec
           glo     rc                  ; get offset
           str     r2                  ; and add to sector
           glo     r7
           add
           plo     r7
           ghi     r7
           adci    0
           phi     r7
           glo     r8
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; now read the sector
           dw      rawread
           sep     scall               ; check for final lump/eof
           dw      cklstlmp
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; and return to caller
ldsecgo2:  dec     rc                  ; decrement lump count
           irx                         ; remove saved lump from stack
           irx
           lbr     ldseclp             ; and keep looking
ldsecgo:   glo     ra                  ; save lump number
           stxd
           ghi     ra
           stxd
           sep     scall               ; get next lump in chain
           dw      readlump
           glo     ra                  ; see if have last lump of file
           smi     0feh
           lbnz    ldsecgo2            ; jump if not
           ghi     ra                  ; check high byte
           smi     0feh
           lbnz    ldsecgo2
           irx                         ; recover last lump number
           ldxa
           phi     ra
           ldx
           plo     ra
ldsecadlp: sep     scall               ; append a lump to the file
           dw      append
           sep     scall               ; read new lump value
           dw      readlump
           dec     rc                  ; decrement the count
           glo     rc                  ; get count
           lbnz    ldsecadlp           ; jump if need to add more
           ghi     rc                  ; check high byte as well
           lbnz    ldsecadlp
           glo     rf                  ; save RF
           stxd
           ghi     rf
           stxd
           ldi     0                   ; set eof for new lump
           phi     rf
           plo     rf
           sep     scall               ; write to descriptor
           dw      setfdeof
           irx                         ; recover RF
           ldxa
           phi     rf
           ldx
           plo     rf
           lbr     ldsecct             ; then continue

; ***********************************
; *** Seek file descriptor to end ***
; *** RD - file descriptor        ***
; ***********************************
seekend:   glo     r7                  ; save registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save registers
           stxd
           ghi     r8
           stxd
           glo     ra                  ; save registers
           stxd
           ghi     ra
           stxd
           glo     rf                  ; save registers
           stxd
           ghi     rf
           stxd
           ldi     0                   ; set offset to zero
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; get starting lump for file
           dw      startlump
           sep     scall               ; read next lump
           dw      readlump
seekendlp: glo     ra                  ; see if have last lump
           smi     0feh
           lbnz    seekendgo           ; jump if not
           ghi     ra                  ; check high byte too
           smi     0feh
           lbnz    seekendgo
           sep     scall               ; get file offset
           dw      getfdeof
           glo     rf                  ; add into offset
           str     r2
           glo     r7
           add
           plo     r7
           ghi     rf
           str     r2
           ghi     r7
           adc
           phi     r7
           glo     r8
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; write offset to descriptor
           dw      setfdofs
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller
seekendgo: ldi     high lmpshift       ; need to get the lump shift value
           phi     rf                  ; in order to determine how much to
           ldi     low lmpshift        ; add to the current offset
           plo     rf
           ldn     rf                  ; get the shift count
           plo     re                  ; and place into the loop counter
           ldi     02h                 ; set intial value at 512 bytes
           phi     rf
           ldi     0
           plo     rf
seeklp1:   glo     re                  ; see if done with shifts
           lbz     seekendg1           ; jump if so
           dec     re                  ; otherwise decrement count
           ghi     rf                  ; and update bytes per lump
           shl
           phi     rf
           lbr     seeklp1             ; loop until correct number of shifts
seekendg1: ghi     r7                  ; add bytes per lump to offset
           str     r2             
           ghi     rf
           add
           phi     r7
           glo     r8                  ; propagate carry
           adci    0
           plo     r8
           ghi     r8
           adci    0
           phi     r8
           sep     scall               ; read value of next lump
           dw      readlump
           lbr     seekendlp           ; loop until end found

; ************************************************
; *** Perform file seek                        ***
; *** R8:R7 - offset                           ***
; ***    RD - file descriptor                  ***
; ***    RC - Whence 0-start, 1-current, 2-eof ***
; *** Returns: R8:R7 - original position       ***
; ************************************************
seek:      inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           glo     rc                  ; get whence
           lbnz    seeknot0            ; jump if not 0
           glo     r7                  ; transfer new offset
           plo     re
           ldn     rd
           plo     r7
           glo     re
           str     rd
           dec     rd
           ghi     r7                  ; transfer new offset
           plo     re
           ldn     rd
           phi     r7
           glo     re
           str     rd
           dec     rd
           glo     r8                  ; transfer new offset
           plo     re
           ldn     rd
           plo     r8
           glo     re
           str     rd
           dec     rd
           ghi     r8                  ; transfer new offset
           plo     re
           ldn     rd
           phi     r8
           glo     re
           str     rd
seekcont:  sep     scall               ; read the corresponding sector
           dw      loadsec
; *****************************************************
; *** Code added to check for seek past end of file ***
; *****************************************************
           sep     scall               ; check if pointer is at or past eof
           dw      checkeof
           lbnf    seekret             ; return to caller if not
           glo     rd                  ; save rd
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd
           ldi     high lmpmask        ; need to get lmpmask
           phi     rf
           ldi     low lmpmask 
           plo     rf
           ldn     rf                  ; retrieve it
           str     r2                  ; save it
           inc     rd                  ; point 2nd lsb of ofs
           inc     rd
           lda     rd                  ; get msb of lump offset
           and                         ; and mask it
           phi     rf                  ; save into rf
           lda     rd                  ; get low byte of lump offset
           plo     rf                  ; rf now holds new eof
           inc     rd                  ; move past dta field
           inc     rd
           ghi     rf                  ; write new eof
           str     rd
           inc     rd                  ; point to lsb of eof
           glo     rf                  ; and write rest of eof
           str     rd
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldx
           plo     rd
; *****************************************************
seekret:   sep     sret                ; and return to caller
seeknot0:  smi     1                   ; check for seek from current
           lbnz    seeknot1            ; jump if not
seekct2:   glo     r7                  ; add offset to current offset
           str     r2                  ; place into memory for add
           ldn     rd                  ; get value from descriptor
           plo     r7                  ; keep copy
           add                         ; add new offset
           str     rd                  ; store new offset
           dec     rd                  ; point to previous byte
           ghi     r7                  ; add offset to current offset
           str     r2                  ; place into memory for add
           ldn     rd                  ; get value from descriptor
           phi     r7                  ; keep copy
           adc                         ; add new offset
           str     rd                  ; store new offset
           dec     rd                  ; point to previous byte
           glo     r8                  ; add offset to current offset
           str     r2                  ; place into memory for add
           ldn     rd                  ; get value from descriptor
           plo     r8                  ; keep copy
           adc                         ; add new offset
           str     rd                  ; store new offset
           dec     rd                  ; point to previous byte
           ghi     r8                  ; add offset to current offset
           str     r2                  ; place into memory for add
           ldn     rd                  ; get value from descriptor
           phi     r8                  ; keep copy
           adc                         ; add new offset
           str     rd                  ; store new offset
           lbr     seekcont            ; load new sector
seeknot1:  smi     1                   ; check for seek from end
           lbnz    seeknot2
           dec     rd                  ; move to beginning of descriptor
           dec     rd
           dec     rd
           sep     scall               ; move pointer to end of file
           dw      seekend
           inc     rd                  ; point to low byte
           inc     rd
           inc     rd
           lbr     seekct2
seeknot2:  dec     rd                  ; restore descriptor
           dec     rd
           dec     rd
           sep     sret

; *************************************
; *** Open master directory         ***
; *** Returns: RD - file descriptor ***
; *************************************
openmd:
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; read sector 0
           dw      sector0
           ldi     high mdfildes       ; point to mdfildes
           phi     rd
           ldi     low mdfildes
           plo     rd
           ldi     low dta             ; point to eof of master dir
           adi     48                  ; add 304, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           ldi     0                   ; set current offset to zero
           str     rd
           inc     rd
           str     rd
           inc     rd
           str     rd
           inc     rd
           str     rd
           inc     rd
           ldi     high mddta          ; next dta
           str     rd
           inc     rd
           ldi     low mddta
           str     rd
           inc     rd
           lda     rf                  ; next eof
           str     rd
           inc     rd
           lda     rf
           str     rd
           inc     rd
           ldi     0ch                 ; next flags
           str     rd
           inc     rd
           ldi     4                   ; 6 bytes to copy
           plo     re
openmdlp1: ldi     0                   ; need to set 0
           str     rd
           inc     rd
           dec     re                  ; decrement count
           glo     re
           lbnz    openmdlp1           ; loop until done
           ldi     1                   ; dir offset is 300
           str     rd
           inc     rd
           ldi     44
           str     rd
           inc     rd
           ldi     4                   ; 4 bytes to copy
           plo     re
openmdlp2: ldi     0ffh                ; need to set -1
           str     rd
           inc     rd
           dec     re                  ; decrement count
           glo     re
           lbnz    openmdlp2           ; loop until done
           glo     rd                  ; move desriptor back to beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           ldi     0
           phi     r8
           plo     r8
           ldi     low mdfildes
           plo     rd
           ldi     low dta             ; point to sector
           adi     5                   ; add 261, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           lda     rf                  ; get starting sector
           phi     r7
           lda     rf
           plo     r7
           sep     scall               ; read first sector
           dw      rawread
           irx                         ; recover used registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           sep     sret                ; return to caller

; **************************************
; *** Get a free lump                ***
; *** Returns: RA - lump             ***
; ***          DF=0 - lump found     ***
; ***          DF=1 - lump not found *** 
; **************************************
freelump:  glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     rc
           stxd
           ghi     rc
           stxd
           glo     rd
           stxd
           ghi     rd
           stxd
           glo     rf
           stxd
           ghi     rf
           stxd
           sep     scall               ; read sector 0
           dw      sector0
           ldi     low dta             ; point to sector
           adi     5                   ; add 261, address of md sector
           plo     rf
           ldi     high dta
           adci    1
           phi     rf
           lda     rf                  ; get sector value
           phi     rb
           lda     rf
           plo     rb
           ldi     0                   ; zero high word
           phi     ra
           plo     ra
           phi     r8                  ; set search sector
           plo     r8
           phi     r7
           ldi     17
           plo     r7
           ldi     high sysfildes      ; get system file descriptor
           phi     rd
           ldi     low sysfildes
           plo     rd
freelump1: glo     rb                  ; check if end of lat table
           str     r2
           glo     r7
           sm
           lbnz    freelump2           ; jump if not
           ghi     rb                  ; check if end of lat table
           str     r2
           ghi     r7
           sm
           lbnz    freelump2           ; jump if not
           glo     ra                  ; check if end of lat table
           str     r2
           glo     r8
           sm
           lbnz    freelump2           ; jump if not
           ghi     ra                  ; check if end of lat table
           str     r2
           ghi     r8
           sm
           lbnz    freelump2           ; jump if not
           ldi     1                   ; signal no lump was found
freelumpe: shr                         ; shift result
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldxa
           plo     rb
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
freelump2: sep     scall               ; read next allocation sector
           dw      rawread
           ldi     high dta            ; point to dta
           phi     r9
           ldi     low dta
           plo     r9
           ldi     1                   ; 256 entries per sector
           phi     rc
           ldi     0
           plo     rc
freelump3: lda     r9                  ; get value from table
           lbnz    freelump4           ; jump if nonzero
           ldn     r9                  ; check low value
           lbnz    freelump4           ; jump if nonzero
           dec     r9                  ; reset offset
           ghi     r9                  ; subtract out buffer address
           smi     1
           phi     r9
           sep     scall               ; convert sector,offset to lump
           dw      secofslmp
           ldi     0                   ; signal a lump was found
           lbr     freelumpe           ; and return
freelump4:
           inc     r9                  ; point to next entry
           dec     rc                  ; decrement count
           glo     rc                  ; check if end
           lbnz    freelump3           ; loop back if more to check
           inc     r7                  ; increment sector number
           glo     r7                  ; see if rollover happened
           lbnz    freelump1           ; loop to sector if not
           ghi     r7                  ; see if rollover happened
           lbnz    freelump1           ; loop to sector if not
           inc     r8                  ; carry over increment
           lbr     freelump1

; *************************************
; *** Append a lump to current file ***
; *** RD - file descriptor          ***
; *** Returns DF=0 - success        ***
; ***         DF=1 - failed         ***
; *************************************
append:
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           sep     scall               ; find a free lump
           dw      freelump
           lbnf    append1             ; jump if one was found
           ldi     1                   ; signal an error
appende:   shr                         ; shift into df
           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldx
           plo     ra
           sep     sret                ; and return to caller
append1:   glo     rb                  ; save additional registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save additional registers
           stxd
           ghi     rc
           stxd
           glo     rf                  ; save additional registers
           stxd
           ghi     rf
           stxd
           ghi     ra                  ; move new lump
           phi     rc
           glo     ra
           plo     rc
           sep     scall               ; get first lump of file
           dw      startlump
           ghi     ra                  ; copy start lump to temp
           phi     rb
           glo     ra
           plo     rb
append2:   glo     ra                  ; get for end of chain code
           smi     0feh
           lbnz    append3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    append3
           lbr     append4             ; end found
append3:   ghi     ra                  ; copy lump to temp
           phi     rb
           glo     ra
           plo     rb
           sep     scall               ; get next lump
           dw      readlump
           lbr     append2             ; loop until last lump is found
append4:   ghi     rb                  ; transfer lump
           phi     ra
           glo     rb
           plo     ra
           ghi     rc                  ; transfer new lump
           phi     rf
           glo     rc
           plo     rf
           sep     scall               ; write new lump value
           dw      writelump
           ghi     rc                  ; get new lump
           phi     ra
           glo     rc
           plo     ra
           ldi     0feh                ; end of chain code
           phi     rf
           plo     rf
           sep     scall               ; write new lump value
           dw      writelump
           sep     scall               ; get file descriptor flags
           dw      getfdflgs
           ani     0fbh                ; indicat current sector is not last
           sep     scall               ; and write back
           dw      setfdflgs
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rb
           ldx
           plo     rb
           ldi     0                   ; indicate success
           lbr     appende             ; and return

; **********************************
; *** Check if at end of file    ***
; *** RD - file descriptor       ***
; *** Returns: DF=0 - not at end ***
; ***          DF=1 - At end     ***
; **********************************
checkeof:  glo     rf                  ; save rf
           stxd
           ghi     rf
           stxd
           ldi     high lmpmask        ; need to get lmpmask
           phi     rf
           ldi     low lmpmask 
           plo     rf
           ldn     rf                  ; retrieve it
           plo     re                  ; and save it here
           glo     rd                  ; save rd
           stxd
           adi     8                   ; and move to flags
           plo     rd
           plo     rf
           ghi     rd
           stxd
           adci    0
           phi     rd
           phi     rf
           ldn     rd                  ; get flags
           ani     4                   ; see if in final lump
           lbz     noeof               ; jump if not
           dec     rf                  ; move rf to eof low byte
           dec     rd                  ; move rd to current offset
           dec     rd
           dec     rd
           dec     rd
           dec     rd
; ******************************************************************
; *** This was original code which compared for the offset being ***
; *** equal to the eof field.                                    ***
; ******************************************************************
;           ldn     rd                  ; get byte from offset
;           str     r2
;           ldn     rf                  ; get eof byte
;           sm                          ; compare them
;           lbnz    noeof               ; jump if no match
;           dec     rf                  ; move to previous byte
;           dec     rd
;           ldn     rf                  ; get byte from eof
;           str     r2                  ; this byte needs to be masked
;           glo     re                  ; get mask
;           and                         ; and apply to the value
;           stxd                        ; keep value on the stack
;           ldn     rd                  ; get byte from offset
;           str     r2                  ; this value must also be masked
;           glo     re                  ; obtain mask
;           and                         ; and perform the masking
;           irx                         ; move back to the last byte
;           sm                          ; compare values
;           lbnz    noeof               ; jump if not at eof
; ******************************************************************
; *** Replaced with the following code which sees if the current ***
; *** offset is equal OR greater than the eof byte               ***
; ******************************************************************
           ldn     rf                  ; get byte from eof
           str     r2                  ; store for comparison
           ldn     rd                  ; get byte from offset
           sm                          ; and subtract
           dec     rf                  ; move to msb of eof
           dec     rd                  ; move to next most byte of offset
           ldn     rf                  ; get byte from eof
           str     r2                  ; this byte needs to be masked
           glo     re                  ; get lump mask
           and                         ; and mask eof byte
           stxd                        ; save it for now
           ldn     rd                  ; get offset byte
           str     r2                  ; this must also be masked
           glo     re                  ; get the mask
           and                         ; and mask offset byte
           irx                         ; point x back to masked eof byte
           smb                         ; and continue subtraction
           lbnf    noeof               ; jump if not at or past eof
; ***********************
; *** End of new code ***
; ***********************
ateof:     ldi     1                   ; signal at end
checkeofe: shr                         ; shift result into df
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return to caller
noeof:     ldi     0                   ; signal not at eof
           lbr     checkeofe

; *****************************************
; *** Increment current offset          ***
; *** RD - file descriptor              ***
; *** Returns: DF=1 - new sector loaded ***
; *****************************************
incofs:    inc     rd                  ; move to last byte of offset
           inc     rd
           inc     rd
           ldn     rd                  ; get offset
           adi     1                   ; increment it
           str     rd                  ; and put back
           plo     re                  ; keep copy of this byte
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           dec     rd                  ; point to previous byte
           ldn     rd                  ; get offset
           adci    0                   ; increment it
           str     rd                  ; and put back
           glo     re                  ; get first byte
           lbz     incofs1             ; jump if it is zero
incofse1:  ldi     0
           shr
           sep     sret                ; return to caller
incofs1:   inc     rd                  ; move to 3rd byte
           inc     rd
           ldn     rd                  ; retrieve it
           dec     rd                  ; move back to beginning
           dec     rd
           plo     re                  ; keep a copy
           ani     1
           lbnz    incofse1            ; jump if not zero
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           ldi     high lmpmask        ; need to get lump mask
           phi     r8
           ldi     low lmpmask
           plo     r8
           ldn     r8                  ; retrieve lump mask
           str     r2                  ; need to mask with byte 2 
           glo     re                  ; of the current file pointer
           and                         ; combine with mask
           plo     re                  ; and keep in re
           glo     rd                  ; move descriptor to current sector
           adi     15
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; get current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; move descriptor back to beginning
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           glo     re                  ; recover byte 3rd byte of file pointer
           lbz     incofslmp           ; need a new lump
           inc     r7                  ; increment count
           glo     r7                  ; see if rollover happened
           lbnz    incofs2             ; jump if not
           ghi     r7
           lbnz    incofs2
           inc     r8                  ; propagate the incrment
incofs2:   sep     scall               ; read the new sector
           dw      rawread
incofse2:  irx                         ; recover consumed registers
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r7
           ldx
           plo     r7
           ldi     1
           shr
           sep     sret                ; return to caller
incofslmp:
           glo     ra                  ; save additional consumed registers
           stxd
           ghi     ra
           stxd
           sep     scall               ; convert sector to lump
           dw      sectolump
           sep     scall               ; get next lump
           dw      readlump
           sep     scall               ; get first sector of next lump
           dw      lumptosec
           sep     scall               ; read the next sector in
           dw      rawread
           sep     scall               ; get next lump
           dw      readlump
           glo     rd                  ; move descriptor to flags
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           glo     ra                  ; check for ending lump
           smi     0feh                ; check for end of chain code
           lbnz    incofs3             ; jump if not
           ghi     ra
           smi     0feh
           lbnz    incofs3
           ldn     rd                  ; get flags
           ori     4                   ; indicate last lump loaded
incofs4:   str     rd                  ; put it back
           glo     rd                  ; move descriptor back
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldx
           plo     ra
           lbr     incofse2
incofs3:   ldn     rd                  ; get flags
           ani     0fbh                ; indicate not last lump
           lbr     incofs4             ; and continue

; **********************************************
; *** Set R9 to current offset + DTA address ***
; *** RD - file descripter                   ***
; *** Returns: R9 - address in DTA           ***
; **********************************************
settrx:    inc     rd                  ; point to low bytes of offset
           inc     rd
           lda     rd                  ; get high byte
           ani     1                   ; strip high info
           phi     r9
           lda     rd                  ; get low byte
           plo     r9
           inc     rd                  ; point to low byte of dta
           ldn     rd                  ; get low of dta
           str     r2                  ; store for add
           glo     r9
           add
           plo     r9
           dec     rd                  ; point to high byte of dta
           ldn     rd
           str     r2
           ghi     r9
           adc
           phi     r9                  ; r9 now has transfer address
           dec     rd                  ; move descriptor back to beginningglo     re                  ; recover flags
           
           dec     rd
           dec     rd
           dec     rd
           sep     sret                ; return to caller

; ***************************************
; *** Check for valid file descriptor ***
; *** RD - file descriptor            ***
; *** Returns: DF=0 - valid FILDES    ***
; ***          DF=1 - Invalid FILDES  ***
; ***************************************
chkvld:    push    rd                  ; save file descriptor position
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           plo     re                  ; save it for a moment
           pop     rd                  ; recover file descriptor
           glo     re                  ; recover flags
           ani     08h                 ; if FILDES marked valid
           lbz     chkvldno            ; jump if not
           ldi     0                   ; mark good
           shr
           sep     sret                ; and return
chkvldno:  ldi     1                   ; mark invalid
           shr
           sep     sret                ; and return

; ***************************************
; *** Read bytes from file            ***
; *** RD - file descriptor            ***
; *** RC - Number of bytes to read    ***
; *** RF - Buffer to store bytes in   ***
; *** Returns: RC - actual bytes read ***
; ***          DF=0 - no errors       ***
; ***          DF=1 - error           ***
; ***                 D - Error code  ***
; ***************************************
read:      sep     scall               ; check for valid FILDES
           dw      chkvld
           lbnf    readgo              ; jump if good
           ldi     2                   ; Signal invalid FILDES
           sep     sret                ; and return
readgo:    glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           sep     scall               ; setup transfer address
           dw      settrx
           ldi     0                   ; clear bytes read counter
           phi     rb
           plo     rb
readlp:    glo     rc                  ; see if more bytes to read
           lbnz    read1               ; jump if so
           ghi     rc
           lbnz    read1
           ghi     rb                  ; move bytes read
           phi     rc
           glo     rb
           plo     rc
           irx                         ; recover consumed registers
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     rb
           ldx
           plo     rb
           ldi     0                   ; signal no error
           shr
           sep     sret                ; and return to caller
read1:     sep     scall               ; check for eof
           dw      checkeof
           lbnf    read2               ; jump if not at end
           ldi     0                   ; clear the bytes left
           phi     rc
           plo     rc
           lbr     readlp              ; and loop back
read2:     lda     r9                  ; get byte from dta
           str     rf                  ; store into buffer
           inc     rf
           inc     rb                  ; increment byte count
           dec     rc                  ; decrement count
           sep     scall               ; increment offset
           dw      incofs
           lbnf    readlp              ; and loop back if not a new sector
           sep     scall               ; setup transfer address
           dw      settrx
           lbr     readlp              ; then continue

; ******************************************
; *** Write bytes to file                ***
; *** RD - file descriptor               ***
; *** RC - Number of bytes to write      ***
; *** RF - Buffer of bytes to write      ***
; *** Returns: RC - actual bytes written ***
; ***          DF=0 - no errors          ***
; ***          DF=1 - error              ***
; ***                 D - Error code     ***
; ******************************************
write:     glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     rd                  ; get copy of descriptor
           adi     8                   ; pointing at flags
           plo     ra
           ghi     rd
           adci    0
           phi     ra
           ldn     ra                  ; get flags
           ani     2                   ; see if file is read only
           lbnz    writeer             ; exit if so
           ldn     ra                  ; get flags
           ani     8                   ; check for valid FILDES
           lbz     writeer2            ; jump if not
           sep     scall               ; setup transfer address
           dw      settrx
           ldi     0                   ; clear bytes read counter
           phi     rb
           plo     rb
writelp:   glo     rc                  ; see if more bytes to read
           lbnz    write1              ; jump if so
           ghi     rc
           lbnz    write1
           ghi     rb                  ; move bytes read
           phi     rc
           glo     rb
           plo     rc
           ldi     0
           shr                         ; clear DF
writeex:   plo     re                  ; save result code
           irx                         ; recover consumed registers
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldx
           plo     rb
           glo     re                  ; recover error result
           sep     sret                ; and return to caller
writeer:   ldi     1                   ; signal error
           shr                         ; shift into DF
           ldi     1                   ; signal read-only error
           lbr     writeex             ; then exit
writeer2:  ldi     1                   ; signal error
           shr                         ; shift into DF
           ldi     2                   ; signal invalid FILDES
           lbr     writeex             ; then exit
write1:    ldn     ra                  ; get flags byte
           ori     011h                ; set written flags
           str     ra                  ; and put back
           lda     rf                  ; get byte from buffer
           str     r9                  ; write into dta
           inc     r9
           inc     rb                  ; increment byte count
           dec     rc                  ; decrement to write count
           sep     scall               ; check for eof
           dw      checkeof
           lbnf    write2              ; jump if not at end
           dec     ra                  ; point to low byte of eof
           ldn     ra                  ; retrieve it
           adi     1                   ; add 1 to it
           str     ra                  ; and put it back
           dec     ra                  ; point to high byte
           ldn     ra                  ; retrieve it
           adci    0                   ; propagate the carry
           ani     0fh                 ; clear high nybble
           str     ra                  ; and put back
           inc     ra                  ; move back to flags
           inc     ra
           lbnz    write2              ; loop back if high byte is nonzero
           dec     ra                  ; retrieve low byte of eof
           lda     ra
           lbnz    write2              ; loop back if nonzero
           sep     scall               ; append a new lump
           dw      append
write2:    sep     scall               ; increment offset
           dw      incofs
           lbnf    writelp             ; and loop back if not a new sector
           sep     scall               ; setup transfer address
           dw      settrx
           lbr     writelp             ; then continue
       
; **************************************
; *** Close a file                   ***
; *** RD - file descriptor           ***
; *** Returns: DF=0 - success        ***
; ***          DF=1 - error          ***
; ***                 D - Error code ***
; **************************************
close:     sep     scall               ; make sure FILDES is valid
           dw      chkvld
           lbnf    closego             ; jump if good
           ldi     1                   ; otherwise signal error
           shr
           ldi     2                   ; invalid FILDES error
           sep     sret                ; return to caller
closego:   sep     scall               ; see if sector needs to be written
           dw      checkwrt
           glo     rd                  ; point to flags byte
           adi     8
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           ldn     rd                  ; get flags byte
           ani     16                  ; see if file was written to
           lbnz    close1              ; jump if so
closeex:   glo     rd                  ; restore descriptor
           smi     8
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           ldi     0                   ; signal no error
           shr
           sep     sret                ; return to caller
close1:    inc     rd                  ; point to dir sector
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           lda     rd                  ; retrieve dir sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           sep     scall               ; read the sector
           dw      readsys
           lda     rd                  ; get dir offset high byte
           stxd                        ; place into memory
           lda     rd                  ; get low byte
           str     r2                  ; and keep for add
           ldi     low dta             ; get system dta
           add                         ; add in diroffset
           plo     r9
           irx                         ; point to high byte of offset
           ldi     high dta
           adc
           phi     r9                  ; r9 now has dir offset
           inc     r9                  ; point to eof field
           inc     r9
           inc     r9
           inc     r9
           glo     rd                  ; move descriptor to eof field
           smi     9 
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           lda     rd                  ; get high byte of eof
           str     r9                  ; store into dir entry
           inc     r9
           lda     rd 
           str     r9
           inc     r9
           inc     r9                  ; move past flags
           sep     scall               ; get current date/time
           dw      gettmdt
           ghi     ra                  ; write date/time to dir entry
           str     r9
           inc     r9
           glo     ra
           str     r9
           inc     r9
           ghi     rb                  ; write date/time to dir entry
           str     r9
           inc     r9
           glo     rb
           str     r9
           sep     scall               ; write the sector back
           dw      writesys
           irx                         ; recover consumed registers
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
           lbr     closeex             ; and exit

; **********************************
; *** Get current sector, offset ***
; *** RD - file descriptor       ***
; *** Returns R8:R7 - sector     ***
; ***            R9 - offset     ***
; **********************************
getsecofs: inc     rd                  ; move to low word of offset
           inc     rd
           lda     rd                  ; get high byte
           ani     1                   ; strip upper bits
           phi     r9                  ; place into offset
           lda     rd                  ; get low byte
           plo     r9                  ; r9 now has offset
           glo     rd                  ; move pointer to current sector
           adi     11
           plo     rd
           ghi     rd
           adci    0
           phi     rd
           lda     rd                  ; retrieve current sector
           phi     r8
           lda     rd
           plo     r8
           lda     rd
           phi     r7
           lda     rd
           plo     r7
           glo     rd                  ; restore descriptor pointer
           smi     19
           plo     rd
           ghi     rd
           smbi    0
           phi     rd
           sep     sret                ; return to caller

; *****************************************
; *** search directory for an entry     ***
; *** RD - file descriptor (dir)        ***
; *** RF - Where to put directory entry ***
; *** RC - filename (asciiz)            ***
; *** Returns: R8:R7 - Dir Sector       ***
; ***             R9 - Dir Offset       ***
; ***          DF=0  - entry found      ***
; ***          DF=1  - entry not found  ***
; *****************************************
searchdir: glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           ghi     rf                  ; save buffer position
           phi     ra
           glo     rf
           plo     ra
           ghi     rc                  ; save filename
           phi     rb
           glo     rc
           plo     rb
searchlp:  sep     scall               ; get current sector, offset
           dw      getsecofs
           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf
           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; perform read
           dw      read
           glo     rc                  ; see if enough bytes were read
           smi     32
           lbnz    searchno            ; jump if end of dir was hit
           ghi     ra                  ; get buffer
           phi     rf
           glo     ra
           plo     rf
           lda     rf                  ; see if entry is valid
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lda     rf
           lbnz    entrygood
           lbr     searchlp            ; entry was no good, try again
entrygood: glo     rd                  ; save descriptor
           stxd
           ghi     rd
           stxd
           ghi     rb                  ; get filename
           phi     rd
           glo     rb
           plo     rd
           glo     ra                  ; recover buffer
           adi     12                  ; pointing at filename
           plo     rf
           ghi     ra                  ; recover buffer
           adci    0
           phi     rf
           sep     scall               ; compare the strings
           dw      f_strcmp
           plo     re                  ; save result
           irx                         ; recover descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           glo     re                  ; get result
           lbz     searchyes           ; entry was found
           lbr     searchlp            ; and keep looking
searchyes:
           ldi     0                   ; indicate entry was found
           lbr     searchex            ; and return
searchno:  ldi     1                   ; indicate not found
searchex:  shr
           ghi     rb                  ; recover filename
           phi     rc
           glo     rb
           plo     rc
           ghi     ra                  ; recover buffer
           phi     rf
           glo     ra
           plo     rf
           irx                         ; recover used registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rb
           ldx
           plo     rb
           sep     sret                ; return to caller

; ****************************************
; *** Split pathname at separator      ***
; *** RF - pathname                    ***
; *** returns: RF - orignal path       ***
; ***          RC - path following sep ***
; ***          DF=0 - separator found  ***
; ***          DF=1 - ne separator     ***
; ****************************************
findsep:   ghi     rf                  ; copy path to rc
           phi     rc
           glo     rf
           plo     rc
findseplp: lda     rc                  ; get byte from pathname
           plo     re                  ; keep a copy
           smi     33                  ; check for space or less
           lbnf    findsepno           ; no separator
           glo     re                  ; recover value
           smi     '/'                 ; check for separator
           lbnz    findseplp           ; keep looping if not found
           dec     rc                  ; need to write a terminator
           ldi     0
           str     rc
           inc     rc                  ; point rc back to following name
           ldi     0                   ; signal separator found
           shr
           sep     sret                ; and return to caller
findsepno: ldi     1                   ; signal no separator
           shr
           sep     sret                ; return to caller

; ************************************
; *** Setup new file descriptor    ***
; ***    RD - descriptor to setup  ***
; *** R8:R7 - dir sector           ***
; ***    R9 - dir offset           ***
; ***    RF - pointer to dir entry ***
; ************************************
setupfd:   sep     scall               ; set dir sector
           dw      setfddrsc
           sep     scall               ; set dir offset
           dw      setfddrof
           ldi     0                   ; zero current offset
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall
           dw      setfdofs            ; set offset
           ldi     0ffh                ; need -1
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; set current sector
           dw      setfdsec
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           inc     rf                  ; point to starting lump
           inc     rf
           lda     rf                  ; get starting lump
           phi     ra
           lda     rf
           plo     ra
           sep     scall               ; convert to sector
           dw      lumptosec
           sep     scall               ; read the first sector of the file
           dw      rawread
           ldi     08h                 ; set initial flags
           sep     scall
           dw      setfdflgs
           sep     scall               ; get lump value
           dw      readlump
           ghi     ra                  ; check end code
           smi     0feh
           lbnz    openeof
           glo     ra
           smi     0feh
           lbnz    openeof
           ldi     0ch                 ; signal final lump
           sep     scall
           dw      setfdflgs
openeof:   lda     rf                  ; get eof
           phi     ra
           lda     rf
           plo     rf
           ghi     ra
           phi     rf
           sep     scall               ; setup eof
           dw      setfdeof
           sep     sret                ; return to caller

; ***************************************
; *** Follow a directory tree         ***
; *** RD - Dir descriptor             ***
; *** RF - Pathname                   ***
; *** Returns: RD - final dir in path ***
; ***          DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************
follow:    sep     scall               ; check for dirname
           dw      findsep
           lbdf    founddir            ; jump if no more dirnames
           glo     rc                  ; save name after sep
           stxd
           ghi     rc
           stxd
           ghi     rf                  ; move pathname
           phi     rc
           glo     rf
           plo     rc
           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; search for name
           dw      searchdir
           irx                         ; recover pathname
           ldxa
           phi     rc
           ldx
           plo     rc
           dec     rc                  ; replace the /
           ldi     '/'
           str     rc
           inc     rc
           lbnf    finddir1            ; jump if entry was found
           ldi     errnoffnd           ; signal an error
           lbr     error
finddir1:  glo     rf                  ; point to flags
           adi     6
           plo     rf
           ghi     rf
           adci    0
           phi     rf
           ldn     rf                  ; get flags
           plo     re                  ; save it
           glo     rf                  ; put rf back
           smi     6
           plo     rf
           ghi     rf
           smbi    0
           phi     rf
           glo     re                  ; recover flags
           ani     1                   ; see if entry is a dir
           lbnz    finddir2            ; jump if so
           ldi     errinvdir           ; invalid directory error
           lbr     error
finddir2:  sep     scall               ; set fd to new directory
           dw      setupfd
           ghi     rc                  ; get next part of path
           phi     rf
           glo     rc
           plo     rf
           lbr     follow              ; and get next
founddir:  ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller

; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RC - first char following dirs ***
; ***          DF=0 - dir was found           ***
; ***          DF=1 - nonexistant dir         ***
; ***********************************************
finddir:   sep     scall               ; open the master dir
           dw      openmd
           ldn     rf                  ; get first byte of pathname
           smi     '/'                 ; check for absolute path
           lbz     findabs             ; jump if so
           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd
           ldi     high path           ; point to current dir
           phi     rf
           ldi     low path
           plo     rf
findcont:  ldn     rf                  ; get first byte
           smi     '/'                 ; check for slash
           lbnz    finddirg            ; jump if not
           inc     rf                  ; move past leading slash
finddirg:  sep     scall               ; follow path in current dir
           dw      follow
           plo     re                  ; save result code
           irx                         ; recover original path
           ldxa
           phi     rf
           ldx
           plo     rf
           glo     re                  ; get result code back
           lbdf    error               ; jump on error
           lbr     findrel
findabs:   inc     rf                  ; move past first slash
findrel:   sep     scall               ; follow dirs
           dw      follow
           lbdf    error               ; jump on error
           ghi     rf                  ; transfer name
           phi     rc
           glo     rf
           plo     rc
           ldi     0                   ; signal success
           shr
           sep     sret                ; return to caller

; *****************
; *** Open /BIN ***
; *****************
execdir:   sep     scall               ; open the master dir
           dw      openmd
           glo     rf                  ; save path
           stxd
           ghi     rf
           stxd
           ldi     high defdir         ; point to default dir
           phi     rf
           ldi     low defdir
           plo     rf
           lbr     findcont            ; continue with normal find


; ***********************************************
; *** Find directory                          ***
; *** RF - filename                           ***
; *** Returns: RD - Dir descriptor            ***
; ***          RF - first char following dirs ***
; ***********************************************
opendir:   glo     rc                  ; save consumed register
           stxd
           ghi     rc
           stxd
           sep     scall               ; call find dir routine
           dw      finddir
           ghi     rc                  ; put end if dir back into rf
           phi     rf
           glo     rc
           plo     rf
           irx                         ; recover consumed register
           ldxa
           phi     rc
           ldx
           plo     rc
           sep     sret                ; return to caller

; **********************************
; *** Create a new file          ***
; *** RD - dir descriptor        ***
; *** RC - descriptro to fill in ***
; *** RF - filename              ***
; *** R7 - Flags                 ***
; ***      1-subdir              ***
; *** Returns: RD - new file     ***
; **********************************
create:    glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb
           stxd
           ghi     rb
           stxd
           glo     r9
           stxd
           ghi     r9
           stxd
           glo     r8
           stxd
           ghi     r8
           stxd
           glo     r7
           stxd
           ghi     r7
           stxd
           glo     r7                  ; put copy of flags on stack
           stxd
           ldi     high scratch        ; get buffer address
           phi     rb
           ldi     low scratch
           plo     rb
           sep     scall               ; get a lump
           dw      freelump
           ldi     0                   ; setup starting lump
           str     rb
           inc     rb
           str     rb
           inc     rb
           ghi     ra
           str     rb
           inc     rb
           glo     ra
           str     rb
           inc     rb
           ldi     0                   ; set eof at zero
           str     rb
           inc     rb
           str     rb
           inc     rb
           irx                         ; recover create flags
           ldx
           str     rb                  ; and save
           inc     rb
           ldi     5                   ; need 5 zeroes
           plo     re
create1:   ldi     0
           str     rb
           inc     rb
           dec     re
           glo     re
           lbnz    create1
create2:   lda     rf                  ; get character from filename
           str     rb                  ; store into buffer
           inc     rb
           lbnz    create2             ; loop back until zero is found
           sep     scall               ; get dir sector and offset
           dw      getsecofs
           ldi     high scratch        ; get buffer address
           phi     rf
           ldi     low scratch
           plo     rf
           glo     rc                  ; save destination descriptor
           stxd
           ghi     rc
           stxd
           ldi     0                   ; 32 bytes to write
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; write the dir entry
           dw      write
           sep     scall               ; close the directory
           dw      close
           irx                         ; recover new descriptor
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     scall               ; write dir sector
           dw      setfddrsc
           sep     scall               ; write dir offset
           dw      setfddrof
           ldi     0                   ; need to set current offset to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; write current offset
           dw      setfdofs
           ldi     0ffh                ; need to set current sector to -1
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           sep     scall               ; write current offset
           dw      setfdsec
           ldi     0ch                 ; set flags
           sep     scall
           dw      setfdflgs
           ldi     0                   ; need to set eof to 0
           phi     rf
           plo     rf
           sep     scall
           dw      setfdeof
           ldi     0feh                ; need to set end of chain
           phi     rf
           plo     rf
           sep     scall
           dw      writelump
           sep     scall               ; convert lump to sector
           dw      lumptosec
           sep     scall               ; read the sector
           dw      rawread
           irx                         ; recover consumed registers
           ldxa
           phi     r7
           ldxa
           plo     r7
           ldxa
           phi     r8
           ldxa
           plo     r8
           ldxa
           phi     r9
           ldxa
           plo     r9
           ldxa
           phi     rb
           ldxa
           plo     rb
           ldxa
           phi     ra
           ldx
           plo     ra
           sep     sret                ; return to caller
           
; *******************************************
; *** Get a free directory entry          ***
; *** RD - directory descriptor           ***
; *** Returns: RD - positioned descriptor ***
; ***          DF=0 - success             ***
; ***          DF=1 - Error               ***
; *******************************************
freedir:   ldi     0                   ; need to seek to 0
           phi     r8
           plo     r8
           phi     r7
           plo     r7
           plo     rc                  ; seek from start
           sep     scall               ; perform file seek
           dw      seek
           ldi     0                   ; offset
           phi     ra
           plo     ra
           phi     rb
           plo     rb
newfilelp: ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           sep     scall               ; read next record
           dw      read
           glo     rc                  ; see if record was read
           smi     32
           lbnz    neweof              ; jump if eof hit
           ldi     high scratch        ; setup buffer
           phi     rf
           ldi     low scratch
           plo     rf
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lda     rf                  ; check for free entry
           lbnz    newnot              ; jump if not
           lbr     neweof              ; found an entry
newnot:    lda     rd                  ; get current offset
           phi     rb
           lda     rd
           plo     rb
           lda     rd
           phi     ra
           ldn     rd
           plo     ra
           dec     rd                  ; restore pointer
           dec     rd
           dec     rd
           lbr     newfilelp           ; keep looking
neweof:    ghi     rb                  ; transfer offset for seek
           phi     r8
           glo     rb
           plo     r8
           ghi     ra
           phi     r7
           glo     ra
           plo     r7
           ldi     0                   ; seek from beginning
           plo     rc
           sep     scall               ; perform seek
           dw      seek
           ldi     0                   ; indicate no error
           sep     sret                ; and return to caller


; *************************************
; *** exec a file from /bin         ***
; *** RF - filename                 ***
; *** RA - pointer to arguments     ***
; *** Returns: RD - file descriptor ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
execbin:   glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           sep     scall               ; find directory
           dw      execdir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbdf    execfail            ; jump if failed to get dir
           sep     scall               ; close the directory
           dw      close
           ldi     high intfildes       ; point to internal fildes
           phi     rd
           ldi     low intfildes
           plo     rd
           sep     scall               ; setup the descriptor
           dw      setupfd
           ldi     0                   ; signal success
           shr
           irx                         ; recover consumed registers
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
           lbr     opened
execfail:  ldi     1                   ; signal error
           shr
           ldi     errnoffnd
           lbr     openexit            ; then return

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
open:      sep     scall               ; validate filename
           dw      validate
           lbdf    noopen              ; failed
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rb                  ; save consumed registers
           stxd
           ghi     rb
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rd                  ; save descriptor
           stxd
           ghi     rd
           stxd
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
allow:     glo     rc                  ; save filename address
           stxd
           ghi     rc
           stxd
           sep     scall               ; find a free dir entry
           dw      freedir
           irx                         ; recover filename
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa                        ; recover new descriptor
           phi     rc
           ldx
           plo     rc
           ldi     0                   ; set no flags
           plo     r7
           sep     scall               ; create the file
           dw      create
           ldi     0                   ; signal success
           shr
           lbr     openexit            ; and return
noopen:    smi     0                   ; signal file not opened
           sep     sret                ; and return

           
; *************************************
; *** delete a file                 ***
; *** RF - filename                 ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
delete:
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           sep     scall               ; find directory
           dw      finddir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    delfile             ; jump if file exists
           sep     scall               ; close the directory
           dw      close
           ldi     1                   ; signal an error
delexit:   shr                         ; shift result into DF
           irx                         ; recover consumed registers
           ldxa
           phi     rc
           ldxa
           plo     rc
           ldxa
           phi     rd
           ldxa
           plo     rd
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
delfile:   sep     scall               ; close the directory
           dw      close
           sep     scall               ; read driectory sector for file
           dw      readsys
           ghi     r9                  ; get offset into sector
           adi     1 
           phi     r9 
           inc     r9                  ; point to flags
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           inc     r9
           ldn     r9                  ; get flags
           ani     1                   ; see if directory
           lbnz    delfildir           ; jump if so
           dec     r9                  ; point to starting lump
           dec     r9
           dec     r9
           dec     r9
delgo:     ldn     r9                  ; retrieve it
           phi     ra
           ldi     0                   ; and zero in dir entry
           str     r9
           inc     r9
           ldn     r9
           plo     ra
           ldi     0
           str     r9
           sep     scall               ; write dir sector back
           dw      writesys
           sep     scall               ; delete the chain
           dw      delchain
           ldi     0                   ; signal success
           lbr     delexit
delfildir: ldi     1                   ; setup error code
           shr
           ldi     errisdir
           shlc
           lbr     delexit             ; and return
           
; *************************************
; *** rename a file                 ***
; *** RF - filename                 ***
; *** RC - new filename             ***
; *** Returns:                      ***
; ***          DF=0 - success       ***
; ***          DF=1 - error         ***
; ***             D - Error code    ***
; *************************************
rename:    glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rc                  ; save copy of destination filename
           stxd
           ghi     rc
           stxd
           sep     scall               ; find directory
           dw      finddir
           ldi     high scratch        ; setup scrath area
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; perform directory search
           dw      searchdir
           lbnf    renfile             ; jump if file exists
           sep     scall               ; close the directory
           dw      close
           ldi     1                   ; signal an error
           irx                         ; drop filename from stack
           irx
           lbr     delexit             ; use exit from delete
renfile:   sep     scall               ; close the directory
           dw      close
           sep     scall               ; read driectory sector for file
           dw      readsys
           glo     r9                  ; point to filename
           adi     12
           plo     r9
           ghi     r9                  ; get offset into sector
           adci    1 
           phi     r9 
           irx                         ; recover new name
           ldxa
           phi     rf
           ldx
           plo     rf
renlp:     lda     rf                  ; get byte from name
           str     r9                  ; store into dir entry
           inc     r9                  ; point to next position
           bnz     renlp               ; loop if a zero was not written
           sep     scall               ; write dir sector back
           dw      writesys
           ldi     0                   ; signal success
           lbr     delexit
           
           
; *************************
; *** Execute a program ***
; *** RF - command line ***
; *************************
exec:      sep      scall                ; move past any leading spaces
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
err:       ldi      1                    ; signal an error
           shr
           sep      sret
opened:    ldi      high scratch         ; scratch space to read header
           phi      rf
           ldi      low scratch
           plo      rf
           ldi      0                    ; need to read 6 bytes
           phi      rc
           ldi      6
           plo      rc
           sep      scall                ; read header
           dw       read
           ldi      high scratch         ; point to load offset
           phi      r7
           ldi      low scratch
           plo      r7
           lda      r7                   ; get load address
           phi      rf
           phi      rb                   ; and make a copy
           lda      r7
           plo      rf
           plo      rb
           lda      r7                   ; get size
           phi      rc
           lda      r7
           plo      rc
           sep      scall                ; read program block
           dw       read
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
           ldi      0                    ; signal no error
           shr
           sep      sret                 ; return to caller

; *******************************
; *** Make directory          ***
; *** RF - pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************
mkdir:     glo     rf                  ; save pathname address
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

; ***************************************
; *** Set default execution directory ***
; *** RF - path                       ***
; *** Returns: DF=0 - success         ***
; ***          DF=1 - error           ***
; ***************************************
setdef:    ldn     rf                  ; get first byte
           lbz     getdef              ; jump if empty
           sep     scall               ; be sure name has a final slash
           dw      finalsl
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           sep     scall               ; attempt to open directory
           dw      opendir
           irx    
           ldxa
           phi     rf
           ldx
           plo     rf
           lbdf    setdefer            ; jump if it did not exist
           ldi     high defdir         ; point to default directory
           phi     rd
           ldi     low defdir
           plo     rd
setdeflp:  lda     rf                  ; copy byte from path
           str     rd                  ; to default directory
           inc     rd
           lbnz    setdeflp            ; loop back until all bytes copied
getdefex:  ldi     0                   ; signal success
           lskp
setdefer:  ldi     1                   ; need 1 for error code
setdefex:  shr                         ; shift result into df
           irx                         ; recover consumed registers
           ldxa
           phi     rd
           ldx
           plo     rd
           sep     sret                ; and return to caller
getdef:    glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           ldi     high defdir         ; get address of default directory
           phi     rd
           ldi     low defdir
           plo     rd
getdeflp:  lda     rd                  ; read byte from default path
           str     rf                  ; store into users buffer
           inc     rf
           lbnz    getdeflp            ; loop until full path copied
           lbr     getdefex            ; return to caller

; *************************************
; *** Change/view current directory ***
; *** RF - pathname                 ***
; ***      first byte 0 to view     ***
; *** Returns: DF=0 - success       ***
; ***          DF=1 - error         ***
; *************************************
chdir:     ldn     rf                  ; get first byte of pathname
           lbz     viewdir             ; jump if to view
           sep     scall               ; check for final slash
           dw      finalsl
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           sep     scall               ; find directory
           dw      finddir
           plo     re                  ; save result code
           irx                         ; recover consumed registers
           ldxa
           phi     rf
           ldxa
           plo     rf
           ldxa
           phi     rd
           ldxa
           plo     rd
           ldxa
           phi     rc
           ldx
           plo     rc
           lbdf    chdirerr            ; jump on error
           glo     ra                  ; save consumed register
           stxd
           ghi     ra
           stxd
           ldi     high path           ; point to current dir storage
           phi     ra
           ldi     low path
           plo     ra
           ldn     rf                  ; get first byte of path
           smi     '/'                 ; check for absolute
           lbz     chdirlp             ; jump if so
chdirlp2:  lda     ra                  ; find way to end of path
           lbnz    chdirlp2
           dec     ra                  ; back up to terminator
chdirlp:   lda     rf                  ; get byte from path
           str     ra                  ; store into path
           inc     ra
           smi     33                  ; loof for terminators
           lbdf    chdirlp             ; loop until terminator found
           irx                         ; recover consumed register
           ldxa
           phi     ra
           ldx
           plo     ra
           ldi     0                   ; indicate success
           shr
           sep     sret                ; and return to caller
chdirerr:  glo     re                  ; recover error
           lbr     error               ; and return with error
viewdir:   glo     rf                  ; save consumed registers
           stxd
           ghi     rf
           stxd
           glo     ra
           stxd
           ghi     ra
           stxd
           ldi     high path           ; get current dir
           phi     ra
           ldi     low path
           plo     ra
viewdirlp: lda     ra                  ; get byte from current dir
           str     rf                  ; write to output
           inc     rf
           lbnz    viewdirlp           ; loop until terminator found
           irx                         ; recover consumed registers
           ldxa
           phi     ra
           ldxa
           plo     ra
           ldxa
           phi     rf
           ldx
           plo     rf
           ldi     0                   ; indicate success
           shr
           sep     sret                ; and return to caller
           
; *******************************
; *** Remove a directory      ***
; *** RF - Pathname           ***
; *** Returns: DF=0 - success ***
; ***          DF=1 - Error   ***
; *******************************
rmdir:     sep     scall               ; check for final slash
           dw      finalsl
           glo     r7                  ; save consumed registers
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save consumed registers
           stxd
           ghi     r8
           stxd
           glo     r9                  ; save consumed registers
           stxd
           ghi     r9
           stxd
           glo     ra                  ; save consumed registers
           stxd
           ghi     ra
           stxd
           glo     rd                  ; save consumed registers
           stxd
           ghi     rd
           stxd
           glo     rc                  ; save consumed registers
           stxd
           ghi     rc
           stxd
           ghi     ra
           phi     rf
           glo     ra
           plo     rf
           sep     scall               ; open the directory
           dw      o_opendir
           lbnf    rmdirlp             ; jump if dir opened
           ldi     errnoffnd           ; signal not found error
rmdirerr:  shl
           ori     1
           shr
           lbr     delexit             ; and return
rmdirlp:   ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           ldi     high scratch        ; where to put it
           phi     rf
           ldi     low scratch
           plo     rf
           sep     scall               ; read the bytes
           dw      read
           glo     rc                  ; see if eof was hit
           smi     32
           lbnz    rmdireof            ; jump if dir was empty
           ldi     high scratch        ; point to buffer
           phi     rf
           ldi     low scratch
           plo     rf
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lda     rf                  ; see if entry is empty
           lbnz    rmdirno             ; jump if not
           lbr     rmdirlp             ; read rest of dir
rmdirno:   ldi     errdirnotempty      ; indicate not empty error
           lbr     rmdirerr            ; and error out
rmdireof:  sep     scall               ; get direcotry info from descriptor
           dw      getfddrsc
           sep     scall               ; get direcotry info from descriptor
           dw      getfddrof
           sep     scall
           dw      readsys
           ghi     r9                  ; get offset into sector
           adi     1
           phi     r9
           inc     r9                  ; point to starting lump
           inc     r9
           lbr     delgo               ; and delete the dir


; ************************************************
; *** Initialize all vectors and data pointers ***
; ************************************************
coldboot:  ldi     high start          ; get return address for setcall
           phi     r6
           ldi     low start
           plo     r6
           ldi     0                   ; setup temporary stack
           phi     r2
           ldi     255
           plo     r2
           sex     r2                  ; point x to stack
           lbr     f_initcall          ; setup call and return


kinit:     sep     scall               ; force ide reset
           dw      f_idereset
           ldi     high path           ; set path
           phi     rf
           ldi     low path
           plo     rf
           ldi     '/'
           str     rf
           inc     rf
           ldi     0
           str     rf
           ldi     high stack          ; reset the stack
           phi     r2
           ldi     low stack
           plo     r2
           sex     r2                  ; be sure x pointes to stack
           sep     scall               ; get shift count for lump size
           dw      lmpsize
           sep     sret                ; return to caller

start:     sep     scall               ; execute init procedures
           dw      kinit

; ********************************
; *** Attempt to execute /INIT ***
; ********************************
           ldi     high initprg        ; point to init program command line
           phi     rf
           ldi     low initprg
           plo     rf
           sep     scall               ; attempt to execute it
           dw      o_exec
           lbnf    welcome             ; jump if no error
#ifndef ELF2K
default:   sep     scall               ; get terminal baud rate
           dw      f_setbd
#endif
welcome:   ldi     high bootmsg
           phi     rf
           ldi     low bootmsg
           plo     rf
           sep     scall
           dw      d_msg
warmboot:  ldi     high stack          ; reset the stack
           phi     r2
           ldi     low stack
           plo     r2
           sex     r2                  ; be sure x pointes to stack

           ldi     high shellprg       ; point to command shell name
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
           dw       d_msg                ; function to print a message


           ldi      high keybuf          ; place address of keybuffer in R6
           phi      rf
           ldi      low keybuf
           plo      rf
           sep      scall
           dw       o_input              ; function to get keyboard input
           ldi      high crlf            ; get address of prompt into R6
           phi      rf
           ldi      low crlf  
           plo      rf
           sep      scall
           dw       d_msg                ; function to print a message

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
           dw       d_msg
           lbr      cmdlp                ; loop back for next command

; *****************************
; *** Validate filename     ***
; *** RF - filename         ***
; *** Returns: DF=1 invalid ***
; ***          DF=0 valid   ***
; *****************************
validate:  ldn     rf                  ; check for zero length
           lbz     invalid             ; jump on invalid entry
           glo     rf                  ; save position
           stxd
           ghi     rf
           stxd
           glo     rc
           stxd
slash:     ldi     0                   ; setup character count
           plo     rc
valid_lp:  lda     rf                  ; get next byte
           lbz     isvalid             ; jump if terminator found
           inc     rc                  ; increment count
           sep     scall               ; see if alphanumeric
           dw      f_isalnum
           lbdf    valid_lp
           plo     re                  ; save a copy
           smi     '-'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '_'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '.'                 ; check other valid characters
           lbz     valid_lp
           glo     re                  ; recover characters
           smi     '/'                 ; check other valid characters
           lbnz    invalid             ; otherwise invalid
           lbr     slash               ; reset counter on directory separator
isvalid:   glo     rc                  ; get count
           lbz     invalid             ; zero lenght is invalid
           smi     19                  ; must be under 19 characters
           lbdf    invalid
           adi     0                   ; indicate valid filename
           lskp                        ; recover filename address
invalid:   smi     0                   ; indicate invalid file
val_ret:   irx                         ; recover rf
           ldxa
           plo     rc
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; return

; ****************************************
; *** Be sure a name has a final slash ***
; *** RF - pointer to filename         ***
; ****************************************
finalsl:   glo     rf                  ; save filename position
           stxd
           ghi     rf
           stxd
finalsllp: lda     rf                  ; look for terminator
           lbnz    finalsllp
           dec     rf                  ; move to char prior to terminator
           dec     rf
           lda     rf                  ; and retrieve it
           smi     '/'                 ; is it final slash
           lbz     finalgd             ; jump if so
           ldi     '/'                 ; add slash to name
           str     rf
           inc     rf
           ldi     0                   ; and new terminator
           str     rf
           inc     rf
finalgd:   irx                         ; recover filename position
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; and return

; *******************************************
; *** Get date and time                   ***
; *** Returns: RA - date in packed format ***
; ***          RB - time in packes format ***
; *******************************************
gettmdt:   glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd
           sep     scall               ; get devices
           dw      f_getdev
           glo     rf
           ani     010h                ; see if RTC is installed
           lbz     no_rtc              ; jump if no rtc
           ldi     0                   ; point to scratch area
           phi     rf
           plo     rf
           sep     scall               ; get time and date
           dw      f_gettod
           lbdf    no_rtc              ; jump if rtc is unreadable
           ldi     0                   ; point to scratch area
           phi     rf
           plo     rf
rtc_cont:  inc     rf                  ; point to year
           inc     rf
           ldn     rf                  ; retrieve year
           phi     ra                  ; place into output
           dec     rf                  ; point to month
           dec     rf
           lda     rf                  ; retrieve it
           ani     0fh                 ; keep only bottom 3 bits
           shl                         ; shift into correct position
           shl
           shl
           shl
           shl
           plo     ra                  ; place into output 
           ghi     ra                  ; get high byte 
           shlc                        ; shift in high bit of month
           phi     ra                  ; ra now has year and high bit of month
           lda     rf                  ; retrieve day
           ani     01fh                ; mask off unnneded bits
           str     r2                  ; prepare to combine
           glo     ra                  ; get month
           or                          ; combine with day
           plo     ra                  ; now ra has full date
           inc     rf                  ; point to hours
           lda     rf                  ; and retrieve
           ani     01fh                ; mask it
           shl                         ; and shift into position 
           shl
           shl
           str     r2                  ; set aside
           ldn     rf                  ; get minutes
           shr                         ; get high 3 bits
           shr
           shr
           or                          ; and combine with hours
           phi     rb                  ; place into answer
           lda     rf                  ; retrieve minutes
           shl                         ; shift into position
           shl
           shl 
           shl
           shl
           str     r2                  ; prepare for combination
           ldn     rf                  ; get seconds
           shr                         ; divide by 2
           ani     01fh                ; mask it
           or                          ; combine with bottom half of minutes
           plo     rb                  ; place into answer
gettm_dn:  irx                         ; recover consumed register
           ldxa
           phi     rf
           ldx
           plo     rf
           sep     sret                ; and return

no_rtc:    ldi     high date_time      ; point to stored date/time
           phi     rf
           ldi     low date_time
           plo     rf
           lbr     rtc_cont            ; continue

bootmsg:   db      'Starting Elf/OS ...',10,13
           db      'Version 0.3.0',10,13
           db      'Copyright 2004-2020 by Michael H Riley',10,13,0
prompt:    db      10,13,'Ready',10,13,': ',0
crlf:      db      10,13,0
errnf:     db      'File not found.',10,13,0
initprg:   db      'INIT',0
shellprg:  db      '/BIN/shell',0
defdir:    db      '/BIN/',0
           ds      80

lmpshift:  db      0
lmpmask:   db      0
path:      ds      128
intdta:    ds      512
mddta:     ds      512
           ds      128
stack:     db      0


