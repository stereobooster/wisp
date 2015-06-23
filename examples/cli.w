#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples cli) main)' -s "$0" "$@"
; !#

define-module : examples cli
              . #:use-module : ice-9 match

define : main args
         match args
           : prog ; just the program name, empty call
             display args
         newline

main '("foo")

