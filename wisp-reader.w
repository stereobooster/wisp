#!/home/arne/wisp/wisp-multiline.sh 
; !#
;;
;; Implement wisp in guile
;;
;; -Author: Arne Babenhauserheide

; adapted from guile-sweet: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/common.scm


; adapted from spec.scm: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/spec.scm
define-module : language wisp spec
  . #:use-module : wisp
  . #:use-module : system base compile
  . #:use-module : system base language
  . #:export : wisp

;;;
;;; Language definition
;;;

define : compile-scheme x e opts
       values x e e

define : decompile-scheme x e opts
       values x e

define wisp-pending-port : make-object-property

; Code thanks to Mark Weaver
define : read-one-wisp-sexp port env
  define : read-wisp-chunk
    if : eof-object? : peek-char port
      read-char port ; return eof: we’re done
      let
           : dpe : fluid-ref %default-port-encoding
             set-pending-port!
               lambda ()
                   let
                     : s : wisp2lisp : wisp-chunkreader port
                     set! : wisp-pending-port port
                        open-input-string s
           if dpe ; default port encoding is set
             set-pending-port!
             ; else: we need to redefine %default-port-encoding to
             ; UTF-8. Use with-fluids to avoid affecting other code.
             with-fluids : : %default-port-encoding "UTF-8"
               set-pending-port!
           try-pending
  define : try-pending
    let : : pending-port : wisp-pending-port port
      if pending-port
          let : : x : read pending-port
             if : eof-object? x
                read-wisp-chunk
                . x
          read-wisp-chunk
  try-pending

define-language wisp
  . #:title "Wisp Scheme Syntax THIS IS EXPERIMENTAL, USE AT YOUR OWN RISK"
  . #:reader read-one-wisp-sexp
  . #:compilers `((scheme . ,compile-scheme)) ; I do not touch quasiquotes yet.
  . #:decompilers `((scheme . ,decompile-scheme))
  . #:evaluator : lambda (x module) : primitive-eval x
  . #:printer write
  . #:make-default-environment
  lambda :
    ;; Ideally we'd duplicate the whole module hierarchy so that `set!',
    ;; `fluid-set!', etc. don't have any effect in the current environment.
    let : : m : make-fresh-user-module
      ;; Provide a separate `current-reader' fluid so that
      ;; compile-time changes to `current-reader' are
      ;; limited to the current compilation unit.
      module-define! m 'current-reader : make-fluid
      ;; Default to `simple-format', as is the case until
      ;; (ice-9 format) is loaded. This allows
      ;; compile-time warnings to be emitted when using
      ;; unsupported options.
      module-set! m 'format simple-format
      . m

