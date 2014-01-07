#!/home/arne/wisp/wisp-multiline.sh -l guile
; !#

;; Testing syntax-rules and syntax-case with wisp

;; Syntax-case: add1 (from guile docs)
define-syntax add1
  lambda : x
    syntax-case x : 
      : _ exp
        syntax : + exp 1

;; use the #' shorthand for syntax
define-syntax add2
  lambda : x
    syntax-case x : 
      : _ exp
        #' + exp 2

;; Syntax-rules add which requires at least 1 argument
define-syntax add-with-argument
 syntax-rules : 
  : _ a b ...
    + a b ...

;; Same with syntax-case
define-syntax add-with-argument
 lambda : x
  syntax-case x : 
   : _ a b ...
     #' + a b ...

; format #t "this breaks\n"
; add-with-argument 
format #t "returns 1: ~A\n" : add-with-argument 1
