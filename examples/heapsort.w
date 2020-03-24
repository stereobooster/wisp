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
    define : left-child n
        * 2 n
    define : right-child n
        + 1 : left-child n
    define : parent n
        if {n = 1} -1
           floor/ n 2
    define : bubble-down! p
        define min-index p
        define : update-min-index! child-index
            when { child-index < len }
                when { (vector-ref array min-index) > (vector-ref array child-index) }
                    set! min-index child-index
        pretty-print : cons min-index array
        update-min-index! : left-child p
        pretty-print : cons min-index array
        update-min-index! : right-child p
        pretty-print : cons min-index array
        when : not { min-index = p }
            vector-swap! array p min-index
            bubble-down! min-index
    ;; TODO: in the Algorithm design menual, this sets min as array 1, not 0
    define : extract-min!
        define min -1
        when { len > 0 }
            set! min : vector-ref array 0
            vector-set! array 0 : vector-ref array { len - 1 }
            set! len { len - 1 }
            bubble-down! 0
        . min
    let loop : : i : floor/ len 2
        when {i >= 1}
            bubble-down! i
        loop { i - 1 }
    extract-min!
    . array

define : main args
    display : heapsort '(4 3 2 1)
    newline
