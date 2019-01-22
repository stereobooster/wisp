#!/usr/bin/env bash
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples map-product-sums)' -c '' "$@"
; !#

define-module : examples map-product-sums
   . #:export : main

use-modules : srfi srfi-42

define : list-product-sums list-of-numbers
       . "return a list with the sum of the products of each number with all other numbers.

         >>> map-product-sums '(2 4 6)
         (list (+ (* 2 4) (* 2 6)) (+ (* 4 2) (* 4 6)) (+ (* 6 2) (* 6 4)))
         "
       map (lambda (x) (apply + x))
           list-ec (: i list-of-numbers)
               map (lambda (x) (* i x))
                   cons (- i) list-of-numbers


define : main . args
  write : list-product-sums '(2 4 6)

