#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples newbase60) main)' -s "$0" "$@"
; !#

;; Encoding and decoding numbers in New Base 60 as defined by Tantek:
;; http://tantek.pbworks.com/NewBase60

;; Based on the very elegant implementation from Kevin Marks licensed under CC0:
;; https://github.com/indieweb/newBase60py/blob/master/newbase60.py

define-module : examples newbase60
              . #:export : integer->sxg sxg->integer date->sxg sxg->date date->sxgepochdays sxgepochdays->yeardays yeardays->sxgepochdays
              . #:use-module : srfi srfi-1

define base60letters "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz"
define base60numbers
       append
         map cons (string->list base60letters) : iota : string-length base60letters
         quote
           : #\l . 1 ; typo lowercase l to 1
             #\I . 1 ; typo capital I to 1
             #\O . 0 ; typo capital O to 0

define : positive-integer->sxg num
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

define : positive-sxg->integer string
       . "Convert a positive new base 60 string into a positive integer."
       let loop
         : n 0
           s string
         cond 
           : equal? "" s
             . n
           else
             loop
               + : assoc-ref base60numbers : string-ref s 0
                 * n 60
               string-drop s 1

define : integer->sxg num
       . "Convert an integer to Tanteks new base 60."
       if : >= num 0
          positive-integer->sxg num
          string-append "-" : positive-integer->sxg : - num

define : sxg->integer str
       . "Convert a new base 60 string into an integer."
       if : and (>= (string-length str) 1) (equal? #\- (string-ref str 0))
          - : positive-sxg->integer : string-drop str 1
          positive-sxg->integer str

define : date->sxgepochdays year month day hour minute second
       let 
         : tm : gmtime 0 ; initialize 
         set-tm:year tm : - year 1900
         set-tm:mon tm month
         set-tm:mday tm day
         set-tm:hour tm hour
         set-tm:min tm minute
         set-tm:sec tm second
         let* 
           : epochseconds : car : mktime tm "+0" ; 0: UTC
             epochdays : quotient epochseconds : * 24 60 60
           integer->sxg epochdays

define : yeardays->sxgepochdays year yeardays
       let 
         : tm : car : strptime "%Y %j" : string-join : map number->string : list year yeardays
         let* 
           : epochseconds : car : mktime tm "+0" ; 0: UTC
             epochdays : quotient epochseconds : * 24 60 60
           integer->sxg epochdays

define : sxgepochdays->yeardays str
       . "Turn sexagesimal days since epoch into year (YYYY) and day of year (DDD)."
       let*
         : epochdays : sxg->integer str
           epochseconds : * epochdays 24 60 60
           tm : gmtime epochseconds
           year : + 1900 : tm:year tm
           yeardays : tm:yday tm
         list year (+ yeardays 1)

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

define : sxg->date str
       . "Convert a new base 60 date into a list:
          YYMD-hms -> (year month day hour minute second)
         "
       let*
         : centeridx : string-rindex str #\- ; rindex because the year could be negative
           getstr : lambda (s di) : string : string-ref str : + centeridx di
         let
           : year : substring/read-only str 0 : - centeridx 2
             month : getstr str -2
             day : getstr str -1
             hour : getstr str 1
             minute : getstr str 2
             second : getstr str 3
           map sxg->integer 
             list year month day hour minute second

define : main args
       let
         : help : lambda () : format #t "usage: ~A [integer | -d string | --datetime | --datetime year month day hour minute second | --help]\n" : list-ref args 0
         cond
           : or (= 1 (length args)) (member "--help" args)
             help
           : and (= 8 (length args)) : equal? "--datetime" : list-ref args 1
             format #t "~A\n" : apply date->sxg : map string->number : drop args 2
           : and (= 8 (length args)) : equal? "--sxgepochdays" : list-ref args 1
             format #t "~A\n" : apply date->sxgepochdays : map string->number : drop args 2
           : and (= 4 (length args)) : equal? "--sxgepochdays-from-yearday" : list-ref args 1
             format #t "~A\n" : apply yeardays->sxgepochdays : map string->number : drop args 2
           : and (= 2 (length args)) : equal? "--datetime" : list-ref args 1
             let : : tm : localtime : current-time
               format #t "~A\n" : apply date->sxg : list (+ 1900 (tm:year tm)) (+ 1 (tm:mon tm)) (tm:mday tm) (tm:hour tm) (tm:min tm) (tm:sec tm)
           : and (= 3 (length args)) : equal? "--decode-datetime" : list-ref args 1
             format #t "~A\n" : sxg->date : list-ref args 2
           : and (= 3 (length args)) : equal? "--decode-sxgepochdays" : list-ref args 1
             format #t "~A\n" : sxgepochdays->yeardays : list-ref args 2
           : and (= 3 (length args)) : equal? "-d" : list-ref args 1
             format #t "~A\n" : sxg->integer : list-ref args 2
           : = 2 : length args
             format #t "~A\n" : integer->sxg : string->number : list-ref args 1
           else
             help
