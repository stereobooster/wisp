#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples with) main)' -s "$0" "$@"
; !#

;; A cleaner way to implement this might be using dynamic-wind.

;; FIXME: This might not be continuation-safe and might break if the
;; code in the with block uses dynamic-wind. Check whether it’s safe
;; and fix it if not.

define-module : examples with

import : oop goops

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
              . "Ensure that a port is always closed at the end of the with-block."
                close-port thing

define : main args
         with (open-file "with.w" "r") as port
              format #t "~a\n" : read port
