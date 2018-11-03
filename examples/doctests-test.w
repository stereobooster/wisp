#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples doctests-test)' -c '' "$@"
; !#

define-module : examples doctests-test
    . #:export : main

import : examples doctests

define : foo
         ##
            tests 
               'foo-equality-tests
                   test-equal "bar" : foo
                   test-equal "bar" "bar"
                   test-equal 'bar : string->symbol : foo
                   test-equal 'foo 'foo
         . "bar"

define %this-module : current-module
define : main args
       . " Testing doctests"
       . #((tests ('mytest
              (test-assert #t)
              (test-assert #f))))
       doctests-testmod %this-module

