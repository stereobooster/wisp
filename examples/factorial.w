#!/usr/bin/env sh
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples factorial) main)' -s "$0" "$@"
; !#

define-module : examples factorial
              . #:export : factorial

define : factorial n            ;   (define (factorial n)
    if : zero? n                ;       (if (zero? n)
       . 1                      ; =>        1
       * n : factorial {n - 1}  ;           (* n (factorial {n - 1}))))

define : main args
         display : factorial 5
         newline

