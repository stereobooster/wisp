#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples cli)' -c '' "$@"
; !#

define-module : examples cli
              . #:use-module : ice-9 match
              . #:export : main

define : main args
         match args
           : prog ; just the program name, empty call
             display : car args
           else
             display args
         newline

