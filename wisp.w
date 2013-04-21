#!/usr/bin/env guile
; !#

; Test

display "Hello World!"
newline

define : nth idx form
    list-ref form idx

let 
    :
        origfile 
            open-file : nth 1 : command-line
                . "r" ; mode
    
    let : : nextchar : read-char origfile
        while : not : eof-object? nextchar
            display nextchar
            set! nextchar : read-char origfile

newline
