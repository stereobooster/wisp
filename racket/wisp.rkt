#lang racket

;; Implement wisp in Racket
;;
;; -Author: Arne Babenhauserheide

; adapted from wisp-in-guile and algol60.rkt

(require (for-syntax "parse-base.rkt"))

(provide literal-wisp)


(define-syntax (literal-wisp stx)
  (syntax-case stx ()
    [(_ strs ...)
     (andmap (λ (x) (string? (syntax-e x))) 
             (syntax->list (syntax (strs ...))))
     
       (parse-wisp-port
        (open-input-string 
         (apply 
          string-append
          (map syntax-e (syntax->list #'(strs ...)))))
        (syntax-source stx))]))