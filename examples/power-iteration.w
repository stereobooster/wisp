#!/usr/bin/env sh
# -*- wisp -*-
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples power-iteration)' -c '' "$@"
; !#

;; Power iteration, following https://en.wikipedia.org/wiki/Power_iteration#The_method

define-module : examples power-iteration
              . #:export : step main

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


define : normalize-squared v
     let lp : (norm 0) (idx 0)
         if {idx >= (length v)}
             let loop : (res '()) (i 0)
                if {i >= (length v)}
                    . res
                    loop 
                        cons : / (list-ref v i) : sqrt norm
                             . res
                        + 1 i
             lp
                 + norm : * (list-ref v idx) (list-ref v idx)
                 + idx 1
            

define : î-step elem prev
    normalize-squared : M*v A prev

define : main args
    let lp : (i 0)
        write : fold î-step b : iota i
        newline
        when {i < 10}
          lp {i + 1}
            
    write : normalize-squared : M*v A b
    newline
