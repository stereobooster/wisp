#!/usr/bin/env bash
# -*- wisp -*-
# set Guile if unset
if [ -z ${GUILE+x} ]; then
	GUILE=guile
fi
"${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -c '(import (language wisp spec))' 2>/dev/null 1>/dev/null
exec -a "$0" "${GUILE}" -L $(dirname $(dirname $(realpath "$0"))) -x .w --language=wisp -e '(examples triangle)' -c '' "$@" 2>/dev/null
; !#

;;; Just converted for fun from the OCaml solution by Andrew Kensler
;;; at
;;; http://www.frank-buss.de/challenge/solutions/andrew-func.ml.html
;;; for the triangle counting challenge
;;; http://www.frank-buss.de/challenge/index.html

define-module : examples triangle
   . #:export : main

define : count_func lsides rsides
  define rsides-1 {rsides - 1}
  define lsides-1 {lsides - 1}
  let loop : (ls 0) (rs 0) (le 0) (re 0) (total 0)
    define new_tot 
        if : or {ls = 0} {rs = 0}
           . {total + 1} total
    cond
        {re < rsides-1} : loop ls rs le { re + 1 } new_tot
        {le < lsides-1} : loop ls rs { le + 1 } rs new_tot
        {rs < rsides-1} : loop ls { rs + 1 } ls { rs + 1 } new_tot
        {ls < lsides-1} : loop { ls + 1 } 0 { ls + 1 } 0 new_tot
        else new_tot

define : main args
    display : count_func 3 3
    newline
