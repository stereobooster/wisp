#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples argparse) main)' -s "$0" "$@"
; !#

define-module : examples argparse
    . #:export : parse-args setup

import : ice-9 optargs

define* : parse-args #:key (parser #f)
        . #f

define* : setup #:key (help #f)
        . #f

define : main args
       . #f
