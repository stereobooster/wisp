#!/usr/bin/env sh
# -*- wisp -*-
D="$(dirname $(realpath "$0"))"
W="$(dirname $(dirname $(realpath "$0")))"
guile -L "$W" -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L "$W" --language=wisp -l "$D/enter-three-witches.w" -s "$0" "$@"
; !#

import : examples enter-three-witches

Enter : Galtag Nimbleday
        Lowlife Pirate
        choose your answer

define answers
  `
    : You fight like a Dairy Farmer!
      How appropriate! You fight like a cow!
      And I've got a little TIP for you, get the POINT?

; write answers
; newline

define answers
  ' 
    . "How appropriate! You fight like a cow!"
    . "And I've got a little TIP for you, get the POINT?"

;; TODO: use macro define-interaction
define : duel me other
  say-name other 
  say-words 
    : 
      You fight like a Dairy Farmer!
  say-name ' : choose your answer
  say-words
       : ,(let ((counter 0))
           (string-join 
             (map (λ (x) 
                     (set! counter (+ 1 counter))
                     (string-append (number->string counter) "  " x)) answers) "\n  "))
  let
    : answer : list-ref answers (- (string->number (format #f "~a" (peek-char))) 1)
    drain-input (current-input-port)
    say-name me
    say-words
      :
        ,answer
    

define-syntax-rule : Duel fighter1 fighter2
   duel
     quote fighter1
     quote fighter2


Duel
  Galtag Nimbleday
  Lowlife Pirate

