#!/home/arne/wisp/wisp-multiline.sh 
; !#

; basic d6 rules, implemented in guile

define : roll
    . "Roll one ± d6"
    let : : die '(-5 -3 -1 2 4 6)
        list-ref die : random 6 : random-state-from-platform

define : check skill target effect-threshold
    . "Check whether a given skill-roll succeeds and provide a margin of success."
    let : : result : + skill : roll
        if : > result target
            if : < effect-threshold : - result target
                . 1
                . #t
            . #f

display : check 12 9 3
newline
display : roll
