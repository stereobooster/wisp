#!/home/arne/wisp/wisp-multiline.sh 
; !#

; A small experiment on a complete evolutionary algorithm.

; NOTE: This only works after preprocessing to scheme.

; run via 
; PATH=../guile-2.0.11/meta:$PATH GUILE_LOAD_PATH=. ./wisp-multiline.sh examples/evolve.w 

; Get the eval string which allows for selecting the language.
use-modules : ice-9 eval-string

define evalsyntax "0123456789+-*/: ()"

define : mutate-replace evalstring
       let 
           : eval-index : random : string-length evalstring
             replace-index : random : string-length evalsyntax
           string-replace evalstring evalsyntax eval-index : + eval-index 1
                                          . replace-index : + replace-index 1


define : mutate-permutate evalstring
       let 
           : replace : random : string-length evalstring
             by : random : string-length evalstring
           string-replace evalstring evalstring replace : + replace 1
                                          . by : + by 1


define : mutate-insert evalstring
       let 
           : eval-index : random : string-length evalstring
             insert-index : random : string-length evalsyntax
           string-append 
               substring evalstring 0 eval-index
               string : string-ref evalsyntax insert-index
               substring evalstring eval-index


define : mutate-remove evalstring
       if : <= 1 : string-length evalstring
          ; cannot remove from a 0 string
          . evalstring
          let 
               : eval-index : random : - (string-length evalstring) 1
               string-append 
                   substring evalstring 0 eval-index
                   substring evalstring : + eval-index 1


define : mutate-eval evalstring
       eval-string : string-append "(" evalstring ")"
                   . #:lang 'scheme ; TODO: use wisp


define : better mutated original
       < 
         abs : - 42 : mutate-eval mutated
         abs : - 42 : mutate-eval original


define : evolve-step evalstring mutate
       ; first try a random replacement, then try a permutation.
       let : : newstring : mutate evalstring
           catch #t
               lambda :
                        mutate-eval newstring
               lambda : key . args
                        set! newstring evalstring
           if : better newstring evalstring
              . newstring
              . evalstring


define : evolve-replace evalstring
       evolve-step evalstring mutate-replace

define : evolve-permutate evalstring
       evolve-step evalstring mutate-permutate

define : evolve-insert evalstring
       evolve-step evalstring mutate-insert

define : evolve-remove evalstring
       evolve-step evalstring mutate-remove


define : evolution initialstring steps
       ; TODO: use a population with survivors.
       let loop : (step 0) (string initialstring)
           let : : action : random 4
               if : >= step steps
                  . string
                  cond 
                    : = action 0
                      loop (+ step 1) (evolve-replace string)
                    : = action 1
                      loop (+ step 1) (evolve-permutate string)
                    : = action 2
                      loop (+ step 1) (evolve-insert string)
                    : = action 3
                      loop (+ step 1) (evolve-remove string)
                    
define : run 
       ; firstoff, seed the random number generator!
       set! *random-state* : random-state-from-platform
       let 
         : opt : evolution "+ 123 (- 2 1)" 1000
         write opt
         newline
         write : mutate-eval opt
         newline


run
