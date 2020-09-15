#!/usr/bin/env bash
# -*- wisp -*-
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
echo ${GUILE}
"${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" "${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples threaded-writing)' -c '' "$@"
; !#

define-module : examples threaded-writing
   . #:export : main

import : ice-9 threads

define : help args
    format #t "~a [--help] [--test]\n" (car args)

define : write-threaded args
            define status-output-mutex : make-mutex

            define : status-message msg i
              lock-mutex status-output-mutex
              format #t "~d ~a\n" i msg
              unlock-mutex status-output-mutex

            par-map status-message args : iota : length args


define : main args
    cond
        : and {(length args) > 1} : equal? "--help" : car : cdr args
          help args
        else
          write-threaded args
