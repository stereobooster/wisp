#!/usr/bin/env bash
# -*- wisp -*-
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples property)' -c '' "$@"
; !#

define-module : examples property
              . #:export : main

; FIXME: this does not work when parsed as script from guile (with the -s switch), 
;        but it works when calling it as module as shown above.

define y 5
define-syntax z
  identifier-syntax : var y
                    : set! var val
                      set! y : + 1 val

define : main args
         write args
         newline
         write z
         newline
         set! z 5
         write z
         newline
