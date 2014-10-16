; works
display  
  call-with-input-string  "  foo ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\n  foo : moo \"\n\" \n___ . goo . hoo" wisp-scheme-read-chunk
newline
display
  call-with-input-string  "  foo \n___. goo . hoo" wisp-scheme-read-chunk
newline

; broken
; expected:
display  
  call-with-input-string  "  (foo) ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\n  foo : moo \"\n\" \n___ . [goo . hoo]" wisp-scheme-read-chunk
newline
display
  call-with-input-string  "  foo \n___. [goo . hoo]" wisp-scheme-read-chunk
newline
