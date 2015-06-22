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
       . "Convert a positive integer to Tanteks new base 60."
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
       . "Convert a new base 60 string into a positive integer."
       let loop
         : n 0
           s string
         if : equal? "" s
            . n
            loop
              + : assoc-ref base60numbers : string-ref s 0
                * n 60
              string-drop s 1

define : date->sxg year month day hour minute second
       . "Convert a date into new base 60 format:
          yyyymmdd hhmmss -> YYMD-hms (can extend till 3599)
         "
       format #f "~A-~A" 
           apply string-append
             map integer->sxg
                 list year month day
           apply string-append 
             map integer->sxg
                 list hour minute second


define : main args
         cond
           : or (= 1 (length args)) (member "--help" args)
             format #t "usage: ~A [integer | -d string | --datetime | --datetime year month day hour minute second | --help]\n" : list-ref args 0
           : and (= 7 (length args)) : equal? "--datetime" : list-ref args 1
             format #t "~A\n" : apply date->sxg : map string->number : drop args 2
           : and (= 2 (length args)) : equal? "--datetime" : list-ref args 1
             let : : tm : localtime : current-time
               format #t "~A\n" : apply date->sxg : list (+ 1900 (tm:year tm)) (+ 1 (tm:mon tm)) (tm:mday tm) (tm:hour tm) (tm:min tm) (tm:sec tm)
           : and (= 3 (length args)) : equal? "-d" : list-ref args 1
             format #t "~A\n" : sxg->integer : list-ref args 2
           : = 2 : length args
             format #t "~A\n" : integer->sxg : string->number : list-ref args 1

