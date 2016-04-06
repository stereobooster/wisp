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
    only (srfi srfi-1) second

define random-source : make-random-source
random-source-randomize! random-source

define random-integer 
       random-source-make-integers random-source

define : randomletter letters
      string-ref letters
        random-integer
          string-length letters

define : password length
      let
       : quertysafeletters "0123456789ABCDEFGHJKLMNPQRSTUVWXabcdefghijkmnopqrstuvwx"
         ;; that’s newbase60 without yz_
         ;; means 5.78 bits entropy per letter.
         delimiters ",.!?-+"
         ;; that’s 2.5 bits entropy per delimiter
       let fill
         : letters '()
           remaining length
         if : zero? remaining
            reverse-list->string letters
            fill
              cons : randomletter quertysafeletters
                if : and (not (= length remaining)) : zero? : modulo remaining 4
                   cons : randomletter delimiters
                        . letters
                   . letters
              - remaining 1

define : main args
      let
       :
         len
           if : = 2 : length args
              string->number : second args
              . 16
       display : password len
       newline
