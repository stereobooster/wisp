#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples argparse) main)' -s "$0" "$@"
; !#

;; Argument parser
;; plan: 
;;   - simplest usage: (import (examples argparse))(let ((args (parse-args))) (write args))
;;   - with setup: (import (examples argparse))
;;                 (let* ((parser (setup-args #:help "foo"))
;;                        (args (parse-args #:parser parser)))
;;                       (write args))

define-module : examples argparse
    . #:export : args-parse args-setup

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
