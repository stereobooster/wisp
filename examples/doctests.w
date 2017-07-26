#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (wisp-scheme) (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples doctests) main)' -s "$0" "$@"
; !#

define-module : examples doctests
              . #:export : doctests-testmod

import : ice-9 optargs
         ice-9 rdelim
         oop goops
         texinfo reflection

; define basic dir
define* (dir #:key (all? #f))
   if all?
      map (λ (x) (cons (module-name x)
                        (module-map (λ (sym var) sym) (resolve-interface (module-name x)))))
           cons (current-module) : module-uses (current-module)
      module-map (λ (sym var) sym) (current-module)
; add support for giving the module as argument
define-generic dir
define-method (dir (all? <boolean>)) (dir #:all? all?)
define-method (dir (m <list>)) (module-map (λ (sym var) sym) (resolve-interface m))
; add support for using modules directly (interfaces are also modules, so this catches both)
define-method (dir (m <module>)) (module-map (λ (sym var) sym) m)

define : string-index s fragment
       . "return the index of the first character of the FRAGMENT in string S."
       let loop : (s s) (i 0)
           if : = 0 : string-length s
              . #f
              if : string-prefix? fragment s
                 . i
                 loop (string-drop s 1) (+ i 1)

define : doctests-extract-from-string s
       . "Extract all test calls from a given string.

          This is an example test:

          (test #:name mytest
              (define v (make-vector 5 99))
              (test-assert (vector? v))
              (test-eqv 99 (vector-ref v 2))
              (vector-set! v 2 7)
              (test-eqv 7 (vector-ref v 2)))
"
       let : : idx : string-index s "(test"
          when idx
              let : : sub : substring s idx
                  with-input-from-string sub
                      λ () : read 

define : doctests-testmod mod
       . "Execute all doctests in the current module"
       let* 
           : names : module-map (λ (sym var) sym) mod
             docstrings
                 map (λ (x) (if (procedure? x) (procedure-documentation x)))
                     map (λ (x) (module-ref mod x)) names
           let loop : (names names) (docstrings docstrings)
               when : not : null? docstrings
                   when : string? : car docstrings
                       let*
                           : name : car names
                             docstring : car docstrings
                             doctest : doctests-extract-from-string : car docstrings
                           write : list name doctest
                           newline
                           let :
                               primitive-eval doctest
                           newline
                   loop (cdr names) (cdr docstrings)

define %this-module : current-module
define : main args
         doctests-testmod %this-module

