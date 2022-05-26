
           proc    final

bootmsg:   db      'Starting Elf/OS ...',10,13
           db      'V4.1.1',10,13,0
prompt:    db      10,13,'Ready',10,13,': ',0
crlf:      db      10,13,0
errnf:     db      'File not found.',10,13,0
initprg:   db      '/bin/init',0
shellprg:  db      '/bin/shell',0
defdir:    db      '/bin/',0
           ds      80

intdta:    ds      512
mddta:     ds      512
;           ds      128
;stack:     db      0

           public  bootmsg
           public  prompt
           public  crlf
           public  errnf
           public  initprg
           public  shellprg
           public  defdir
           public  intdta
           public  mddta

           endp
