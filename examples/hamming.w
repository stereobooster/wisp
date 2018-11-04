#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples hamming)' -c '' "$@"
; !#

define-module : examples hamming
              . #:export : main
import : examples doctests
         srfi srfi-1 ; list operations
         srfi srfi-37 ; commandline parsing
         srfi srfi-60 ; bit conversion via integer->list 
         ice-9 match
         ice-9 format


define : mod2sum . numbers
       . "Modulo-2 sum, i.e. for even parity"
       ##
           tests : test-eqv 1 (mod2sum 1 0 1 1 0)
       modulo (apply + numbers) 2

define : flip numbers index
    . "flip the bit-number (0→1 or 1→0) at the index."
    ## : tests : test-equal '(1 0 1) : flip '(0 0 1) 0
    append
        take numbers index
        list : mod2sum 1 : list-ref numbers index
        drop numbers {index + 1}


define : hamming-11/7-encode numbers
       . "Hamming encoding for a list of 7 zeros or ones."
       ##
           tests
               test-equal '(0 0 1 0 0 0 0 1 0 0 1)
                   hamming-11/7-encode '(1 0 0 0 0 0 1)

       define : H . bits
           apply mod2sum bits
       match numbers
           : i3 i5 i6 i7 i9 i10 i11
             list
                 H i3 i5 i7 i9 i11  ;; bit 1
                 H i3 i6 i7 i10 i11 ;; bit 2
                 . i3               ;; bit 3
                 H i5 i6 i7         ;; bit 4
                 . i5 i6 i7         ;; bit 5, 6, 7
                 H i9 i10 i11       ;; bit 8
                 . i9 i10 i11       ;; bit 9, 10, 11


define : hamming-11/7-decode numbers
       . "Hamming decoding for a list of 11 zeros or ones"
       ##
         tests
             test-equal '(1 0 0 0 0 0 1)
                 hamming-11/7-decode '(0 0 1 0 0 0 0 1 0 0 1)
             test-equal '(1 0 0 0 0 0 1)
                 hamming-11/7-decode : flip '(0 0 1 0 0 0 0 1 0 0 1) 5
             test-equal '(0 1 0 0 0 0 1)
                 hamming-11/7-decode '(0 1 0 1 1 1 0 1 0 0 1)
                 
       define m2+ mod2sum
       define broken-bit
          match numbers
              : h1 h2 i3 h4 i5 i6 i7 h8 i9 i10 i11
                +
                  * 1 : m2+ h1 i3 i5 i7 i9 i11
                  * 2 : m2+ h2 i3 i6 i7 i10 i11
                  * 4 : m2+ h4 i5 i6 i7
                  * 8 : m2+ h8 i9 i10 i11
       define fixed
           if : zero? broken-bit
              . numbers
              flip numbers {broken-bit - 1}
       match fixed
           : h1 h2 i3 h4 i5 i6 i7 h8 i9 i10 i11
             list i3 i5 i6 i7 i9 i10 i11




;; commandline interaction

define : help . args ; args used for simpler option parsing
         format #t "Usage: ./hamming.w [option ...] [--] input | file | -

Encode or decode the input, file or stdin.

  -h --help      display this help and exit
     --test      run unit tests
  -E --encode-text-bits
                 encode 7 bits given as numbers (0 or 1) using an 11,7 hamming code
  -D --decode-text-bits
                 decode 11 bits given as numbers (0 or 1) using an 11,7 hamming code
  -V --version   output version information and exit
  -d [LEVEL] --debug[=LEVEL]
                 set logging to debug or to the given level
"
         exit 0

define : test . args
  doctests-testmod %this-module


define test-option
  option '(#f "test")
          . #f #f test

define help-option
  option '(#\h "help")
          . #f #f help

define : version . args
         display "hamming 0.0.0

Copyright (C) 2018 Arne Babenhauserheide.
See the file COPYING. There is NO warranty.
"
         exit 0

define version-option
  option '(#\V "version")
          . #f #f version

define : debug?
    equal? 'debug : assoc-ref %options 'log-level


define debug-option
  let
    : required #f
      can-take-argument #t
    option '(#\d "debug")
          . required can-take-argument
          λ : option name arg operands
              if arg
                 set! %options : alist-cons 'log-level (string->symbol arg) %options
                 set! %options : alist-cons 'log-level 'debug %options
              format : current-error-port
                     . "debug: activate log level ~a\n"
                     if arg arg 'debug
              . operands


define : text-bits->number-bits text-bits
    define : char->bit char
        if : equal? char #\0
           . 0 1
    map char->bit : string->list text-bits

define : show-text-bit-operation operation text-bits
    let : : bits : text-bits->number-bits text-bits
        display
            string-join
                map number->string 
                    operation bits
                . ""
        newline
        when : debug?
            format : current-error-port
                   . "in: ~a\n"
                   .  text-bits

define : encode-text-bits text-bits
    show-text-bit-operation hamming-11/7-encode text-bits

define : decode-text-bits text-bits        
    show-text-bit-operation hamming-11/7-decode text-bits



define encode-text-bits-option
   option '(#\E "encode-text-bits")
           . #f #f
           λ : option name arg operands
               set! %options : assoc-set! %options 'operation encode-text-bits

define decode-text-bits-option
   option '(#\D "decode-text-bits")
           . #f #f
           λ : option name arg operands
               set! %options : assoc-set! %options 'operation decode-text-bits

define %options
    `
      log-level . info
      operation . ,encode-text-bits

define %option-list
    list test-option help-option version-option debug-option encode-text-bits-option decode-text-bits-option

define : action operand
       . "Run the action set by the options"
       : assoc-ref %options 'operation
         . operand

define : parse-args args
         args-fold args
            . %option-list
            λ : option name arg operands
              format : current-error-port
                     . "unrecognized command line argument name: ~a arg: ~a operands: ~a\n"
                     . name arg operands
              exit 1
            λ : operand operands ;; operand = argument (not option)
              action operand
            . '() ;; option operands (seed)
          

define %this-module : current-module
define : main args
    if : null? : cdr args
         help
         parse-args : cdr args

