#!/usr/bin/env sh
# -*- wisp -*-
guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile-2.0 -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples fib)' -c '' "$@"
; !#

define-module : examples fib
    . #:export : main

;; Fibonacci Functions

define : fibonacci n
    . "Get Fibonacci Element N in Linear Time"
    let rek : (i 0) (u 1) (v 1)
        if : >= i : - n 2
            . v
            rek (+ i 1) v (+ u v) ; else

; display : fib 5

;; Try it with curly infix

;; First activate curly infix
. #!curly-infix 

;; Now define fibonacci with curly infix.
define : fibonacci n
    . "Get Fibonacci Element N in Linear Time"
    let rek : (i 0) (u 1) (v 1)
        if {i >= {n - 2}}
            . v
            rek {i + 1} v {u + v}

display 
  . {1 + 1}
newline

;; And a complete infix-fibonacci
define : fibcurl2 n
    . "Get Fibonacci Elements in Linear Time"
    let rek : (i 0) (u 1) (v 1)
        if { i >= { n - 2 } }
            . v
            rek { i + 1 } v { u + v }

define : main args
    display : fibcurl2 5
    newline
