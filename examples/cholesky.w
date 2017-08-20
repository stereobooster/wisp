#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples cholesky) main)' -s "$0" "$@"
; !#

;; Cholesky decomposition, following https://de.wikipedia.org/wiki/Cholesky-Zerlegung#Pseudocode

define-module : examples cholesky
              . #:export : cholesky! matrix-ref matrix-set! matrix-transpose matrix-multiply

use-modules : srfi srfi-42 ; list-comprehension
              srfi srfi-11 ; let-values

define : ->exact-matrix list-of-lists
       . "Turn a list of lists into a matrix"
       map 
         λ : x
             apply list : map inexact->exact x
         . list-of-lists

define : ->inexact-matrix list-of-lists
       . "Turn a list of lists into a matrix"
       map 
         λ : x
             apply list : map exact->inexact x
         . list-of-lists

define : matrix-ref X row col
  list-ref (list-ref X row) col

define : matrix-set! X row col val
  let : : sublist : list-ref X row
    list-set! sublist col val
    list-set! X row sublist

define : matrix-transpose X
   . "Swap columns and rows of a matrix"
   list-ec (: outer (length X)) ; outer
     list-ec (: inner (length (list-ref X outer))) ; inner
       matrix-ref X inner outer

define : matrix-multiply X Y
       . "Calculate the matrix product of X and Y"
       list-ec (: row (length Y))
         list-ec (: col (length X))
           sum-ec (: inner (length (list-ref Y row)))
                   * : matrix-ref Y inner col
                       matrix-ref X row inner

define : mostly-exact-sqrt n
       . "Calculate an exact sqrt if possible, else use a good approximation"
       inexact->exact : sqrt : inexact->exact n

define : cholesky! a
  . "Modifies the square matrix a to contain its cholesky decomposition.

sets a to g with a = ggT,

a is represented as list of lists."
  let : : n : length a
    do-ec (: i n)
      do-ec (: j (+ 1 i))
        let : : sum : matrix-ref a i j
          ; format #t "n: ~A i: ~A j: ~A\n" n i j
          when : >= j 1
            do-ec (: k j)
              set! sum : - sum : * (matrix-ref a i k) (matrix-ref a j k)
          cond
            : > i j ; lower triangle
              matrix-set! a i j
                / sum
                  matrix-ref a j j
            : > sum 0 ; diagonal element
              matrix-set! a i i
                mostly-exact-sqrt sum ; preserves the exactness, since the result is an exact number, though not an exact result
            else
              throw 'matrix-numerically-not-symmetric-positive-definite a
    do-ec (: i n)
      do-ec (: j (+ 1 i) n)
        matrix-set! a i j 0
    . a


define : main args
   let
         :  X : ->exact-matrix '(( 1  -1   1)
                                 (-1   3 -.5)
                                 ( 1 -.5   4))
            L : ->exact-matrix '(( 1 0          0)
                                 (-1 1.41421356 0)
                                 ( 1 0.35355339 1.6955825))
         format #t "X\n"
         display : ->inexact-matrix X
         newline
         format #t "cholesky\n"
         display : ->inexact-matrix : cholesky! X
         newline
         format #t "L\n"
         display : ->inexact-matrix L
         newline
         format #t "L·Lt\n"
         display
           ->inexact-matrix
             matrix-multiply L : matrix-transpose L
         newline
         format #t "X·Xt\n"
         display
           ->inexact-matrix
             matrix-multiply X : matrix-transpose X
         newline
