#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples multithreaded-magic)' -c '' "$@"
; !#

define-module : examples multithreaded-magic
   . #:export : main

; Mathematical magic: Always get one.
; 
; Via http://www.liv.ac.uk/HPC/HTMLF90Course/HTMLF90CourseQuestionsnode18.html
; (actually for learning fortran)
; 
; this is the wisp scheme version which I want to compare with the fortran version.

; Call as PATH=~/guile/meta:$PATH ./examples/multithreaded-magic.w

use-modules 
  ice-9 format
  ice-9 futures
  ice-9 threads

define : magic-threaded mutex futures integer
  ; this can cause unordered output. It’s fun anyway : 
  let
    :
      futures
        cons : future : with-mutex mutex : format #t "~30r\n" integer
          . futures
    if : not : = integer 1
      if : even? integer
        magic-threaded mutex futures {integer / 2}
        magic-threaded mutex futures
              truncate : + 1 {integer / 3}
      for-each touch futures

define : magic integer
  magic-threaded
    make-mutex
    list
    . integer

define : magic-simple integer
  format #t "~30r\n" integer
  if : not : = integer 1
    if : even? integer
      magic-simple : / integer 2
      magic-simple : truncate : + 1 : / integer 3 

define : main args
         display ";;; multithreaded magic ;;;\n"
         magic 456189456156456196152615
         display ";;; simple magic ;;;\n"
         magic-simple 456189456156456196152615
