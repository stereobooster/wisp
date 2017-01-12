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
      : ,(string-join answers "\n  ")
  let
    : answer : list-ref answers (string->number (format #f "~a" (peek-char)))
    drain-input (current-input-port)
    say-name me
    say-words
      :
        ,answer
    

;; TODO: Turn this into a macro
duel
  ' Galtag Nimbleday
  ' Lowlife Pirate
