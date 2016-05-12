#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples with) main)' -s "$0" "$@"
; !#

;; A cleaner way to implement this might be using dynamic-wind.

define-module : examples with

import : oop goops

; import : ice-9 rdelim
; with (open-file "with.w") as port
;      display : read-line port

define : enter thing
       . thing
define-generic enter

define : exit thing
       . thing
define-generic exit

define-syntax with
    syntax-rules : as
      : _ thing as name thunk ...
        let*
           : name : enter thing
             res : begin thunk ...
           exit thing
           . res

define-method : exit (thing <port>)
                close-port thing

define : main args
         with (open-file "with.w" "r") as port
              format #t "~a\n" : read port
