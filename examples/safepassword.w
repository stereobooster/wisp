#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples safepassword) main)' -s "$0" "$@"
; !#

;; Create safe passwords, usable on US and German keyboards without problems

define-module : examples safepassword
              . #:export : password

define : main args
       display "password\n"
