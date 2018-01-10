#!/usr/bin/env sh
(# -*- wisp -*-)
(guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))')
(exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -s "$0" "$@")
; !#

;;; coffee --- pseudo-code for work with coffee, based on flawed java-code on a cup

(import (ice-9 q)
         (ice-9 pretty-print))

(define-syntax-rule (sip x)
  (set! x #f))
(define-syntax-rule (pop x)
  (let ((y (car x)))
    (set! x (cdr x))
    y))

(define* (work schedule)
    (let*
      ((pot (prepare 'coffee))
        (cup (serve pot)))
      (let proceed ((task (pop schedule)))
          (sip cup)
          (execute task)
          (when (not (done? schedule))
              (when (empty? cup)
                  (when (empty? pot)
                      (set! pot (prepare 'coffee)))
                  (set! cup (serve pot)))
              (proceed (pop schedule))))))

(define prepare list)
(define serve car)
(define execute pretty-print)
(define done? null?)
(define (empty? x)
    (equal? #f x))
(define schedule (iota 5))

(work schedule)


