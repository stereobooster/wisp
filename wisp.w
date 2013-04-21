#!/usr/bin/env guilewisp 
; !#

; Test

display "Hello World!"
newline

let 
    :
        origfile 
            open-file 
                list-ref 
                    command-line
                    . 1
                . "r"
    let : : nextchar : read-char origfile
        while : not : eof-object? nextchar
            display nextchar
            set! nextchar : read-char origfile

newline
