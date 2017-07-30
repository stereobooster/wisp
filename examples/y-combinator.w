#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples y-combinator) main)' -s "$0" "$@"
; !#

define-module : examples y-combinator

;; Poor mans y-combinator from William Byrds talk: https://www.youtube.com/watch?v=OyfBQmvr2Hc&t=2844s 
define fac-pmy-zealous-wisp
  :
    λ : !
      λ : n
        :
          ! !
          . n
    λ : !
      λ : n
        if : zero? n
           . 1
           * n
             :
                ! !
                - n 1

define fac-pmy-pragmatic-wisp
  :
    λ : !
      λ : n
        (! !) n
    λ : !
      λ : n
        if : zero? n
           . 1
           * n : (! !) {n - 1}


;; Poor mans y-combinator from William Byrds talk: https://www.youtube.com/watch?v=OyfBQmvr2Hc&t=2844s 
define facres-pmy
 . (((λ (!)
     (λ (n)
       ((! !) n)))
     (λ (!)
       (λ (n)
         (if (zero? n)
             1
             (* n ((! !) (- n 1)))))))
   5)

;; from rosetta code: https://rosettacode.org/wiki/Y_combinator#Scheme
define Y
  λ : h
    : λ (x) : x x
      λ : g
         h : λ args : apply (g g) args

define fac
  Y
    λ : f
      λ : x
        if : < x 2
           . 1
           * x : f : - x 1

define fib
  Y
    λ : f
      λ : x
        if : < x 2
           . x
           + : f : - x 1
               f : - x 2


define : main args
         display : fac-pmy-zealous-wisp 5
         newline
         display : fac-pmy-pragmatic-wisp 5
         newline
         display facres-pmy
         newline
         display : fac 6
         newline
         display : fib 6
         newline
