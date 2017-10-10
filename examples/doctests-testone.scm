#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) -s "$0" "$@"
; !#

(import (examples doctests))

(define (foo)
    #((tests 
      ('foo
        (test-equal "bar" (foo)))))
    "bar")

(doctests-testmod (current-module))



