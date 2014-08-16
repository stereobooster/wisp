; expected:
; ((2 (foo)) (2) (0) (0) (2 foo : moo 
; ) (4 #{.}# [goo #{.}# hoo]))
display  
  call-with-input-string  "  (foo) ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\n  foo : moo \"\n\" \n___ . [goo . hoo]" wisp-scheme-read-chunk
newline
