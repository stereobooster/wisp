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

define* : benchmark-run fun #:key (min-seconds 0.1)
  let profiler : (loop-num 10)
    let : : t : get-internal-real-time
      with-output-to-string
        lambda ()
          let lp : (i loop-num)
            : λ () : fun
            when (> i 0)
              lp (- i 1)
      let*
        : dt : - (get-internal-real-time) t
          seconds : / (exact->inexact dt) internal-time-units-per-second
        pretty-print : list dt seconds loop-num
        if : > seconds min-seconds
            / seconds loop-num ;; this wastes less than {(10 * ((10^(i-1)) - 1)) / 10^i} fractional data but gains big in simplicity
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

define : logiota steps start stepsize
    . "Create numbers evenly spread in log space"
    let*
        : logstart : log (+ start 1)
          logstep : / (- (log (+ start (* stepsize (- steps 1)))) logstart) (- steps 1)
        map inexact->exact : map round : map exp : iota steps logstart logstep 

define : benchmark-list-append
  . "Test (append a b) with lists of different lengths."
  define : bench-append param-list
    zip param-list 
        map 
         lambda (x)
           let : (N (list-ref x 0)) (m (list-ref x 1))
               benchmark (append a b) :let ((a (iota N))(b (iota m)))
         . param-list
  let : (steps 100)
    concatenate
      list 
        let : (param-list (zip (logiota steps 1 10000) (logiota steps 1 0)))
               bench-append param-list
        ;; let : (param-list (zip (logiota steps 20 0) (logiota steps 1 10000)))
        ;;        bench-append param-list
        ;; let : (param-list (zip (logiota steps 1 1000) (logiota steps 1 0)))
        ;;        bench-append param-list
        ;; let : (param-list (zip (logiota steps 1 0) (logiota steps 1 1000)))
        ;;        bench-append param-list
        ;; let : (param-list (zip (logiota steps 1 1000) (logiota steps 100000 0)))
        ;;        bench-append param-list
        ;; let : (param-list (zip (logiota steps 100000 0) (logiota steps 1 1000)))
        ;;        bench-append param-list


;; prepare a multi-function fit
import 
    only : examples ensemble-estimation
         . EnSRF make-covariance-matrix-with-offdiagonals-using-stds 
         . standard-deviation-from-deviations x-deviations->y-deviations
         . x^steps
    only : ice-9 popen
         . open-output-pipe close-pipe

define-syntax-rule : or0 test c ...
    if test : begin c ...
            . 0

define-syntax-rule : define-quoted sym val
    ;; set the value to true using eval to break the symbol->variable barrier
    primitive-eval `(define ,sym val)

define* 
       H-N-m x pos #:key all const OlogN OsqrtN ON ONlogN ON²
                                 . Ologm Osqrtm Om Omlogm Om²
                                 . OlogNm ONlogm OmlogN ONm
                                 . ON²m Om²N OsinN/N Osinm/m
       . "Observation operator. It generates modelled observations from the input.

x are parameters to be optimized, pos is another input which is not optimized. For plain functions it could be the position of the measurement on the x-axis. We currently assume absolute knowledge about the position.
"
       when all
           let lp : (l '(const OlogN OsqrtN ON ONlogN ON² Ologm Osqrtm Om Omlogm Om² OlogNm ONlogm OmlogN ONm ON²m Om²N OsinN/N Osinm/m))
               when : not : null? l
                      define-quoted (car l) #t
                      lp : cdr l
       
       let : (N (first pos)) (m (second pos))
           +
             or0 const : list-ref x 0 ; constant value
             ;; pure N
             or0 OlogN  : * (list-ref x 1) : log (+ 1 N) ; avoid breakage at pos 0
             or0 OsqrtN : * (list-ref x 2) : sqrt N
             or0 ON     : * (list-ref x 3) N
             or0 ONlogN : * (list-ref x 4) : * N : log (+ 1 N)
             or0 ON²    : * (list-ref x 5) : expt N 2
             ;; pure m
             or0 Ologm  : * (list-ref x 6) : log (+ 1 m) ; avoid breakage at pos 0
             or0 Osqrtm : * (list-ref x 7) : sqrt m
             or0 Om     : * (list-ref x 8) m
             or0 Omlogm : * (list-ref x 9) : * m : log (+ 1 m)
             or0 Om²    : * (list-ref x 10) : expt m 2
             ;; mixed terms
             or0 OlogNm : * (list-ref x 11) : log (+ 1 N m)
             or0 ONlogm : * (list-ref x 12) : * N : log (+ 1 m)
             or0 OmlogN : * (list-ref x 13) : * m : log (+ 1 N)
             or0 ONm    : * (list-ref x 14) : * N m
             or0 ON²m   : * (list-ref x 15) : * (expt N 2) m
             or0 Om²N   : * (list-ref x 16) : * (expt m 2) N
             or0 OsinN/N : * (list-ref x 17) : / (sin (/ (- N (list-ref x 18)) (list-ref x 19))) N ; sin(x)/x
             or0 Osinm/m : * (list-ref x 20) : / (sin (/ (- m (list-ref x 21)) (list-ref x 22))) m ; sin(x)/x


define : interleave lx lz
  cond
    (null? lx) lz
    else
      cons : car lx
             interleave lz : cdr lx


define : print-fit x σ
    . "Print the big-O parameters which are larger than σ (their standard deviation)."
    let : : number-format "~,1,,,,,'ee±~,1,,,,,'ee"
      let big-O
        : names : list "" "log(N)" "sqrt(N)" "N log(N)" "N^2" "log(m)" "sqrt(m)" "m" "m log(m)" "m^2" "log(N + m)" "N log(m)" "m log(N)" "N m" "N^2 m" "m^2 N" "sin((N-x)/p)/N" "sin((N-x*)/p)/N" "sin((N-x)/p*)/N" "sin((m-x)/p)/m" "sin((m-x*)/p)/m" "sin((m-x)/p*)/m" 
          x x
          σ σ
        cond
          : or (null? names) (null? x) (null? σ)
            newline
          : > (abs (car x)) (car σ)
            format #t : string-append number-format " " (car names) "  "
                      . (car x) (car σ)
            big-O (cdr names) (cdr x) (cdr σ)
          else
            big-O (cdr names) (cdr x) (cdr σ)


define : flatten li
         append-ec (: i li) i

;; TODO: add filename and title and fix the units
define* : plot-benchmark-result bench H
     let*
        : ensemble-member-count 256
          ensemble-member-plot-skip 4
          y_0 : apply min : map car : map cdr bench
          y_m : apply max : map car : map cdr bench
          nb : apply max : interleave (map car (map car bench)) (map car (map cdr (map car bench)))
          ;; "const" "log(N)" "sqrt(N)" "N" "N^2" "N^3" "log(m)" "sqrt(m)" "m" "m^2" "m^3" "log(N + m)" "N log(m)" "m log(N)" "N m" "N^2 m" "m^2 N"
          x^b : list y_0 (/ y_m (log nb)) (/ y_m (sqrt nb)) (/ y_m nb) (/ y_m nb nb) (/ y_m nb nb nb) (/ y_m (log nb)) (/ y_m (sqrt nb)) (/ y_m nb) (/ y_m nb nb) (/ y_m nb nb nb) (/ y_m nb nb) (/ y_m nb nb) (/ y_m nb nb nb) (/ y_m nb nb nb) (/ y_m nb nb nb nb) (/ y_m nb nb nb nb) y_0 (/ nb 100) 10000 y_0 (/ nb 100) 10000 ; inital guess: constant starting at the first result
          x^b-std : list-ec (: i x^b) i ; inital guess: 100% uncertainty
          P : make-covariance-matrix-with-offdiagonals-using-stds x^b-std
          y⁰-pos : map car bench
          y⁰ : append-map cdr bench
          y⁰-std : list-ref (sort y⁰ <) : round : / (length y⁰) 32 ; lower octile median
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
        ;; TODO: minimize y-mismatch * y-uncertainty
        format #t "Model standard deviation (uncertainty): ~,4e\n" y-std
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
          ;; format port "pl.errorbar(*zip(*sorted(zip(ypos1, yinit))), yerr=zip(*sorted(zip(ypos1, yinitstds)))[1], label='prior vs N')\n"
          format port "pl.errorbar(*zip(*sorted(zip(ypos1, yopt))), yerr=zip(*sorted(zip(ypos1, yoptstds)))[1], marker='H', mew=0, ms=10, linewidth=0.1, label='optimized vs N')\n"
          format port "eb=pl.errorbar(*zip(*sorted(zip(ypos1, y0))), yerr=yerr, alpha=0.6, marker='x', mew=2, ms=10, linewidth=0, label='measurements vs N')\neb[-1][0].set_linewidth(1)\n"
          ;; format port "pl.errorbar(*zip(*sorted(zip(ypos2, yinit))), yerr=zip(*sorted(zip(ypos2, yinitstds)))[1], label='prior vs. m')\n"
          format port "pl.errorbar(*zip(*sorted(zip(ypos2, yopt))), yerr=zip(*sorted(zip(ypos2, yoptstds)))[1], marker='h', mew=0, ms=10, linewidth=0.1, label='optimized vs. m')\n"
          format port "eb=pl.errorbar(*zip(*sorted(zip(ypos2, y0))), yerr=yerr, alpha=0.6, marker='x', mew=2, ms=10, linewidth=0, label='measurements vs. m')\neb[-1][0].set_linewidth(1)\n"
          format port "pl.plot(sorted(ypos1+ypos2), pl.log(sorted(ypos1+ypos2))*(max(y0) / pl.log(max(ypos1+ypos2))), label='log(x)')\n"
          format port "pl.plot(sorted(ypos1+ypos2), pl.sqrt(sorted(ypos1+ypos2))*(max(y0) / pl.sqrt(max(ypos1+ypos2))), label='sqrt(x)')\n"
          format port "pl.plot(sorted(ypos1+ypos2), pl.multiply(sorted(ypos1+ypos2), max(y0) / max(ypos1+ypos2)), label='x')\n"
          list-ec (: step 0 (length x^steps) 4)
               let : : members : list-ref x^steps (- (length x^steps) step 1)
                  list-ec (: member-idx 0 (length members) ensemble-member-plot-skip) ; reversed
                     let : : member : list-ref members member-idx
                       format port "paired = pl.get_cmap('Paired')
cNorm = mpl.colors.Normalize(vmin=~A, vmax=~A)
scalarMap = mpl.cm.ScalarMappable(norm=cNorm, cmap=paired)\n" 0 (length member)
                       list-ec (: param-idx 0 (length member) 4) ; step = 4
                          ;; plot parameter 0
                          let : (offset (/ (apply max (append y⁰ y-opt)) 2)) (spreading (/ (apply max (append y⁰ y-opt)) (- (apply max member) (apply min member))))
                              format port "pl.plot(~A, ~A, marker='.', color=scalarMap.to_rgba(~A), linewidth=0, label='', alpha=0.6, zorder=-1)\n"
                                          . (/ step 1) (+ offset (* spreading (list-ref member param-idx))) param-idx
          format port "pl.legend(loc='upper left')\n"
          format port "pl.xlabel('position [arbitrary units]')\n"
          format port "pl.ylabel('value [arbitrary units]')\n"
          format port "pl.title('~A')\n" "Operation scaling behaviour"
          format port "pl.xscale('log')\n"
          ;; format port "pl.yscale('log')\n"
          format port "pl.show()\n"
          format port "exit()\n"
          close-pipe port


define : main args
   let*
      : bench : benchmark-list-append ;; benchmark results
        H : lambda (x pos) (H-N-m x pos #:const #t #:ON #t #:ONlogN #t)
      plot-benchmark-result bench H
