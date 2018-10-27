#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(@@ (examples hamming-file) main)' -s "$0" "$@"
; !#

define-module : examples hamming-file
import
         srfi srfi-1 ; list operations
         srfi srfi-37 ; commandline parsing
         srfi srfi-60 ; bit conversion via integer->list 
         rnrs bytevectors
         ice-9 match
         ice-9 format
         ice-9 rdelim ; for read-string
         ice-9 binary-ports
         ice-9 pretty-print

define : read-file filepath
    let* 
        : port : open-input-file filepath
          data : get-bytevector-all port
        close port
        . data

define : bytevector->bits bv
    let loop 
        : bits : list
          bytes : bytevector->u8-list bv
        cond
            : null? bytes
              . bits
            else
              loop : append bits : integer->list (first bytes) 8
                     cdr bytes

define : bits->bytevector bits
    let loop 
        : bytes : list
          bits bits
        cond
            : null? bits
              u8-list->bytevector : reverse! bytes
            else
              loop 
                  cons : list->integer : take bits 8
                       . bytes
                  drop bits 8

define : bits->numbers bits
   map : lambda (x) : if x 1 0
       . bits

define : numbers->bits numbers
   map : lambda (x) : if (equal? x 0) #f #t
       . numbers



define : encode filepath
    pretty-print : bits->bytevector : numbers->bits : bits->numbers : bytevector->bits : read-file filepath
    pretty-print : read-file filepath
    

define : main args
    when {(length args) < 2}
        format : current-error-port
           . "must have at least one argument, but got ~a" : cdr args
           exit 1
    if : equal? "-D" : second args
         decode : third args
         encode : second args
