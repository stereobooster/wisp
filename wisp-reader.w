#!/home/arne/wisp/wisp-multiline.sh 
; !#
;;
;; Implement wisp in guile
;;
;; -Author: Arne Babenhauserheide

; adapted from guile-sweet: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/common.scm


; adapted from spec.scm: https://gitorious.org/nacre/guile-sweet/source/ae306867e371cb4b56e00bb60a50d9a0b8353109:sweet/spec.scm
define-module : language wisp spec
;   . #:use-module : wisp
  . #:use-module : wisp-scheme
  . #:use-module : system base compile
  . #:use-module : system base language
  . #:use-module : language scheme compile-tree-il
  . #:use-module : language scheme decompile-tree-il
  . #:export : wisp

; Set locale to something which supports unicode. Required to avoid using fluids.
catch #t
      lambda :
        setlocale LC_ALL ""
      lambda : key . parameters
        let : : locale-fallback "en_US.UTF-8"
          format (current-error-port)
              string-join
                  list "Warning: setlocale LC_ALL \"\" failed with ~A: ~A"
                     . "using explicit ~A locale. Please setup your locale.\n"
                  .  "\n         "
              . key parameters locale-fallback
          setlocale LC_ALL locale-fallback

;;;
;;; Language definition
;;;

define wisp-pending-sexps : list

define : read-one-wisp-sexp port env
         cond
            : eof-object? : peek-char port
              read-char port ; return eof: we’re done
            else
              let : : chunk : wisp-scheme-read-chunk port
                cond
                  : not : null? chunk
                    car chunk
                  else
                    . #f

define-language wisp
  . #:title "Wisp Scheme Syntax. See SRFI-119 for details. THIS IS EXPERIMENTAL, USE AT YOUR OWN RISK"
  ; . #:reader read-one-wisp-sexp
  . #:reader : lambda (port env) : let ((x (read-one-wisp-sexp port env))) x
  . #:compilers `((tree-il . ,compile-tree-il))
  . #:decompilers `((tree-il . ,decompile-tree-il))
  . #:evaluator : lambda (x module) : primitive-eval x
  . #:printer write ; TODO: backtransform to wisp? Use source-properties?
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

