#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples enter-three-witches) main)' -s "$0" "$@"
; !#

define-module : examples enter-three-witches

use-modules : ice-9 optargs

define-syntax Enter
 syntax-rules ()
  : _ (name) b ...
    begin
      define-syntax name
        syntax-rules ::: ()
          : _ (c :::) d :::
            format #t "~A\n  ~A\n\n" 
               string-join 
                 string-split (symbol->string 'name) #\_
               string-join 
                 map : lambda (x) (string-join (map symbol->string x))
                       quote : (c :::) d :::
                 . "\n  "
          : _ c d :::
            ;; allow for modifier keywords after the name
            begin
              format #t "~A:\n" : symbol->string 'c
              name d :::
          : _ c :::
            begin #t c :::
      Enter b ...
  : _ b ...
    begin 


define : main args
  Enter : First_Witch
          Second_Witch
          Third_Witch
  
  First_Witch
      When shall we three meet again
      In thunder, lightning, or in rain?
  
  Second_Witch
      When the hurlyburly's done,
      When the battle's lost and won.

  Third_Witch
      That will be ere the set of sun.
