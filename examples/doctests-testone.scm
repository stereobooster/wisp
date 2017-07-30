#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) -s "$0" "$@"
; !#

(import (examples doctests))

(define (foo)
    "(test 'foo
        (test-equal \"bar\" (foo)))
    "
    "bar")

(doctests-testmod (current-module))



