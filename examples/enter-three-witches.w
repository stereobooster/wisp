#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples enter-three-witches) main)' -s "$0" "$@"
; !#

define-module : examples enter-three-witches

define-syntax Enter
 syntax-rules ()
  : _ name b ...
    begin
      define-syntax name
        syntax-rules ::: ()
          : _ words :::
            format #t "~A\n" 
              string-join 
                map : lambda (x) (string-join (map symbol->string x))
                      quote : words :::
                . "\n"
      Enter b ...
  : _ b ...
    begin 

; define-syntax-rule : First_Witch a ...
;   format #t "~A\n" 
;     string-join 
;       map : lambda (x) (string-join (map symbol->string x))
;             quote : a ...
;       . "\n"

define : main args
  Enter First_Witch
  First_Witch
      When shall we three meet again
      In thunder, lightning, or in rain?
