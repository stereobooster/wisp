#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (guildhall ext foof-loop))'
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples fizzbuzz)' -c '' "$@"
; !#

define-module : examples fizzbuzz
    . #:export : main

;; this example needs foof-loop installed via guildhall!
import : guildhall ext foof-loop
;; Pseudocode adapted from 
;; http://en.wikipedia.org/wiki/Pseudocode#Syntax
define : divisible? number divisor
         = 0 : remainder number divisor

define : fizzbuzz
  let
    : print_number #f
    loop
      : for i : up-from 1 : to 100
      set! print_number #t
      when : divisible? i 3
          display "Fizz"
          set! print_number #f
      when : divisible? i 5
          display "Buzz"
          set! print_number #f;
      when print_number : display i
      newline

define : main args
    fizzbuzz
