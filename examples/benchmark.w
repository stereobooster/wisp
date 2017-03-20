#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples benchmark) main)' -s "$0" "$@"
; !#

define-module : examples benchmark

import : statprof
         ice-9 optargs
         srfi srfi-1
         ice-9 pretty-print
         system vm program

define : benchmark-run fun
  let profiler : : loop-num 100
    statprof-start
    with-output-to-string
      lambda ()
        let lp : (i loop-num)
          fun
          when (> i 0)
            lp (- i 1)
    statprof-stop
    if : > (statprof-sample-count) 10
        / (statprof-accumulated-time) (statprof-sample-count)
        profiler (* 10 loop-num)

define loopcost
  benchmark-run (λ() #f)

;; TODO: Simplify #:key setup -> . setup
define* : benchmark-fun fun #:key setup
  when setup
    setup
  - : benchmark-run fun
    . loopcost

define-syntax benchmark
  ;; one single benchmark
  lambda : x
    syntax-case x (:let :setup)
      : _ thunk :setup setup-thunk :let let-thunk args ...
        #' benchmark thunk :let let-thunk :setup setup-thunk args ... 
      : _ thunk :let let-thunk :setup setup-thunk args ...
        #' benchmark thunk :let let-thunk #:setup (lambda () setup-thunk) args ... 
      : _ thunk :setup setup-thunk args ...
        #' benchmark thunk #:setup (lambda () setup-thunk) args ... 
      : _ thunk :let let-thunk args ...
        #' let let-thunk
           benchmark thunk args ... 
      : _ thunk args ...
        #' benchmark-fun
         . (lambda () thunk) args ...

;; TODO: Use fit to different mappings.
define : mismatch-to-const-N-m timing-list
  define : N-m x
    define : const y
             car : cdr x
    map const : car x
  map N-m timing-list

define : mismatch-to-linear-N-m timing-list
  define : N-m x 
    define : linear y
       / (car (cdr x)) y
     map linear : car x
  map N-m timing-list

define : benchmark-list-append
  . "Test (append a b) with lists of different lengths."
  define : bench-append param-list
    zip param-list 
        map 
         lambda (x)
           let : (N (list-ref x 0)) (m (list-ref x 1))
               benchmark (append a b) :let ((a (iota N))(b (iota m)))
         . param-list
  let : (steps 4)
    concatenate
      list 
        let : (param-list (zip (iota steps 1 1000) (iota steps 1 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 0) (iota steps 1 100)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 1000) (iota steps 1 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 0) (iota steps 1 100)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 1000) (iota steps 100000 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 100000 0) (iota steps 1 100)))
               bench-append param-list

;; stddev from rosetta code: http://rosettacode.org/wiki/Standard_deviation#Scheme
define : stddev nums
    sqrt 
        - 
            / : apply + : map (lambda (i) (* i i)) nums
                length nums 
            expt (/ (apply + nums) (length nums)) 2

define : running-stddev nums
  define : running-stddev-2 num
      set! nums : cons num nums
      stddev nums
  . running-stddev-2

define : main args
   map 
       lambda : mismatch-fun
         write (procedure-name mismatch-fun)
         newline
         let : (mis (mismatch-fun (benchmark-list-append)))
            map : lambda (x) : pretty-print (stddev x)
                  apply zip mis
       list mismatch-to-const-N-m mismatch-to-linear-N-m
