#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples factorial) main)' -s "$0" "$@"
; !#

define-module : examples factorial
              . #:export : factorial

define : factorial n            ;   (define (factorial n)
    if : zero? n                ;       (if (zero? n)
       . n                      ; =>        n
       * n : factorial {n - 1}  ;           (* n (factorial {n - 1}))))

define : main args
         display : factorial 5
         newline

