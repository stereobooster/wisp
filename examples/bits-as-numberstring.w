#!/usr/bin/env bash
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples bits-as-numberstring)' -c '' "$@"
; !#

define-module : examples bits-as-numberstring
   . #:export : main

import : examples doctests
         srfi srfi-1 ; list operations
         srfi srfi-37 ; commandline parsing
         srfi srfi-60 ; bit conversion via integer->list 
         rnrs bytevectors
         rnrs io ports
         ice-9 match
         ice-9 format
         ice-9 rdelim ; for read-string
         ice-9 binary-ports
         ice-9 pretty-print

format : current-error-port
    . "THIS CODE HAS SERIOUS ISSUES with the bits->bytes->hammingencode->bits->bytes->hammingdecode->bits due to byte-bits-alignment, except if the number of checkbits is a multiple of 8. 16 to 31 chara"

define : read-file filepath
    let* 
        : port : open-input-file filepath
          data : get-bytevector-all port
        close port
        . data

define : write-file filepath bytevector
    let* 
        : port : open-output-file filepath
        put-bytevector port bytevector
        close port


define : u8->bits u8
    ## tests : test-equal '(#t #f #f #f #f #f #t #t) : u8->bits 131
    let loop
        : bits : list
          remaining u8
          pow2 128
        cond
          {pow2 < 1}
            reverse bits
          {remaining > pow2}
            loop : cons #t bits
                 . {remaining - pow2}
                 / pow2 2
          else
            loop : cons #f bits
                 . remaining
                 / pow2 2


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
            {(length bits) < 8} ;; zero-pad;; FIXME: This is wrong, somewhere there is a bug here.
              let : : bits : append bits : make-list {8 - (length bits)} #f
                loop 
                  cons : list->integer : take bits 8
                       . bytes
                  drop bits 8
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


define : bitlist->bitstring bitlist
    string-join : map number->string bitlist
       . ""

define : encode infile outfile
    ;; pretty-print : bits->bytevector : numbers->bits : bits->numbers : bytevector->bits : read-file filepath
    write-file outfile
      string->bytevector ;; write 0 and 1 as letters
        bitlist->bitstring : bits->numbers : bytevector->bits : read-file infile
        native-transcoder
    newline
    

define : decode infile outfile
    pretty-print : read-file infile
    display : bitlist->bitstring : bits->numbers : bytevector->bits : read-file infile
    newline
    write-file outfile ;; write bits
        bits->bytevector
            map : λ (x) (if (equal? x #\0) #f #t)
                string->list : bytevector->string (read-file infile) : native-transcoder

define %this-module : current-module
define : main args
    when : null? : cdr args
         doctests-testmod %this-module
         exit 0
    when {(length args) < 3}
        format : current-error-port
           . "must have at least one argument, but got ~a" : cdr args
           exit 1
    if : equal? "-D" : second args
         decode (third args) (fourth args)
         encode (second args) (third args)
