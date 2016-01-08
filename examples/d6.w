#!/home/arne/wisp/wisp-multiline.sh 
; !#

define-module : examples d6
   . #:export : roll check

use-modules : srfi srfi-1

; basic d6 rules, implemented in guile

define : roll
    . "Roll one ± d6"
    let* 
        : eyes '(-5 -3 -1 2 4 6)
          d6 : lambda () : list-ref eyes : random 6 : random-state-from-platform
        let rolling : : rolled : cons (d6) '()
            cond
              : = 1 (length rolled)
                if : not : member (first rolled) '(-5, 6)
                     first rolled
                     rolling : cons (d6) rolled
              : not : equal? (first rolled) (second rolled)
                apply + : cdr rolled
              else
                rolling : cons (d6) rolled
                
                
          
define : check skill target effect-threshold
    . "Check whether a given skill-roll succeeds and provide a margin of success."
    let : : result : + skill : roll
        if : > result target
            floor/ {result - target} effect-threshold
            . #f

display : check 12 9 3
newline
display : roll
newline

