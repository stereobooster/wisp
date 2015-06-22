#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples newbase60) main)' -s "$0" "$@"
; !#

;; Encoding and decoding numbers in New Base 60 as defined by Tantek:
;; http://tantek.pbworks.com/NewBase60

;; Based on the very elegant implementation from Kevin Marks licensed under CC0:
;; https://github.com/indieweb/newBase60py/blob/master/newbase60.py

define-module : examples newbase60
              . #:export : integer->sxg sxg->integer
              . #:use-module : srfi srfi-1
;               . #:use-module : ice-9 match

define base60letters "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz"
define base60numbers
       append
         map cons (string->list base60letters) : iota : string-length base60letters
         quote
           : #\l . 1 ; typo lowercase l to 1
             #\I . 1 ; typo capital I to 1
             #\O . 0 ; typo capital O to 0

define : integer->sxg num
         if : equal? 0 num
            . "0"
            let loop
              : s '()
                n num
              if : equal? n 0
                 list->string s
                 loop
                   cons (string-ref base60letters (remainder n 60)) s
                   quotient n 60

define : sxg->integer string
         let loop
           : n 0
             s string
           if : equal? "" s
              . n
              loop
                + : assoc-ref base60numbers : string-ref s 0
                  * n 60
                string-drop s 1

define : main args
         display : sxg->integer : integer->sxg 60

