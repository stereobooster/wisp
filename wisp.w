#!/home/arne/wisp/wisp-multiline.sh 
; !#

; we need to be able to replace end-of-line characters in brackets and strings

;; define : nostringandbracketbreaks inport
;;     ; Replace end of line characters in brackets and strings
;;     let* 
;;         : nextchar : read-char inport
;;           text ""
;;           incomment #f
;;           instring #f
;;           inbrackets 0
;;           incharform 0
;;         while : not : eof-object? nextchar
;;             when : and ( char=? nextchar #\" ) ( not incomment )
;;                 set! instring : not instring
;;                 display instring
;;             when : and ( char=? nextchar #\; ) ( not incomment ) ( not instring )
;;                 set! incomment #t
;;             when
;;                 and incomment 
;;                     not instring
;;                     or 
;;                         char=? nextchar #\newline
;;                         char=? nextchar #\linefeed
;;                 set! incomment #f
;;             ; TODO: This still treats cod as in brackets which is not, possibly because it cannot cope with char literals: #\( and #\)
;;             when : and ( char=? nextchar #\( ) ( not instring ) ( not incomment ) 
;;                 set! inbrackets : + inbrackets 1
;;             when : and ( char=? nextchar #\) ) ( not instring ) ( not incomment ) 
;;                 set! inbrackets : - inbrackets 1
;; 
;;             if : or instring : > inbrackets 0
;;                 if : char=? nextchar #\linefeed
;;                     set! text : string-append text "\\LINE_BREAK_N"
;;                     if : char=? nextchar #\newline
;;                         set! text : string-append text "\\LINE_BREAK_R"
;;                         set! text : string-append text : string nextchar
;;                 ; when not in brackets or string: just append the char
;;                 set! text : string-append text : string nextchar
;; 
;;             set! nextchar : read-char origfile
;; 

; first step: Be able to mirror a file to stdout

let* 
    : filename : list-ref ( command-line ) 1
      origfile : open-file filename "r" ; mode
      nextchar : read-char origfile
      text ""
    while : not : eof-object? nextchar
        set! text : string-append text : string nextchar
        set! nextchar : read-char origfile
    display text

newline
; (modify-syntax-entry ?: "w")
