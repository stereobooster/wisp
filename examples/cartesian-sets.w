#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples cartesian-sets) main)' -s "$0" "$@"
; !#
;; Implementation of the cartesian product over a list of lists, building on http://stackoverflow.com/a/20591545/7666

define-module : examples cartesian-sets
   . #:export : cartesian-product

import : srfi srfi-1

;; original
define : cartesian-product-lambda . lists
  fold-right 
      lambda : xs ys
          append-map (lambda (x)
                      (map (lambda (y)
                             (cons x y))
                           ys))
                    . xs
      . '(())
      . lists


;; easier to understand
define : cartesian-product . lists
    define : product-of-two xs ys
         define : cons-on-each-ys x
             map : lambda (y) (cons x y)
                 . ys
         append-map cons-on-each-ys
                  . xs
    fold-right product-of-two '(()) lists

define : main args
    write : cartesian-product-lambda '(1 2) '(3 4) '(5 6)
    newline
    write : cartesian-product '(1 2) '(3 4) '(5 6)
    newline
