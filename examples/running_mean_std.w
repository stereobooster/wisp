#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples running_mean_std)' -c '' "$@"
; !#

define-module : examples running_mean_std
   . #:export : main

use-modules : srfi srfi-11

define : running-stat-fun
     let
       : n 0
         sum 0
         sum² 0
       define : mean-std x
                set! n : + n 1
                set! sum : + sum x
                set! sum² : + sum² : expt x 2
                let*
                  : mean : / sum n
                    σ 
                      - : / sum² n
                        . mean
                  values mean σ
       . mean-std

define statfun : running-stat-fun

define : main args
  write : statfun 5
  newline
  write : statfun 4
  newline
  let-values 
      : (mean σ) : statfun 5
      display mean 
      display '±
      display σ
      newline
  
