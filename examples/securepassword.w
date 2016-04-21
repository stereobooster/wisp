#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples securepassword) main)' -s "$0" "$@"
; !#

;; Create secure passwords, usable on US and German keyboards without problems

;; As of 2011, a single device can do 2,800,000,000 guesses per second.
;; Today this should be 10 billion guesses per second.
;; According to a recovery company which sells crackers at 1.5k$, as of
;; 2016 a zip-file can be attacked with 100,000 guesses per second.

;; A password with 8 letters and 2 delimiters (length 8, entropy 50)
;; would on average withstand the strong attack for 2.5 days, the weak
;; until 2032 (when it would be cracked in one year), assuming
;; doubling of processing power every two years. Cracking it in one
;; day would be possible in 2049.

;; A password with 12 letters and 3 delimiters (length 12, entropy 75)
;; should withstand the strong attack until 2069 (then it would be
;; cracked in one year), assuming doubling of processing power every
;; two years, the weak until 2099.

;; For every factor of 1000 (i.e. 1024 computers), the time to get a
;; solution is reduced by 20 years.  Using every existing cell phone,
;; the 12 letter key would be cracked by the method with 100,000
;; guesses per second in 2039. Facebook could do that with Javascript.

define-module : examples securepassword
              . #:export : password yearstillcrackable

import
    only (srfi srfi-27) random-source-make-integers
      . make-random-source random-source-randomize!
    only (srfi srfi-1) second third iota
    srfi srfi-42
    ice-9 optargs


define* : yearstillcrackable entropy #:key (guesses/second 100000)
       . "Estimate of the years it will take until the password is crackable"
       let 
        : seconds/day : * 60 60 24
          days/year 365.25
        ` 
             in-one-day
               , * 2
                  / 
                    log : / (expt 2 entropy) (* seconds/day guesses/second)
                    log 2
             in-one-year 
               , * 2
                  / 
                    log : / (expt 2 entropy) (* days/year seconds/day guesses/second)
                    log 2


;; newbase60 without yz_: 55 letters, 5.78 bits of entropy per letter.
define qwertysafeletters "0123456789ABCDEFGHJKLMNPQRSTUVWXabcdefghijkmnopqrstuvwx"
;; delimiters: 2 bits of entropy per delimiter.
define delimiters ",.!-"

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
              . 8
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
