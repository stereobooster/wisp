#!/usr/bin/env sh
# -*- wisp -*-
guile -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" guile -L $(dirname $(dirname $(realpath "$0"))) --language=wisp -x .w -e '(examples pipe)' -c '' "$@"
; !#

;; FIXME: Sometimes this stops early. 
;;        it should always be equivalent to echo 1 | echo 2 | echo 3 | echo 4 
;;        but sometimes it only does echo 1 | echo 2

;; Use pipes to connect several commands

define-module : examples pipe
    . #:export : ! main

import : ice-9 popen
         ice-9 rdelim
         only (srfi srfi-1) fold
         ice-9 pretty-print

define : ! . cmds
       . "A pipe-procedure: connect each of the CMDS with the next
in the list, the first with stdin and the last with stdout."
       define : read-till-eof in-port
           read-delimited "" in-port
       define : connect B A
           let 
               : in-port : if (port? A) A : open-input-pipe A
                 out-port : open-input-output-pipe B
               pretty-print : cons A B
               let : (data (read-till-eof in-port))
                 pretty-print data
                 display data out-port
               close in-port
               . out-port
       fold connect (car cmds) (cdr cmds)

define : main args
    display : read-delimited "" : ! "echo 1" "echo 2" "echo 3" "echo 4"
       
