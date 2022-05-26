#include   macros.inc

; *******************************************
; *** Get date and time                   ***
; *** Returns: RA - date in packed format ***
; ***          RB - time in packes format ***
; *******************************************
           proc    gettmdt

scall:     equ     4
sret:      equ     5

           extrn   date_time
           extrn   o_getdev
           extrn   o_gettod

           glo     rf                  ; save consumed register
           stxd
           ghi     rf
           stxd
           sep     scall               ; get devices
           dw      o_getdev
           glo     rf
           ani     010h                ; see if RTC is installed
           lbz     no_rtc              ; jump if no rtc
           ldi     0                   ; point to scratch area
           phi     rf
           plo     rf
           sep     scall               ; get time and date
           dw      o_gettod
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

           endp

