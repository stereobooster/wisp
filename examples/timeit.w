#!/usr/bin/env sh
# -*- wisp -*-
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples timeit) main)' -s "$0" "$@"
; !#

;; Timeit: NIH Easy benchmarking of code in guile

define-module : examples timeit
              . #:exports : timeit timeit-fun

use-modules : ice-9 match

define* : timeit-fun #:key (fun (lambda () #f)) (let #f) (subtract #f)
          fun

define-syntax-rule : timeit pattern ...
  let matcher
    : pattern pattern
      args '()
    if : null? pattern
      timeit-fun args
      match pattern
        : '#:let c d ...
          matcher 
            cons a d
            cons `(let . ,c) args
        : '#:subtract c d ...
          matcher 
            cons a d
            cons `(subtract . ,c) args
         : a
           let : : fun : lambda () a
           matcher '()
             cons `(fun . ,fun) args
