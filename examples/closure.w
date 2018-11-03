#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples closure)' -c '' "$@"
; !#

;; A simple example for a closure

define-module : examples closure
    . #:export : main

define counting-closure ; simple variable
  let : : counter 0 ; provide counter to hold local data
    lambda () ; the variable is bound to a function -> callable
      set! counter : 1+ counter ; adjust the counter shared by all function calls
      . counter


; counter is created outside the function definition (lambda), so the
; change survives over function calls. It is function-local data.


define : main args
         display : counting-closure
         newline ; 1
         display : counting-closure
         newline ; 2
         display : counting-closure
         newline ; 3
