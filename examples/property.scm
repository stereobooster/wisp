#!/usr/bin/env sh
(# -*- wisp -*-)
(exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples property) main)' -s "$0" "$@")
; !#

(define-module (examples property)
              #:export (main))

; FIXME: this does not work when called from guile, but it works when
; first translating it to scheme and then calling the scheme file.

; The following works:

; guile ../wisp.scm property.w > property.scm; guile -e '(@@ (examples property) main)' -s property.scm 

(define y 5)
(define-syntax z
  (identifier-syntax (var y)
                    ((set! var val)
                      (set! y (+ 1 val)))))

(define (main args)
         (write args)
         (newline)
         (write z)
         (newline)
         (set! z 5)
         (write z)
         (newline))


