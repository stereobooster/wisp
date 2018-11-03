#!/usr/bin/env sh
# -*- wisp -*-
D="$(dirname $(realpath "$0"))"
W="$(dirname $(dirname $(realpath "$0")))"
guile -L "$W" -c '(import (wisp-scheme) (language wisp spec))'
exec -a "$0" guile -L "$W" --language=wisp -x .w -e '(examples ild)' -c '' "$@"
; !#

define-module : examples ild
    . #:export : main

import : examples enter-three-witches

define : main args
  Enter : Dr. Arne Bab.
  
  Dr. Arne Bab.
    Hallo Liebste,
    ,(color 'red) Ich ,(color 'yellow) liebe ,(color 'red) Dich ,(color #f)
    Dein Arne
