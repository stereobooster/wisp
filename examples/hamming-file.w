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
         ## : tests : test-equal #t : power-of-2? 1
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


define : prepare-hamming-vector data-vector
    ## : tests : test-equal #1(#f #f 1 #f 0 1) : prepare-hamming-vector #1(1 0 1)
    define data-length : vector-length data-vector
    let loop
        : hamming : list
          data-index 0
          checkbit-count 0
        cond
          {data-index >= data-length}
            apply vector
                reverse hamming
          : power-of-2? : + 1 data-index checkbit-count
            loop : cons #f hamming
                 . data-index
                 + 1 checkbit-count
          else
              loop
                  cons : vector-ref data-vector data-index
                       . hamming
                  + 1 data-index
                  . checkbit-count


define : mod2sum . numbers
       . "Modulo-2 sum, i.e. for even parity"
       ##
           tests : test-eqv 1 (mod2sum 1 0 1 1 0)
       modulo (apply + numbers) 2

define : check-bit-value hamming-vector check-bit-index
    ## : tests : test-equal 1 : check-bit-value #1(#f #f 1 #f 0 1) 0
    define check-bit-hamming-index {check-bit-index + 1}
    define : hamming-bit-set? index
        vector-ref hamming-vector {index - 1}
    let 
        : checked : checked-by check-bit-hamming-index : vector-length hamming-vector
        let loop
            : sum 0
              checked
                  if : hamming-bit-set? check-bit-hamming-index
                       cons check-bit-hamming-index checked
                       . checked
            cond 
               : null? checked
                 . sum
               : null? : cdr checked ;; last element
                  mod2sum sum : vector-ref hamming-vector {(car checked) - 1}
               else
                  loop
                      mod2sum sum : vector-ref hamming-vector {(car checked) - 1}
                      cdr checked


define : set-check-bits! hamming-vector
    ## : tests : test-equal #1(1 0 1 1 0 1) : set-check-bits! : vector #f #f 1 #f 0 1
    let loop
        : checkbit-index 1
        cond 
            {checkbit-index > (vector-length hamming-vector)}
              . hamming-vector
            else
                vector-set! hamming-vector {checkbit-index - 1}
                    check-bit-value hamming-vector {checkbit-index - 1}
                loop {checkbit-index * 2}


define : get-data-bits hamming-vector
    ## : tests : test-equal #1(1 0 1) : get-data-bits : vector #f #f 1 #f 0 1
    let loop
        : data-hamming-indizes : remove power-of-2? : iota (vector-length hamming-vector) 1
          data : list
        if : null? data-hamming-indizes
           apply vector : reverse data
           loop : cdr data-hamming-indizes
                  cons : vector-ref hamming-vector {(car data-hamming-indizes) - 1}
                       . data
     

define : hamming-encode data-bits
    ## : tests : test-equal #1(1 0 1 1 0 1) : hamming-encode : vector 1 0 1
    let : : hamming-vector : prepare-hamming-vector data-bits
        set-check-bits! hamming-vector

define : bitlist->bitstring bitlist
    string-join : map number->string bitlist
       . ""

define : encode infile outfile
    ;; pretty-print : bits->bytevector : numbers->bits : bits->numbers : bytevector->bits : read-file filepath
    display : bitlist->bitstring : bits->numbers : bytevector->bits : read-file infile
    newline
    write-file outfile : bits->bytevector : numbers->bits : vector->list : hamming-encode : apply vector : bits->numbers : bytevector->bits : read-file infile
    

define : decode infile outfile
    ;; TODO: actually apply hamming decoding fixes
    pretty-print : read-file infile
    display : bitlist->bitstring : bits->numbers : bytevector->bits : read-file infile
    newline
    write-file outfile : bits->bytevector : numbers->bits : vector->list : get-data-bits : apply vector : bits->numbers : bytevector->bits : read-file infile
    

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
