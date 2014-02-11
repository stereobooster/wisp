#!/home/arne/wisp/wisp-multiline.sh 
; !#

;; Fibonacci Functions

define : fibonacci n
    . "Get Fibonacci Element N in Linear Time"
    let rek : (i 0) (u 1) (v 1)
        if : >= i : - n 2
            . v
            rek (+ i 1) v (+ u v) ; else

; display : fib 5

;; Try it with curly infix

;; First activate curly infix
. #!curly-infix 

;; Now define fibonacci with curly infix.
define : fibonacci n
    . "Get Fibonacci Element N in Linear Time"
    let rek : (i 0) (u 1) (v 1)
        if {i >= {n - 2}}
            . v
            rek {i + 1} v {u + v}

display 
  . {1 + 1}
newline

;; Due to the compatibility with curly-infix, the following is no longer possible.

;; Try an infix notation with curly brackets - curly infix from readable as simple macro
;; define-syntax {
;;     syntax-rules : { }
;;         : { left infix right } 
;;           infix left right
;; 
;; ; display : { 1 + 2 }
;; 
;; ;; Now do the fibonacci again
;; define : fibcurl n
;;     . "Get Fibonacci Elements in Linear Time"
;;     let rek : (i 0) (u 1) (v 1)
;;         if : { i >= ({ n - 2 }) }
;;             . v
;;             rek ({ i + 1 }) v ({ u + v }) ; else
;; 
;; ; display : fibcurl 5
;; 
;; ;; Do a more complete syntax-rule
;; 
;; ;; Try an infix notation with curly brackets - curly infix from readable as simple macro
;; define-syntax {
;;     syntax-rules : { }
;;         : { l in r } 
;;           in l r
;;         : { { ll lin lr } in r } 
;;           in (lin ll lr) r
;;         : { l in { rl rin rr } } 
;;           in l (rin rl rr)
;;         : { { ll lin lr } in { rl rin rr } } 
;;           in (lin ll lr) (rin rl rr)
;; 
;; ;; And a complete infix-fibonacci
;; define : fibcurl2 n
;;     . "Get Fibonacci Elements in Linear Time"
;;     let rek : (i 0) (u 1) (v 1)
;;         if : { i >= { n - 2 } }
;;             . v
;;             rek 
;;                { i + 1 } 
;;                . v 
;;                { u + v }
;; 
;; ;; But to be frank: Prefix looks better.
;; 
;; display : { { 1 + 2 } * { 2 * 3 } }
;; ; display : fibcurl2 5
;; ; TODO: Make the macro recursive, so it can actually cover arbitrary depths of curly braces.
