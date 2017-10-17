#!/usr/bin/env sh
# -*- scheme -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) -e '(@@ (examples doctests-test) main)' -s "$0" "$@"
; !#

(define-module (examples doctests-test))

(import (examples doctests))

(define (foo)
    #((tests
      ('foo
        (test-equal "bar" (foo)))))
    "bar")

(define %this-module (current-module))
(define (main args)
       " Testing doctests"
       #((tests ('mytest
              (test-assert #t)
              (test-assert #f))))
       (doctests-testmod %this-module))



