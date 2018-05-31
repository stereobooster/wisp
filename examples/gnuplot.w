#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec) (language wisp))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples gnuplot)' -s "$0" "$@"
; !#

define-module : examples gnuplot
    . #:export : main plot-numbers

import : ice-9 optargs
         ice-9 rdelim
         ice-9 popen

define* : plot-numbers numbers #:key (output "/tmp/plot.png") (set-options '((term png))) (plot-options '()) (title #f)
    . "set options and plot options are converted via symbol->string and joined via string-join to pass them to gnuplot"
    let : : tmp : mkstemp! (string-append (tmpnam) "XXXXXX") "w+"
      map : λ (number) (display (exact->inexact number) tmp) (newline tmp)
          . numbers
      force-output tmp
      let : : port : open-output-pipe "gnuplot"
          map : λ(x) (format port "set ~a\n" (string-join (map symbol->string x)))
            . set-options
          when output
              format port "set output \"~a\"\n" output
          format port "plot \"~a\" ~a ~a\n" 
              port-filename tmp
              if title
                  format #f "title \"~a\"" title
                  . ""
              string-join (map symbol->string plot-options)
    display output
    newline

define : main args
    plot-numbers '(1 2 3 5.76) #:title "testdata" #:plot-options '(with lines)
