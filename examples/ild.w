#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -l $(dirname $(realpath "$0"))/enter-three-witches.w -s "$0" "$@"
; !#

import : examples enter-three-witches

Enter : Dr. Arne Bab.

Dr. Arne Bab.
  Hallo Liebste,
  ,(color 'red) Ich ,(color 'yellow) liebe ,(color 'red) Dich ,(color #f)
  Dein Arne
