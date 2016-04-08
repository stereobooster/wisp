#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples safepassword) main)' -s "$0" "$@"
; !#

;; Create safe passwords, usable on US and German keyboards without problems

define-module : examples safepassword
              . #:export : password

import
    only (srfi srfi-27) random-source-make-integers
      . make-random-source random-source-randomize!
    only (srfi srfi-1) second third iota
    srfi srfi-42


;; newbase60 without yz_: 57 letters, each 5.78 bits of entropy.
define qwertysafeletters "0123456789ABCDEFGHJKLMNPQRSTUVWXabcdefghijkmnopqrstuvwx"
;; delimiters: 2.32 bits of entropy per delimiter.
define delimiters ",.!?-"

define random-source : make-random-source
random-source-randomize! random-source


define random-integer 
       random-source-make-integers random-source


define : randomletter letters
      string-ref letters
        random-integer
          string-length letters


define : flatten e
    cond 
       : pair? e
         ` 
           ,@ flatten : car e 
           ,@ flatten : cdr e
       : null? e
         list
       else 
         list e


define : password/srfi-42 length
       list->string
         append-ec (: i (iota length 1))
           cons : randomletter qwertysafeletters
             if : and (not (= i length)) : zero? : modulo i 4
                cons : randomletter delimiters
                  list
                list


define : password/map length
       list->string
         flatten
           map
             lambda : i
               let
                 : letter : randomletter qwertysafeletters
                 if : and (not (= i length)) : zero? : modulo i 4
                    list letter 
                      randomletter delimiters
                    list letter
             iota length 1


define : password length
       let fill
         : letters '()
           remaining length
         if : zero? remaining
            reverse-list->string letters
            fill
              cons : randomletter qwertysafeletters
                if : and (not (= length remaining)) : zero? : modulo remaining 4
                   cons : randomletter delimiters
                        . letters
                   . letters
              - remaining 1


define : main args
      let
       :
         len
           if : <= 2 : length args
              string->number : second args
              . 16
       let 
         : idx (if (> 3 (length args)) 1 (string->number (third args)))
         cond
           : = idx 1
             display : password len
           : = idx 2
             display : password/map len
           : = idx 3
             display : password/srfi-42 len
         newline
