#!/usr/bin/env bash
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples factorial)' -c '' "$@"
; !#

define-module : examples factorial
              . #:export : factorial main

define : factorial n            ;   (define (factorial n)
    if : zero? n                ;       (if (zero? n)
       . 1                      ; =>        1
       * n : factorial {n - 1}  ;           (* n (factorial {n - 1}))))

define : main args
         display : factorial 5
         newline

