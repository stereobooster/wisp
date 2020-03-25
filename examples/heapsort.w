#!/usr/bin/env bash
# -*- wisp -*-
# Just a fun example of a heapsort using a vector
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
echo ${GUILE}
"${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))'
exec -a "$0" "${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples heapsort)' -c '' "$@"
; !#

define-module : examples heapsort
   . #:export : main

import : only (srfi srfi-43) vector-swap!
         ice-9 pretty-print

define : heapsort data
    define array : list->vector data
    define len : vector-length array
    ;; heaps use 1-indexed indizes for their simple next-index
    ;; calculation, so we use our own functions
    define : heap-set! i value
        vector-set! array { i - 1 } value
    define : heap-ref i
        vector-ref array { i - 1 }
    define : heap-swap! i j
        vector-swap! array { i - 1 } { j - 1 }
    
    define : left-child n
        * 2 n
    define : right-child n
        + 1 : left-child n
    define : parent n
        if {n = 1} 
           . -1
           floor/ n 2
    define : bubble-down! p
        define min-index p
        define : update-min-index! child-index
            when { child-index < { len + 1 } }
                when : < (heap-ref child-index) (heap-ref min-index)
                    set! min-index child-index
        update-min-index! : left-child p
        update-min-index! : right-child p
        when : not { min-index = p }
            heap-swap! p min-index
            bubble-down! min-index
    define : extract-min!
        define min -1
        when { len > 0 }
            set! min : heap-ref 1
            heap-set! 1 : heap-ref { len }
            heap-set! len #f
            set! len { len - 1 }
            bubble-down! 1
        . min
    let loop : : i : floor/ len 2
        when {i >= 1}
            bubble-down! i
            loop { i - 1 }
    map : λ _ : extract-min!
        . data

define : main args
    define data : reverse! : iota 100000
    display : car : heapsort data
    newline
