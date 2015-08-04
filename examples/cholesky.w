#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples cholesky) main)' -s "$0" "$@"
; !#

;; Cholesky decomposition, following https://de.wikipedia.org/wiki/Cholesky-Zerlegung#Pseudocode

define-module : examples cholesky
              . #:exports : cholesky!

use-modules : guildhall ext foof-loop

define : matrrix-ref X u v
  list-ref (list-ref X u) v

define : matrrix-set! X u v val
  list-set! (list-ref X u) v val


define : cholesky! a
  . "Modifies the square matirx a to contain its cholesky decomposition.

sets a to g with a = ggT,

a is represented as list of lists."
  let : : n : length a
    loop : : for i : up-from 1 : to n
      loop : : for j : up-from 1 : to i
        let : : sum : matrix-ref a i j
          when (>= j 1)
            loop : : for k : up-from 1 : to {j - 1}
              set! sum : - sum : * (matrix-ref a i k) (matrix-ref a j k)
          cond
            : > i j ; lower triangle
              matrix-set! a i j
                / sum : matrix-ref a j j
              . a
            : > sum 0 ; diagonal element
              matrix-set! a i i : sqrt sum
              . a
            else
              throw 'matrix-numerically-not-symmetric-positive-definite


define : main args
         display : cholesky! '((1 2)(2 4))
