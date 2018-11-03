#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples yinyang)' -c '' "$@"
; !#

define-module : examples yinyang
   . #:export : main

define : main args
    ;; from http://en.wikipedia.org/wiki/Scheme_%28programming_language%29
    let* 
       :
         yin
             : lambda (cc) (display "@") cc
               call/cc : lambda (c) c
         yang
             : lambda (cc) (display "*") cc 
               call/cc : lambda (c) c
       yin yang
