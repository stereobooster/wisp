#!/bin/bash
exec guile -L . --language=wisp -s "$0" "$@"
!#

when : not : = 3 : length : command-line
   format #t "Usage: ~A <wisp file> <scheme file>\n" : list-ref (command-line) 0
   exit

define wisp-file : list-ref (command-line) 1
define scheme-file : list-ref (command-line) 2

use-modules 
  srfi srfi-1
  wisp-scheme


define : read-all port
  let readloop : : res : '
    let : : next : read port
      if : eof-object? next
          . res 
          readloop : append res : list next


let
   :
     read-scheme
       with-input-from-file scheme-file 
         λ ()
           read-all : current-input-port
     parsed-wisp
       with-input-from-file wisp-file
         λ () 
           wisp-scheme-read-all : current-input-port
   if : equal? parsed-wisp read-scheme
        format #t "Files ~A and ~A have equivalent content.\n" scheme-file wisp-file
        format #t "Files ~A and ~A are different!\nwisp: ~A, \nscheme: ~a" scheme-file wisp-file parsed-wisp read-scheme
