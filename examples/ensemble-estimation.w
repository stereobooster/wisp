#!/usr/bin/env sh
exec guile -L ~/wisp --language=wisp "$0" "$@"
; !#

;; Simple Ensemble Square Root Filter to estimate function parameters
;; based on measurements.

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

use-modules : srfi srfi-42 ; list-ec

; seed the random number generator
; set! *random-state* : random-state-from-platform
;; Start with the simple case: One variable and independent observations (R diagonal)
define x^b '(1) ; initial guess
define P '((0.25)) ; standard deviation 0.5

define y⁰ '(0.8 0.7 0.9 0.75) ; real value: 0.8
define R '((0.1 0 0 0) ; standard deviation √0.1
           (0 0.1 0 0)
           (0 0 0.1 0)
           (0 0 0 0.1))

define : H-single x
       . "Simple single state observation operator which just returns the state."
       . x

define* : write-multiple . x
        map : lambda (x) (write x) (newline)
            . x

define : EnSRT-single-state H x P y R N
       . "Observation function H, parameters x,
parameter-covariance P, observations y, observation covariance R
and number of ensemble members N.

Limitations: x is a single value, P is a single value (variance of x).
"
       let process-observation
         : observations-to-process y
           observation-variances : list-ec (: i (length y)) : list-ref (list-ref R i) i
           x^b : list-ref x 0
           x-deviations : list-ec (: i N) : * (random:normal) : sqrt : list-ref (list-ref P 0) 0; only for single x'^b 
         cond
            : null? observations-to-process
              list x^b x-deviations
            else
               write : list (expt x^b 2) '± : * {1 / {(length x-deviations) - 1}} : sum-ec (: i x-deviations) : expt i 2
               newline
               let*
                 : y_cur : car observations-to-process
                   R_cur : car observation-variances
                   Hx^b_i : list-ec (: i x-deviations) : H {x^b + i} ; this only works for single value x!
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
                      list-ec (: j (length x)) ; for each x^b_i multiply the state-element and model-deviation for all ensemble members. This is not used at the moment.
                         * {1 / {N - 1}} 
                             sum-ec (: i N) 
                               * : list-ref x-deviations i ; FIXME: this currently does not use j because I only do length 1 x
                                   list-ref Hx^b-prime i
                   K : list-ec (: i PHt) {i / {HPHt + R_cur}}
                   x^a 
                     list-ec (: i (length K)) 
                       + x^b
                         * : list-ref K i
                           . {y_cur - Hx^b}
                   α-weight-sqrt : sqrt {R_cur / {HPHt + R_cur}}
                   α {1 / {1 + α-weight-sqrt}}
                   x^a-deviations 
                     list-ec (: i N)
                       - : list-ref x-deviations i
                         * α
                           list-ref K 0
                           list-ref Hx^b-prime i
                 process-observation
                   cdr observations-to-process
                   cdr observation-variances
                   list-ref x^a 0
                   . x^a-deviations

write : EnSRT-single-state H-single x^b P y⁰ R 30
newline
