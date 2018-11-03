#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples argparse)' -c '' "$@"
; !#

;; Argument parser
;; 
;; Status: draft (basic interface works, but does not do something useful yet)
;; 
;; plan: (TODO)
;;   - simplest usage: (import (examples argparse))(let ((args (args-parse))) (write args))
;;   - with setup: (import (examples argparse))
;;                 (let* ((parser (setup-args #:help "foo"))
;;                        (args (parse-args #:parser parser)))
;;                       (write args))
;;   - implement -h | --help | --usage and -V | --version, set up automatically and improved via setup-args.

define-module : examples argparse
    . #:export : args-parse args-setup main

import : ice-9 optargs

define* : args-parse #:optional args #:key parser
          if : equal? #f args
               command-line
               . args

define* : args-setup #:key (help #f)
        . #f

define : main args
         let : : args : args-parse args
           write args
         let*
            : parser : args-setup #:help "argparse"
              args : args-parse #:parser parser
            write args
         let*
            : parser : args-setup #:help "argparse"
              args : args-parse args #:parser parser
            write args
