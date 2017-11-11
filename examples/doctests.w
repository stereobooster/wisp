#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -e '(@@ (examples doctests) main)' -s "$0" "$@"
; !#

;;; doctests --- simple testing by adding procedure-properties with tests.

;;; Usage

;; Add a tests property to a procedure to have simple unit tests.

;; Simple tests:
;;
;; (define (A)
;;     #((tests (test-eqv 'A (A))
;;              (test-assert #t)))
;;     'A)
;;
;; Named tests:
;;
;; (define (A)
;;     #((tests ('test1 (test-eqv 'A (A))
;;                      (test-assert #t))
;;              ('test2 (test-assert #t))))
;;     'A)
;;
;; Allows for docstrings:
;;
;; (define (A)
;;     "returns 'A"
;;     #((tests (test-eqv 'A (A))
;;              (test-assert #t)))
;;     'A)

;; For writing the test before the implementation, start with the test and #f:

;; (define (A)
;;     #((tests (test-eqv 'A (A))))
;;     #f)

;; With wisp, you currently need to use the literal #((tests (...)))
;; TODO: add array parsing to wisp following quoting with ':
;;       # a b → #(a b) and # : a b c → #((a b))


define-module : examples doctests
              . #:export : doctests-testmod

import : ice-9 optargs
         ice-9 rdelim
         ice-9 match
         ice-9 pretty-print
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
       . "Extract all test calls from a given string."
       let lp
           : str s
             tests : list
           if : string-null? str
              reverse tests
              let : : idx : string-index str "(test"
                  if : not idx
                      reverse tests
                      let : : sub : substring str idx
                          lp ; recurse with the rest of the string
                             with-input-from-string sub
                                 λ () (read) (read-string)
                             cons
                                 with-input-from-string sub
                                     λ () : read
                                 . tests

define : subtract a b
    . "Subtract B from A."
    ##
      tests : test-eqv 3 (subtract 5 2)
    - a b

define : doctests-testmod mod
       . "Execute all doctests in the current module

          This procedure provides an example test:"
       ##
         tests
            'mytest
              define v (make-vector 5 99)
              test-assert (vector? v)
              test-eqv 99 (vector-ref v 2)
              vector-set! v 2 7
              test-eqv 7 (vector-ref v 2)
            'mytest2
              test-assert #t
       ;; thanks to Vítor De Araújo: https://lists.gnu.org/archive/html/guile-user/2017-08/msg00003.html
       let*
           : names : module-map (λ (sym var) sym) mod
             filename
                 if (module-filename mod) (string-join (string-split (module-filename mod) #\/ ) "-")
                     string-join (cons "._" (map symbol->string (module-name mod))) "-"
             doctests
                 map (λ (x) (if (procedure? x) (procedure-property x 'tests)))
                     map (λ (x) (module-ref mod x)) names
           let loop
               : names names
                 doctests doctests
               ;; pretty-print doctests
               ;; newline
               when : pair? doctests
                   let*
                       : name : car names
                         doctest : car doctests
                       let loop-tests
                          : doctest doctest
                          when : and (pair? doctest) (car doctest) : pair? : car doctest
                             ;; pretty-print : car doctest
                             ;; newline
                             let*
                               :
                                 testid
                                    match doctest
                                      : (('quote id) tests ...) moretests ...
                                        string-join : list filename (symbol->string name) : symbol->string id
                                                     . "--"
                                      : tests ...
                                        string-join : list filename (symbol->string name)
                                                     . "--"
                                 body
                                     match doctest
                                      : (('quote id) test tests ...) moretests ...
                                        cons test tests
                                      : tests ...
                                        . tests
                                 cleaned
                                        cons 'begin
                                            cons '(import (srfi srfi-64)) 
                                                cons 
                                                    list 'test-begin : or testid ""
                                                    append
                                                        . body
                                                        list : list 'test-end : or testid ""
                               ;; pretty-print testid
                               ;; pretty-print body
                               ;; pretty-print cleaned
                               ;; newline
                               when cleaned
                                   let :
                                       eval cleaned mod
                                   newline
                               match doctest
                                      : (('quote id) tests ...) moretests ...
                                        loop-tests moretests
                                      : tests ...
                                        . #t
                   loop (cdr names) (cdr doctests)

define %this-module : current-module
define : main args
         doctests-testmod %this-module

