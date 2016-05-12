#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples with) main)' -s "$0" "$@"
; !#

define-module : examples with

; import : ice-9 rdelim
; with (open-file "with.w") as port
;      display : read-line port

define* : enter thing
        . thing

define* : exit thing
        . thing

define-syntax with
    syntax-rules : as
      : _ thing as name thunk ...
        let*
           : name : enter thing
             res : begin thunk ...
           exit thing
           . res

define : main args
         with (open-file "with.w" "r") as port
              format #t "~a\n" : read port
