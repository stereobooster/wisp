#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples say) main)' -s "$0" "$@"
; !#

; Simple specialized syntax for writing natural text with scheme.

define-module : examples say
              . #:export : main

define-syntax-rule : say a ...
  format #t "~A\n" 
    string-join 
      map symbol->string : quote : a ...

define : main argv
         say Yes, this works!
