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

define : enter thing state
       . thing
define-generic enter

define : exit thing state
       . thing
define-generic exit

define-syntax with
    syntax-rules : as
      : _ thing as name thunk ...
        let
          : name #f
            state #f
            res #f
          dynamic-wind
              λ () : set! name : enter thing state
              λ () : set! res : begin thunk ...
                   . res
              λ () ; : exit thing state
                   . res

define-method : enter (thing <port>) state
              . "Ensure that a port is always closed at the end of the with-block."
              when : not : equal? #f state
                  set-port-column! thing (car state)
                  set-port-line! thing (car (cdr state))
              . thing

define-method : exit (thing <port>) state
              . "Ensure that a port is always closed at the end of the with-block."
              set! state : list (port-line thing) (port-column thing)
              close-port thing

define : main args
         with (open-file "with.w" "r") as port
              format #t "~a\n" : read port
              format #t "~a\n" : read port
              format #t "~a\n" : read port

         ;; TODO: test-continuation
