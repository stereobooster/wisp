#!/usr/bin/env guile
; !#

;; Currently this file contains tests, how the syntax could be nicer. 
;; Longterm it should implement wisp in wisp.

; Test

display "Hello World!"
newline

let : : filename : list-ref ( command-line ) 1
    let : : origfile ( open-file : filename ) "r" ; mode
        let : : nextchar : read-char origfile

            while : not : eof-object? nextchar
                display nextchar
                set! nextchar : read-char origfile

let* 
    : filename : list-ref ( command-line ) 1
      origfile ( open-file : filename ) "r" ; mode
      nextchar : read-char origfile

    while : not : eof-object? nextchar
        display nextchar
        set! nextchar : read-char origfile


newline
