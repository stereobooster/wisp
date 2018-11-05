#!/usr/bin/env bash
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples ensemble-estimation)' -c '' "$@"
; !#

;; Simple Ensemble Square Root Filter to estimate function parameters
;; based on measurements with uncertainty.

;; Provide first guess parameters x^b and measurements y⁰ to get
;; optimized parameters x^a.

;; Method
;; x^b = '(…) ; first guess of the parameters
;; P = '((…) (…) …) ; parameter covariance
;; y⁰ = '(…) ; observations
;; R = '((…) (…) …) ; observation covariance
;; H: H(x) → y ; provide modelled observations for the given parameters. Just run the function.
;; with N ensemble members (i=1, … N) drawn from the state x^b:
;; For each measurement y⁰_j:
;;     x'^b: X = 1/√(N-1)(x'b_1, …, x'b_N)^T
;;     with P = XX^T ; in the simplest case x'^b are gaussian
;;                     distributed with standard distribution from
;;                     square root of the diagonals.
;;     x_i = x^b + x'^b_i
;;     H(x^b_i) = H(x^b + x'^b_i)
;;     H(x^b) = (1/N)·Σ H(x^b + x'^b_i)
;;     H(x'^b_i) = H(x^b + x'_i) - H(x^b)
;;     HPHt = 1/(N-1)(H(x'_1), …, H(x'_N))(H(x'1), …, H(x'N))T
;;     PHt = 1/(N-1)(x'_1, …, x'_N)(H(x'1), …, H(x'N))T
;;     K = PHt*(HPHt + R)⁻¹
;;     x^a = x^b + K(y⁰_j - H(x^b))
;;     α = (1 + √(R/(HPHt+R)))⁻¹
;;     x'^a = x'^b - αK·H(x'^b)

define-module : examples ensemble-estimation 
              . #:export (EnSRF H standard-deviation-from-deviations 
                          make-covariance-matrix-with-offdiagonals-using-stds
                          x-deviations->y-deviations x^steps main)

use-modules : srfi srfi-42 ; list-ec
              srfi srfi-9 ; records
              oop goops ; generic functions
              ice-9 optargs
              examples cholesky ; cholesky! for random variables with covariance
use-modules 
  : ice-9 popen
        . #:select : open-output-pipe close-pipe

; seed the random number generator
set! *random-state* : random-state-from-platform

define : make-diagonal-matrix-with-trace trace
         let : : dim : length trace
             list-ec (: i dim)
               list-ec (: j dim)
                 if : = i j
                      list-ref trace i
                      . 0.0

define : make-covariance-matrix-with-offdiagonals-using-stds stds
         . "this is a dense covariance matrix with (√1/N std_i std_j) as the off-diagonal elements, with N the number of elements in the stds."
         let : : dim : length stds
             list-ec (: i dim)
               list-ec (: j dim)
                 if : = i j
                      expt (list-ref stds i) 2
                      ; add smaller off-diag elements
                      * (sqrt (/ 1 dim)) (list-ref stds i) (list-ref stds j)

; TODO: Allow for off-diagonal elements
define-class <sparse-covariance-matrix> ()
  trace #:getter get-trace #:init-keyword #:trace
  zeros #:getter get-zeros #:init-keyword #:zeros
  stds #:getter get-stds #:init-keyword #:stds
      . #:allocation #:virtual
      . #:slot-ref (lambda (o)
                       (map (lambda (x) (expt x 0.5)) (slot-ref o 'trace)))
      . #:slot-set! (lambda (o m)
                       (slot-set! o 'trace (map (lambda (x) (expt x 2)) m))
                       (slot-set! o 'zeros (list-ec (: i (length m)) 0)))

define-generic list-ref 
define-method : list-ref (M <sparse-covariance-matrix>) (i <integer>)
              let
                : trace : slot-ref M 'trace
                  zeros : slot-ref M 'zeros
                append
                  list-head zeros i
                  list : list-ref trace i
                  list-tail zeros : + i 1

define-generic length
define-method : length (M <sparse-covariance-matrix>)
                length : slot-ref M 'trace

define : make-covariance-matrix-from-standard-deviations stds
         ; make-diagonal-matrix-with-trace : map (lambda (x) (expt x 2)) stds
         ; make <sparse-covariance-matrix> #:stds stds
         make-covariance-matrix-with-offdiagonals-using-stds stds

define : mean l
       . "Calculate the average value of l (numbers)."
       / : apply + l
           length l
       

define : standard-deviation l
       . "Calculate the standard deviation of list l (numbers)."
       let : : l_mean : mean l
         sqrt
           / : sum-ec (: i l) : expt {i - l_mean} 2
             . {(length l) - 1}

define : standard-deviation-from-deviations . l
       . "Calculate the standard deviation from a list of deviations (x - x_mean)."
       sqrt 
         / : sum-ec (: i l) : expt i 2
           . {(length l) - 1}

define* : write-multiple . x
        . "Helper to avoid suffering from write-newline-typing."
        map : lambda (x) (write x) (newline)
            . x

;; Start with the simple case: One variable and independent observations (R diagonal)
;; First define a truth
define x^seed '(-2 3 -1) ; 0.7 0.9 0.8 0.4)
define x^seed-std '(3 4 2) ; 0.2 0.2 0.2 0.2)
;; The size is the length of the seed, squared, each multiplied by each
define x^true : append-ec (: i (length x^seed)) : list-ec (: j x^seed) : * j : list-ref x^seed i
;; And add an initial guess of the parameters
define x^b : list-ec (: i (length x^true)) 1 ; initial guess
;; set x^b as x^true to test losing uncertainty
; define x^b x^true
define x^b-std : append-ec (: i (length x^seed)) x^seed-std
define P : make-covariance-matrix-from-standard-deviations x^b-std

;; Then generate observations
define y⁰-num 80
define y⁰-pos-max 100
define y⁰-plot-skip : max 1 : * (/ 5 2) {y⁰-num / y⁰-pos-max}
;; At the positions where they are measured. Drawn randomly to avoid
;; giving an undue weight to later values.
define y⁰-pos-sorted : list-ec (: i y⁰-num) : exact->inexact : * y⁰-pos-max : / i y⁰-num 
define y⁰-pos-random : list-ec (: i y⁰-num) : * (random:uniform) y⁰-pos-max
define y⁰-pos y⁰-pos-random

define : H-single-parameter xi xi-pos pos
       . "Observation function for a single parameter."
       let* 
         : xi-posdist : abs : / {pos - xi-pos} {y⁰-pos-max / 20}
         cond
           : < 5 xi-posdist 
             . 0
           else
             * xi pos 
               exp : - : expt xi-posdist 2

define : H-single-parameter-sinx/x xi xi-pos pos
       . "Observation function for a single parameter."
       let* 
         : xi-posdist : abs : / {pos - xi-pos} {y⁰-pos-max / 26.4} ; for (2 2 2 2) this just barely does resolves the two central values
         * xi 15
           / : sin xi-posdist
             . xi-posdist
                    

;; We need an observation operator to generate observations from true values
define : H x pos
       . "Observation operator. It generates modelled observations from the input.

x are parameters to be optimized, pos is another input which is not optimized. For plain functions it could be the position of the measurement on the x-axis. We currently assume absolute knowledge about the position.
"
       let*
           : len : length x
             ystretch y⁰-pos-max
             x-pos : list-ec (: i len) : * ystretch {{i + 0.5} / len}
           sum-ec (: i len)
                   H-single-parameter-sinx/x
                       list-ref x i
                       list-ref x-pos i
                       . pos

;; We start with true observations which we will disturb later to get
;; the equivalent of measured observations
define y^true : list-ec (: i y⁰-pos) : H x^true i
;; now we disturb the observations with a fixed standard deviation. This assumes uncorrelated observations.
define y⁰-std 30
define y⁰ : list-ec (: i y^true) : + i : * y⁰-std : random:normal
;; and define the covariance matrix. This assumes uncorrelated observations.
define R : make-covariance-matrix-from-standard-deviations : list-ec (: i y⁰-num) y⁰-std

;; Alternative: define observations
;; define y⁰-mean 0.8
;; The actual observations
;; define y⁰ : list-ec (: i y⁰-num) : + y⁰-mean : * y⁰-std : random:normal

define : matrix-times-vector X y
       . "Calculate the matrix product of X and Y"
       list-ec (: row (length X))
         sum-ec (: i (length y))
                 * : list-ref y i
                     list-ref (list-ref X row) i


define x^steps '()
define 1-AK '()

define* : EnSRF H x P y R y-pos N #:key (penalty-function-of-x (λ (x) 0))
     . "Observation function H, parameters x,
parameter-covariance P, observations y, observation covariance R
and number of ensemble members N.

TODO: PENALTY-FUNCTION-OF-X is any function which takes the
parameters X and returns a penalty.

Limitations: y is a single value. R and P are diagonal.
"
     let*
       : P_copy : list-ec (: j (length P)) : list-ec (: k (length (list-ref P j))) : list-ref (list-ref P j) k
         L
           cholesky! P_copy
       let step
         : observations-to-process y
           observation-variances : list-ec (: i (length y)) : list-ref (list-ref R i) i
           observation-positions y-pos
           x^b x
           x-deviations ; multiply the sqrt of P (L with LLt=P) with a vector with random perturbations
               list-ec (: i N)
                 matrix-times-vector L
                   list-ec (: j (length x))
                     * : random:normal
                       . 1 ; sqrt : list-ref (list-ref P j) j ; only for diagonal P!
         set! x^steps : cons x-deviations x^steps
         cond
            : null? observations-to-process
              list x^b x-deviations
            else
               ; write : list x^b '± : sqrt : * {1 / {(length x-deviations) - 1}} : sum-ec (: i x-deviations) : expt i 2
               ; newline
               let*
                 : y_cur : car observations-to-process
                   R_cur : * 1 : car observation-variances
                   y-pos_cur : car observation-positions
                   Hx^b_i
                       list-ec (: i x-deviations) 
                           H 
                             list-ec (: j (length i))
                                 + (list-ref x^b j) (list-ref i j)
                             . y-pos_cur
                   Hx^b 
                      / : sum-ec (: i Hx^b_i) i 
                        . N
                   Hx^b-prime 
                       list-ec (: i N) 
                           - : list-ref Hx^b_i i
                             . Hx^b
                   HPHt 
                      / : sum-ec (: i Hx^b-prime) {i * i}
                        . {N - 1}
                   PHt 
                      list-ec (: j (length x^b)) ; for each x^b_i multiply the state-element and model-deviation for all ensemble members.
                         * {1 / {N - 1}} 
                             sum-ec (: i N) 
                               * : list-ref (list-ref x-deviations i) j
                                   list-ref Hx^b-prime i
                   K : list-ec (: i PHt) {i / {HPHt + R_cur}}
                   x^a 
                     list-ec (: j (length x^b))
                       + : list-ref x^b j
                         * : list-ref K j
                           . {y_cur - Hx^b}
                   α-weight-sqrt : sqrt {R_cur / {HPHt + R_cur}}
                   α {1 / {1 + α-weight-sqrt}}
                   x^a-deviations 
                     list-ec (: i N) ; for each ensemble member
                       list-ec (: j (length x^b)) ; and each state variable
                         - : list-ref (list-ref x-deviations i) j
                           * α
                             list-ref K j
                             list-ref Hx^b-prime i
                 if : equal? 1-AK '()
                      set! 1-AK : list-ec (: i K) {1 - i} ; init
                      set! 1-AK : list-ec (: i (length K)) : * (list-ref 1-AK i) {1 - (abs (list-ref K i))}
                 ;; display 1-AK ; TODO: What does this actually signify?
                 ;; newline
                 step
                   cdr observations-to-process
                   cdr observation-variances
                   cdr observation-positions
                   . x^a
                   . x^a-deviations


define : x-deviations->y-deviations H x-opt x-deviations y⁰-pos
         . "Calculate y-deviations for each measurement from the x-deviations.
         
         return ((y_0'0 y_0'1 ...) ...)
         "
         define (~ li i) (list-ref li i)
         ; for each ensemble member calculate the y-deviations
         let*
           : y-opt : map (λ (x) (H x-opt x)) y⁰-pos
             y-ensemble
               list-ec (: x-dev x-deviations) ; x-dev has one number (x'_i) per x-parameter
                     let*
                       : ; calculate x-parameters for the ensemble
                         x-opt+dev
                           list-ec (: j (length x-opt))
                             + : ~ x-opt j
                                 ~ x-dev j
                         ; calculate all y-values for the ensemble
                         y-opt+dev : map (λ (x) (H x-opt+dev x)) y⁰-pos
                       ; calculate all differences
                       map (λ (x y) (- x y)) y-opt+dev y-opt
           ; reshape into one ensemble per value
           list-ec (: ensidx (length (~ y-ensemble 0)))
                list-ec (: obsidx (length y-ensemble))
                     ~ (~ y-ensemble obsidx) ensidx

define : flatten li
         append-ec (: i li) i

define : main args
    let*
      : ensemble-member-count 32
        ensemble-member-plot-skip 4
        optimized : EnSRF H x^b P y⁰ R y⁰-pos ensemble-member-count
        x-opt : list-ref optimized 0
        x-deviations : list-ref optimized 1
        x-std 
              list-ec (: i (length x-opt))
                    apply standard-deviation-from-deviations : list-ec (: j x-deviations) : list-ref j i
        y-deviations : x-deviations->y-deviations H x-opt x-deviations y⁰-pos
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
        σ
          list-ec (: i (length x-opt))
                   apply standard-deviation-from-deviations : list-ec (: j x-deviations) : list-ref j i
        Δ/σ
          list-ec (: i (length x-opt))
                   / : - (list-ref x-opt i) (list-ref x^true i)
                       list-ref σ i
      format #t "x⁰:        ~A\n         ± ~A\nx:         ~A\n         ± ~A\nx^t:       ~A\nx-t/σ:     ~A\n√Σ(Δ/σ)²/N:~A\n√Σσ²:      ~A\ny̅:         ~A ± ~A\ny̅⁰:        ~A ± ~A\ny̅^t:       ~A\nnoise:     ~A\n" 
                 . x^b
                 list-ec (: i (length x^b)) : list-ref (list-ref P i) i
                 . x-opt 
                 . x-std
                 . x^true
                 . Δ/σ
                 * {1 / (length Δ/σ)}
                   sqrt
                     sum-ec (: i Δ/σ)
                        expt i 2
                 sqrt
                   sum-ec (: i σ)
                      expt i 2
                 mean : map (lambda (x) (H x-opt x)) y⁰-pos
                 . y-std
                     ; list-ec (: i (length y-opt))
                     ;   - (list-ref y-opt+dev i) (list-ref y-opt i)
                 ; apply standard-deviation-from-deviations : map H x-deviations ; FIXME: This only works for trivial H.
                 mean y⁰
                 standard-deviation y⁰
                 * {1 / (length y⁰)} : apply + : map (lambda (x) (H x^true x)) y⁰-pos
                 . y⁰-std
      ; now plot the result
      let : : port : open-output-pipe "python2"
        format port "import pylab as pl\nimport matplotlib as mpl\n"
        format port "y0 = [float(i) for i in '~A'[1:-1].split(' ')]\n" y⁰
        format port "yerr = ~A\n" y⁰-std
        format port "ypos = [float(i) for i in '~A'[1:-1].split(' ')]\n" y⁰-pos
        format port "yinit = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : H x^b i
        format port "yinitstds = [float(i) for i in '~A'[1:-1].split(' ')]\n" y^b-stds
        format port "ytrue = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : H x^true i
        format port "yopt = [float(i) for i in '~A'[1:-1].split(' ')]\n" : list-ec (: i y⁰-pos) : H x-opt i
        format port "yoptstds = [float(i) for i in '~A'[1:-1].split(' ')]\n" y-stds
        format port "pl.errorbar(*zip(*sorted(zip(ypos, yinit))), yerr=zip(*sorted(zip(ypos, yinitstds)))[1], label='prior')\n"
        format port "pl.plot(*zip(*sorted(zip(ypos, ytrue))), label='true')\n"
        format port "pl.errorbar(*zip(*sorted(zip(ypos, yopt))), yerr=zip(*sorted(zip(ypos, yoptstds)))[1], label='optimized')\n"
        format port "eb=pl.errorbar(*zip(*sorted(zip(ypos, y0))), yerr=yerr, alpha=0.6, marker='+', linewidth=0, label='measurements')\neb[-1][0].set_linewidth(1)\n"
        list-ec (: step 0 (length x^steps) y⁰-plot-skip)
             let : : members : list-ref x^steps (- (length x^steps) step 1)
                list-ec (: member-idx 0 (length members) ensemble-member-plot-skip) ; reversed
                   let : : member : list-ref members member-idx
                     format port "paired = pl.get_cmap('Paired')
cNorm = mpl.colors.Normalize(vmin=~A, vmax=~A)
scalarMap = mpl.cm.ScalarMappable(norm=cNorm, cmap=paired)\n" 0 (length member)
                     list-ec (: param-idx 0 (length member) 4) ; step = 4
                        ; plot parameter 0
                        format port "pl.plot(~A, ~A, marker='.', color=scalarMap.to_rgba(~A), linewidth=0, label='', alpha=0.6, zorder=-1)\n" (/ step y⁰-plot-skip) (+ 80 (* 60 (list-ref member param-idx))) param-idx
        format port "pl.legend(loc='upper right')\n"
        format port "pl.xlabel('position [arbitrary units]')\n"
        format port "pl.ylabel('value [arbitrary units]')\n"
        format port "pl.title('ensemble optimization results')\n"
        format port "pl.show()\n"
        format port "exit()\n"
        close-pipe port
