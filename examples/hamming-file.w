#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(@@ (examples hamming-file) main)' -s "$0" "$@"
; !#

define-module : examples hamming-file
import : examples doctests
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


define : must-be-bit number
    when : not : member number '(0 1)
        error "Number is no bit: must be 0 or 1, but was ~a" number

define : checkbit-indizes-for number
    ## : tests : test-equal '(2 4) : checkbit-indizes-for 6
    define all-smaller-pow2
      let loop
        : smaller : list 1
        if : < number : car smaller
             cdr smaller
             loop
                 cons : * 2 : car smaller
                      . smaller
    let loop
        : smaller all-smaller-pow2
          needed-numbers : list
          remaining number
        cond 
           : zero? remaining
             . needed-numbers
           {remaining >= (car smaller)}
              loop : cdr smaller
                     cons (car smaller) needed-numbers
                     - remaining : car smaller
           else
             loop : cdr smaller
                  . needed-numbers remaining


define : power-of-2? number
    integer?
        / : log number
            log 2


define : checked-by checkbit-index max-index
    ## : tests : test-equal '(3 5 7 9 11) : checked-by 1 11
    when : not : power-of-2? checkbit-index
        error 'invalid-checkbit-index 
            . "checkbits must be a power of two, but this was ~a"
            . checkbit-index
    let loop
        : index max-index
          checked-indizes : list
        cond
            {index <= checkbit-index}
              . checked-indizes ;; need to walk forward through
                                      ;; the data for checking
            : member checkbit-index : checkbit-indizes-for index
              loop {index - 1} : cons index checked-indizes
            else
              loop {index - 1} checked-indizes
              




define : encode filepath
    pretty-print : bits->bytevector : numbers->bits : bits->numbers : bytevector->bits : read-file filepath
    pretty-print : read-file filepath
    

define %this-module : current-module
define : main args
    when : null? : cdr args
         doctests-testmod %this-module
         exit 0
    when {(length args) < 2}
        format : current-error-port
           . "must have at least one argument, but got ~a" : cdr args
           exit 1
    if : equal? "-D" : second args
         decode : third args
         encode : second args
