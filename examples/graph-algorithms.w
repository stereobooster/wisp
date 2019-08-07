#!/usr/bin/env bash
# -*- wisp -*- 
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
exec -a "$0" "${GUILE}" -L "$(dirname "$(dirname "$(realpath "$0")")")" -x .w --language=wisp -e '(examples graph-algorithms)' -c '' "$@"
; !#

define-module : examples graph-algorithms
   . #:export : main

import : ice-9 pretty-print

define nodelist : vector "n" "foo" "bar"

define edgelist-by-index
    ' : 1 . 2
        1 . 0
        2 . 1
    
define seen
    make-bitvector {64 * 1024} #f

define : nodes-and-edges->adjacency-lists-by-index nodelist edgelist-by-index
    . "Assemble adjacency lists by index in the nodelist"
    define number-of-nodes : vector-length nodelist
    define adjacency-lists : make-vector number-of-nodes '()
    let loop : : unprocessed edgelist-by-index
        if : null? unprocessed
           . adjacency-lists
           let : : edge : car unprocessed
               vector-set! adjacency-lists : car edge
                   cons (cdr edge) : vector-ref adjacency-lists : car edge
               loop : cdr unprocessed

define : main args
    pretty-print nodelist
    pretty-print edgelist-by-index
    pretty-print : nodes-and-edges->adjacency-lists-by-index nodelist edgelist-by-index
