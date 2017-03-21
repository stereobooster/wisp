#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples benchmark) main)' -l $(dirname $(realpath "$0"))/cholesky.w -l $(dirname $(realpath "$0"))/ensemble-estimation.w -s "$0" "$@"
; !#

define-module : examples benchmark

import : statprof
         ice-9 optargs
         ice-9 format
         srfi srfi-1
         srfi srfi-42 ; list-ec
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
  let : (steps 30)
    concatenate
      list 
        let : (param-list (zip (iota steps 1 1000) (iota steps 1 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 0) (iota steps 1 1000)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 1000) (iota steps 1 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 0) (iota steps 1 1000)))
               bench-append param-list
        let : (param-list (zip (iota steps 1 1000) (iota steps 100000 0)))
               bench-append param-list
        let : (param-list (zip (iota steps 100000 0) (iota steps 1 1000)))
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


;; prepare a multi-function fit
import 
    only : examples ensemble-estimation
         . EnSRF make-covariance-matrix-with-offdiagonals-using-stds 
         . standard-deviation-from-deviations x-deviations->y-deviations
         . x^steps
    only : ice-9 popen
         . open-output-pipe close-pipe

define : H x pos
       . "Observation operator. It generates modelled observations from the input.

x are parameters to be optimized, pos is another input which is not optimized. For plain functions it could be the position of the measurement on the x-axis. We currently assume absolute knowledge about the position.
"
       let : (N (first pos)) (m (second pos))
           +
             list-ref x 0 ; constant value
             ;; pure N
             * (list-ref x 1) : log : + 1 N ; avoid breakage at pos 0
             ; * (list-ref x 2) : sqrt N
             * (list-ref x 3) N
             ; * (list-ref x 4) : expt N 2
             ; * (list-ref x 5) : expt N 3
             ;; pure m
             * (list-ref x 6) : log : + 1 m ; avoid breakage at pos 0
             ; * (list-ref x 7) : sqrt m
             * (list-ref x 8) m
             ; * (list-ref x 9) : expt m 2
             ; * (list-ref x 10) : expt m 3
             ;; mixed terms
             * (list-ref x 11) : log : + 1 N m
             * (list-ref x 12) : * N (log (+ 1 m))
             * (list-ref x 13) : * m (log (+ 1 N))
             ; * (list-ref x 14) : * N m
             ; * (list-ref x 15) : * (expt N 2) m
             ; * (list-ref x 16) : * (expt m 2) N


define : interleave lx lz
  cond
    (null? lx) lz
    else
      cons : car lx
             interleave lz : cdr lx


define : print-fit x σ
    let : : msg "
~,1,,,,,'ee±~,1,,,,,'ee + ~,1,,,,,'ee±~,1,,,,,'ee log(N) + ~,1,,,,,'ee±~,1,,,,,'ee sqrt(N) + ~,1,,,,,'ee±~,1,,,,,'ee N + ~,1,,,,,'ee±~,1,,,,,'ee N^2 + ~,1,,,,,'ee±~,1,,,,,'ee N^3 +
~,1,,,,,'ee±~,1,,,,,'ee log(m) + ~,1,,,,,'ee±~,1,,,,,'ee sqrt(m) + ~,1,,,,,'ee±~,1,,,,,'ee m + ~,1,,,,,'ee±~,1,,,,,'ee m^2 + ~,1,,,,,'ee±~,1,,,,,'ee m^3 +
~,1,,,,,'ee±~,1,,,,,'ee log(N + m) + ~,1,,,,,'ee±~,1,,,,,'ee N log(m) + ~,1,,,,,'ee±~,1,,,,,'ee m log(N)+ ~,1,,,,,'ee±~,1,,,,,'ee N m + ~,1,,,,,'ee±~,1,,,,,'ee N^2 m + ~,1,,,,,'ee±~,1,,,,,'ee m^2 N
"
      apply format 
        append (list #t msg) (interleave x σ)


define : flatten li
         append-ec (: i li) i

define : main args
   ;; map 
   ;;     lambda : mismatch-fun
   ;;       write (procedure-name mismatch-fun)
   ;;       newline
   ;;       let : (mis (mismatch-fun (benchmark-list-append)))
   ;;          map : lambda (x) : pretty-print (stddev x)
   ;;                apply zip mis
   ;;     list mismatch-to-const-N-m mismatch-to-linear-N-m
   let*
      : bench : benchmark-list-append ;; benchmark results
        ; fitting to cost estimates
        ensemble-member-count 32
        ensemble-member-plot-skip 4
        x^b : list-ec (: i 17) (car (cdr (car bench))) ; inital guess: constant starting at the first result
        x^b-std : list-ec (: i 17) (car (cdr (car bench))) ; inital guess: 100% uncertainty
        P : make-covariance-matrix-with-offdiagonals-using-stds x^b-std
        y⁰-pos : map car bench
        y⁰ : append-map cdr bench
        y⁰-std : stddev y⁰
        R : make-covariance-matrix-with-offdiagonals-using-stds : list-ec (: i (length bench)) y⁰-std
        optimized : EnSRF H x^b P y⁰ R y⁰-pos ensemble-member-count
        x-opt : list-ref optimized 0
        x-deviations : list-ref optimized 1
        x-std 
              list-ec (: i (length x-opt))
                    apply standard-deviation-from-deviations : list-ec (: j x-deviations) : list-ref j i
        y-deviations : x-deviations->y-deviations H x-opt x-deviations y⁰-pos
        y-stds : list-ec (: i y-deviations) : apply standard-deviation-from-deviations i
        y-opt : map (λ (x) (H x-opt x)) y⁰-pos
        x^b-deviations-approx
            list-ec (: i ensemble-member-count)
                 list-ec (: j (length x^b))
                     * : random:normal
                         sqrt : list-ref (list-ref P j) j ; only for diagonal P!
        y^b-deviations : x-deviations->y-deviations H x^b x^b-deviations-approx y⁰-pos
        y-std
           apply standard-deviation-from-deviations
              flatten y-deviations
        y-stds : list-ec (: i y-deviations) : apply standard-deviation-from-deviations i
        y^b-stds : list-ec (: i y^b-deviations) : apply standard-deviation-from-deviations i

      ;; print-fit x-std
      print-fit x-opt x-std
      ; now plot the result
      let : : port : open-output-pipe "python2"
        format port "import pylab as pl\nimport matplotlib as mpl\n"
        format port "y0 = [float(i) for i in '~A'[1:-1].split(' ')]\n" y⁰
        format port "yerr = ~A\n" y⁰-std
        format port "ypos1 = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : first i
        format port "ypos2 = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : second i
        format port "yinit = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : H x^b i
        format port "yinitstds = [float(i) for i in '~A'[1:-1].split(' ')]\n" y^b-stds
        format port "yopt = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : H x-opt i
        format port "yoptstds = [float(i) for i in '~A'[1:-1].split(' ')]\n" y-stds
        format port "pl.errorbar(*zip(*sorted(zip(ypos1, yinit))), yerr=zip(*sorted(zip(ypos1, yinitstds)))[1], label='prior vs N')\n"
        format port "pl.errorbar(*zip(*sorted(zip(ypos1, yopt))), yerr=zip(*sorted(zip(ypos1, yoptstds)))[1], label='optimized vs N')\n"
        format port "eb=pl.errorbar(*zip(*sorted(zip(ypos1, y0))), yerr=yerr, alpha=0.6, marker='x', mew=2, ms=10, linewidth=0, label='measurements vs N')\neb[-1][0].set_linewidth(1)\n"
        format port "pl.errorbar(*zip(*sorted(zip(ypos2, yinit))), yerr=zip(*sorted(zip(ypos2, yinitstds)))[1], label='prior vs. m')\n"
        format port "pl.errorbar(*zip(*sorted(zip(ypos2, yopt))), yerr=zip(*sorted(zip(ypos2, yoptstds)))[1], label='optimized vs. m')\n"
        format port "eb=pl.errorbar(*zip(*sorted(zip(ypos2, y0))), yerr=yerr, alpha=0.6, marker='x', mew=2, ms=10, linewidth=0, label='measurements vs. m')\neb[-1][0].set_linewidth(1)\n"
        list-ec (: step 0 (length x^steps) 16)
             let : : members : list-ref x^steps (- (length x^steps) step 1)
                list-ec (: member-idx 0 (length members) ensemble-member-plot-skip) ; reversed
                   let : : member : list-ref members member-idx
                     format port "paired = pl.get_cmap('Paired')
cNorm = mpl.colors.Normalize(vmin=~A, vmax=~A)
scalarMap = mpl.cm.ScalarMappable(norm=cNorm, cmap=paired)\n" 0 (length member)
                     list-ec (: param-idx 0 (length member) 16) ; step = 16
                        ; plot parameter 0
                        format port "pl.plot(~A, ~A, marker='.', color=scalarMap.to_rgba(~A), linewidth=0, label='', alpha=0.6, zorder=-1)\n" (/ step 1) (+ 80 (* (/ (apply + y-opt) (length y-opt)) (list-ref member param-idx))) param-idx
        format port "pl.legend(loc='upper right')\n"
        format port "pl.xlabel('position [arbitrary units]')\n"
        format port "pl.ylabel('value [arbitrary units]')\n"
        format port "pl.title('ensemble optimization results')\n"
        format port "pl.xscale('log')\n"
        format port "pl.yscale('log')\n"
        format port "pl.show()\n"
        format port "exit()\n"
        close-pipe port
