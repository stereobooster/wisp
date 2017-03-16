#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples power-iteration) main)' -s "$0" "$@"
; !#

;; Power iteration, following https://en.wikipedia.org/wiki/Power_iteration#The_method

define-module : examples power-iteration
              . #:export : step

import : srfi srfi-1

define A '((1 2 3) (1 2 3) (1 2 4))
define b '(1 1 1)


define : M*v A b
    . "Matrix by vector product"
    if : = 0 : length A
       . '()
       let lp : (res '()) (head 0) (i 0) (j 0)
         cond
            {i >= (length A)}
                reverse res
            {j >= (length (list-ref A 0))}
                lp (cons head res) 0 (+ 1 i) 0
            else
                lp res
                   + head 
                     * : list-ref (list-ref A i) j
                         list-ref b j
                   . i
                   + 1 j

define : main args
    write : M*v A b
    newline
