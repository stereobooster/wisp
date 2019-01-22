#!/usr/bin/env bash
# -*- wisp -*-
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples sh)' -c '' "$@"
; !#

;; simplest way to run shell commands

define-module : examples sh
              . #:export : sh main

use-modules : srfi srfi-1

define : ->string thing
  if : symbol? thing
    symbol->string thing
    format #f "\"~A\"" thing

define : run-me . args
  system : string-join : map ->string args

define-syntax-rule : sh args ...
  apply run-me : quote : args ...

define : main args
  sh echo foo | sed s/o/u/
