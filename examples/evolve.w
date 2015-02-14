#!/home/arne/wisp/wisp-multiline.sh 
; !#

; One thousand monkeys: A small experiment on a complete evolutionary algorithm.

; TODO: genetic with mutate+combinate, population which keeps the best and directed whch only keeps improvements

; NOTE: This only works after preprocessing to scheme.

; run via 
; PATH=../guile-2.0.11/meta:$PATH GUILE_LOAD_PATH=. ./wisp-multiline.sh examples/evolve.w 

; Get the eval string which allows for selecting the language.
use-modules : ice-9 eval-string

define evalsyntax "0123456789+-*/: ()"


define : paired-char? char
       or (equal? #\) char) (equal? #\( char)


define : mutate-replace evalstring
       let*
           : eval-index : random : string-length evalstring
             replace-index : random : string-length evalsyntax
             remove-char : string-ref evalstring eval-index
             insert-char : string-ref evalsyntax replace-index
             ; double step, if mutating a paired character
             evalstring 
                 if : not : or (paired-char? insert-char) (paired-char? remove-char)
                    . evalstring 
                    mutate-replace evalstring
           string-replace evalstring evalsyntax eval-index : + eval-index 1
                                          . replace-index : + replace-index 1


define : mutate-permutate evalstring
       let 
           : replace : random : string-length evalstring
             by : random : string-length evalstring
           string-replace evalstring evalstring replace : + replace 1
                                          . by : + by 1


define : mutate-insert evalstring
       let* 
           : eval-index : random : string-length evalstring
             insert-index : random : string-length evalsyntax
             insert-char : string-ref evalsyntax insert-index
             ; double step, if mutating a paired character
             evalstring 
                 if : not : paired-char? insert-char
                    . evalstring 
                    mutate-insert evalstring
           string-append 
               substring evalstring 0 eval-index
               string insert-char
               substring evalstring eval-index


define : mutate-remove-by-index evalstring index
               string-append 
                   substring evalstring 0 index
                   substring evalstring : + index 1
       

define : mutate-remove evalstring
       if : <= 1 : string-length evalstring
          ; cannot remove from a 0 string
          . evalstring
          let* 
               : eval-index : random : - (string-length evalstring) 1
                 eval-char : string-ref evalstring eval-index
                 ; double step, if mutating a paired character
                 evalstring 
                     if : not : paired-char? eval-char
                        . evalstring 
                        mutate-remove evalstring
               mutate-remove-by-index evalstring eval-index

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


define : evolution-step string 
       let : : action : random 4
           cond 
             : = action 0
               evolve-replace string
             : = action 1
               evolve-permutate string
             : = action 2
               evolve-insert string
             : = action 3
               evolve-remove string


define : evolution-population initialstring steps population-size
       . "a population with 50% survivors."
       . initialstring

define : evolution initialstring steps
       ; TODO: use 
       let loop : (step 0) (string initialstring)
           if : >= step steps
              . string
              loop 
                  1+ step
                  evolution-step string

                    
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
