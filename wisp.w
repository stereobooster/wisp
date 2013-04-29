#!/home/arne/wisp/wisp-multiline.sh 
; !#

; we need to be able to replace end-of-line characters in brackets and strings

;; nostringandbracketbreaks INPORT
;; 
;; Replace linebreaks within brackets and strings in the INPORT by the
;; placeholders \STRING_BREAK_N and \STRING_BREAK_R. Also identify
;; real comments as ;\REALCOMMENTHERE
;; 
;; -Author: Arne Babenhauserheide
define : nostringandbracketbreaks inport
    ; Replace end of line characters in brackets and strings
    ; FIXME: Breaks if the string is shorter than 2 chars
    let* 
        : lastchar : read-char inport
          nextchar : read-char inport
          text ""
          incomment #f
          incommentfirstchar #f ; first char of a comment
          instring #f
          inbrackets 0
          incharform 0 ; #\<something>
        while : not : eof-object? nextchar
            ; incommentfirstchar is only valid for exactly one char
            when incommentfirstchar : set! incommentfirstchar #f
            ; already started char forms win over everything, so process them first.
            ; already started means: after the #\
            when : >= incharform 2
                if : char=? nextchar #\space
                   set! incharform 0
                   ; else
                   set! incharform : + incharform 1
            ; check if we switch to a string: last char is space, linebreak or in a string, not in a charform, not in a comment
            when 
                 and 
                     char=? nextchar #\"
                     or 
                        . instring ; when I’m in a string, I can get out
                        char=? lastchar #\space ; when the last char was a space, I can get into a string
                        char=? lastchar #\linefeed ; same for newline chars
                        char=? lastchar #\newline
                     not incomment
                     < incharform 1
                set! instring : not instring
            ; check if we switch to a comment
            when 
                 and 
                     char=? nextchar #\;
                     not incomment
                     not instring
                     < incharform 2
                set! incomment #t
                set! incommentfirstchar #t
                ; this also closes any potential charform
                set! incharform 0
            when
                and incomment
                    or 
                        char=? nextchar #\newline
                        char=? nextchar #\linefeed
                set! incomment #f
            
            ; check for the beginning of a charform
            when 
                and
                    not instring
                    not incomment
                    char=? lastchar #\space
                    char=? nextchar #\#
                set! incharform 1
            ; check whether a charform is continued
            when
                and
                     = incharform 1
                     char=? lastchar #\#
                     char=? nextchar #\\
                set! incharform 2
                        
            ; check for brackets
            when : and ( char=? nextchar #\( ) ( not instring ) ( not incomment ) ( = incharform 0 )
                set! inbrackets : + inbrackets 1
            when : and ( char=? nextchar #\) ) ( not instring ) ( not incomment ) ( = incharform 0 )
                set! inbrackets : - inbrackets 1

            if : or instring ( > inbrackets 0 )
                if : char=? nextchar #\linefeed
                    set! text : string-append text "\\LINE_BREAK_N"
                    if : char=? nextchar #\newline
                        set! text : string-append text "\\LINE_BREAK_R"
                        set! text : string-append text : string nextchar
                ; mark the start of a comment, so we do not have to repeat the string matching in later code
                if incommentfirstchar
                    set! text : string-append text ( string nextchar ) "\\REALCOMMENTHERE"
                    ; when not in brackets or string or starting a
                    ; comment: just append the char
                    set! text : string-append text : string nextchar

            set! lastchar nextchar
            set! nextchar : read-char inport
        ; return the text
        . text


; As next part we have to split a single line into indentation, content and comment.
define : splitline inport
    let
        : nextchar : read-char inport
          inindentunderbar #t
          inindent #t ; it always begins in indent
          incomment #f ; but not in a comment
          commentstart #f
          commentstartidentifier "\\REALCOMMENTHERE"
          commentstartidentifierlength 16
          commentidentifierindex 0
          indent 0
          content ""
          comment ""
        while : not : eof-object? nextchar
            ; check wether we leave the initial underbars
            when : and inindentunderbar : not : char=? nextchar #\_
                set! inindentunderbar #f
                set! indent : + indent 1
                continue
            ; check whether we leave the indentation
            when : and inindent : not : char=? nextchar #\space
                set! inindent #f
                set! indent : + indent 1
                continue
            ; check whether we leave the content
            when : and ( not incomment ) : char=? nextchar #\;
                set! commentstart #t
                set! comment : string-append comment : string nextchar
                continue
            ; check whether we stay in the commentcheck
            when : and commentstart : char=? nextchar : char : string-ref commentstartidentifier commentidentifierindex
                 set! commentidentifierindex : + commentidentifierindex 1
                 set! comment : string-append comment : string nextchar
                 when : = commentidentifierindex : - commentstartidentifierlength 1
                     set! commentstart #f
                     set! incomment #t
                     ; reset used variables
                     set! commentidentifierindex 0
                     set! comment ""
                 continue
            ; if we cannot complete the commentcheck, we did not start a real comment. Append it to the content
            when : and commentstart : not : char=? nextchar : char : string-ref commentstartidentifier commentidentifierindex
                set! commentstart #f
                set! content : string-append content comment
                set! comment ""
                set! commentidentifierindex 0
                continue
            ; if we are in the comment, just append to the comment
            when incomment
                set! comment : string-append comment : string nextchar
                continue
            ; if nothing else is true, we are in the content
            set! content : string-append content : string nextchar
        ; return the indentation, the content and the comment
        ' indent content comment


; first step: Be able to mirror a file to stdout

let* 
    : filename : list-ref ( command-line ) 1
      origfile : open-file filename "r" ; mode
      nextchar : read-char origfile
      text ""
    while : not : eof-object? nextchar
        set! text : string-append text : string nextchar
        set! nextchar : read-char origfile
    set! text : call-with-input-string text nostringandbracketbreaks
    display text

newline
