#!/usr/bin/env sh
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples newbase60) main)' -s "$0" "$@"
; !#

define-module : examples newbase60
              . #:export : main

define : main args
         display args
