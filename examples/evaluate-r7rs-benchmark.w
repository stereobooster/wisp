#!/bin/sh
# -*- wisp -*-
exec guile -L ~/wisp --language=wisp -s $0 "$@"
!#

;; Evaluate the benchmarks from ecraven at http://ecraven.github.io/r7rs-benchmarks/benchmark.html
;; Uses data from http://ecraven.github.io/r7rs-benchmarks/all.csv

import : ice-9 rdelim
         srfi srfi-1
         ice-9 pretty-print
         ice-9 optargs
         ice-9 i18n

define : read-csv port
    let loop : : lines '()
        if : eof-object? : peek-char port 
           reverse : map (λ (x) (string-split x #\,)) lines
           loop : cons (read-line port) lines

define : min-alist-by-test data-by-project
    let lp 
        : min-data '()
          data-by-project data-by-project
        if : null? data-by-project
           . min-data
           let*
             : proj : car : car data-by-project
               test : car : cdr : car data-by-project
               time : string->number : car : cdr : cdr : car data-by-project
               best : assoc-ref min-data test
             lp
                if : and time : or (not best) : < time best
                   assoc-set! min-data test time
                   . min-data
                cdr data-by-project

define : select-project-data data-by-project project
       define : notproj? datapoint
              not : string-prefix? project : car datapoint
       define : only-project data
              remove notproj? data
       map cdr : only-project data-by-project

define : get-multiples guile-data data-min-by-test
  let lp 
      : gd guile-data
        multiples-of-best '()
      if : null? gd
         remove (λ(x) (equal? #f x)) multiples-of-best
         let*
             : guile : string->number : car : cdr : car gd
               test : car : car gd
               multiple
                 if : not guile
                    . guile
                    / guile
                      or (assoc-ref data-min-by-test test) guile
             lp : cdr gd
                  if multiple
                     cons multiple multiples-of-best
                     . multiples-of-best


define : help args
    format #t "Usage: ~a csv-file [project-prefix]\n" (car args)

define args : program-arguments

when : null? : cdr args
     help args
     exit 1

define csv-file
    car : cdr args

define project-prefix
    if : null? : cdr : cdr args
       . "guile"
       car : cdr : cdr args

let*
  : port : open-input-file csv-file
    data-by-project : read-csv port
    data-min-by-test : min-alist-by-test data-by-project
    guile-data : select-project-data data-by-project project-prefix
  display "=== Best times ==="
  newline
  pretty-print : sort data-min-by-test (λ (x y) (string<? (car x) (car y)))
  newline
  format #t "=== ~a times ===\n" : string-locale-titlecase project-prefix
  newline
  pretty-print : sort guile-data (λ (x y) (string<? (car x) (car y)))
  newline
  format #t "=== ~a slowdown ===\n" : string-locale-titlecase project-prefix
  newline
  pretty-print : get-multiples guile-data data-min-by-test
  newline
  format #t "=== ~a Geometric Mean slowdown ===\n" : string-locale-titlecase project-prefix
  newline
  pretty-print
     if : null? : get-multiples guile-data data-min-by-test
        . #f
        expt
           apply * : get-multiples guile-data data-min-by-test
           / 1 : length : get-multiples guile-data data-min-by-test
  newline
