#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) -s "$0" "$@"
; !#

(import (examples doctests))

(define (one)
    "(test 'one
        (test-equal 1 (one)))"
    1)

(doctests-testmod (current-module))
