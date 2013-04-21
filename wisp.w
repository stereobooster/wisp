#!/usr/bin/env guile
; !#

; first step: Be able to mirror a file to stdout

let* 
    : filename : list-ref ( command-line ) 1
      origfile : open-file filename "r" ; mode
      nextchar : read-char origfile

    while : not : eof-object? nextchar
        display nextchar
        set! nextchar : read-char origfile

newline
