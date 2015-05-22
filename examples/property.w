#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples property) main)' -s "$0" "$@"
; !#

define-module : examples property
              . #:export : main

; FIXME: this does not work when called from guile, but it works when
; first translating it to scheme and then calling the scheme file.

define y 5
define-syntax z
  make-variable-transformer
   lambda : x
     syntax-case x : set!
       : set! var val
         quasisyntax : set! y : + 1 val
       : var arg ...
         quasisyntax : y arg ...
       var : identifier? #'var
         quasisyntax y


define : main args
         write args
         newline
         write z
         newline
         set! z 5
         write z
         newline
