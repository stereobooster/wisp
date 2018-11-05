#!/usr/bin/env bash
# -*- wisp -*-
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples say)' -c '' "$@"
; !#

; Simple specialized syntax for writing natural text with scheme.

define-module : examples say
              . #:export : main

; TODO: rewrite for syntax-case with recursion into sub-lists.
;       Goal: say Yes, this works ,(red 1 2) .

; TODO: longterm goal: simply syntax for writing plays. The header
;       with active persons defines macros which are like say, but
;       personalized. The code should read like the output of
;       classical JRPGs.

define-syntax-rule : say a ...
  format #t "~A\n" 
    string-join 
      map symbol->string : quote : a ...

define : main argv
         say Yes, this works!
