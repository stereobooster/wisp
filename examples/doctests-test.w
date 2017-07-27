#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples doctests-test) main)' -s "$0" "$@"
; !#

define-module : examples doctests-test

import : examples doctests

define %this-module : current-module
define : main args
       . " Testing doctests
   (test \"mytest\"
       (test-assert #t)
       (test-assert #f))
"
       doctests-testmod %this-module

