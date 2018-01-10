#!/usr/bin/env sh
(# -*- wisp -*-)
(exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples sh) main)' -s "$0" "$@")
; !#

;; simplest way to run shell commands

(define-module (examples sh)
              #:export (sh))

(use-modules (srfi srfi-1))

(define (->string thing)
  (if (symbol? thing)
    (symbol->string thing)
    (format #f "\"~A\"" thing)))

(define (run-me . args)
  (system (string-join (map ->string args))))

(define-syntax-rule (sh args ...)
  (apply run-me (quote (args ...))))

(define (main args)
  (sh echo foo | sed s/o/u/))


