#!/usr/bin/env sh
(# -*- wisp -*-)
(D="$(dirname $(realpath "$0"))"
W="$(dirname $(dirname $(realpath "$0")))"
guile -L "$W" -c '(import (wisp-scheme) (language wisp spec))')
(exec guile -L "$W" --language=wisp -l "$D/enter-three-witches.w" -s "$0" "$@")
; !#

(import (examples enter-three-witches))

(Enter (Dr. Arne Bab.))

(Dr. Arne Bab.
  (Hallo Liebste,)
  (,(color 'red) Ich ,(color 'yellow) liebe ,(color 'red) Dich ,(color #f))
  (Dein Arne))


