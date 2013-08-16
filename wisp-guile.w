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
          text : string lastchar
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
                        ; else
                        set! text : string-append text : string nextchar
                ; mark the start of a comment, so we do not have to
                ; repeat the string matching in later code. We include
                ; the comment character!
                if incommentfirstchar
                    set! text : string-append text ( string nextchar ) "\\REALCOMMENTHERE"
                    ; when not in brackets or string or starting a
                    ; comment: just append the char
                    set! text : string-append text : string nextchar

            set! lastchar nextchar
            set! nextchar : read-char inport
        ; return the text
        . text


; As next part we have split a text into a list of lines which we can process one by one.
; FIXME: Cuts off the beginning of the content.
define : splitlines inport 
    let 
        : lines '()
          nextchar : read-char inport
          nextline ""
        while : not : eof-object? nextchar
            if : not : or (char=? nextchar #\newline ) (char=? nextchar #\linefeed )
                set! nextline : string-append nextline : string nextchar
                begin 
                    set! lines : append lines (list nextline)
                    set! nextline ""
            set! nextchar : read-char inport
        . lines

; skip the leading indentation
define : skipindent inport
    let skipper
        : inunderbars #t
          indent 0
          nextchar : read-char inport
        ; when the file ends, do not do anything else
        when : not : eof-object? nextchar 
            ; skip underbars
            if inunderbars
                if : char=? nextchar #\_ ; still in underbars?
                    skipper 
                        . #t ; still in underbars?
                        + indent 1
                        read-char inport
                    ; else, reevaluate without inunderbars
                    skipper #f indent nextchar
                ; else: skip remaining spaces
                if : char=? nextchar #\space
                    skipper
                        . #f
                        + indent 1
                        read-char inport
                    begin
                        unread-char nextchar inport
                        . indent

; Now we have to split a single line into indentation, content and comment.
define : splitindent inport
    let 
        : indent : skipindent inport
        let
            : nextchar : read-char inport
              inindent #t ; it always begins in indent
              incomment #f ; but not in a comment
              commentstart #f
              commentstartidentifier "\\REALCOMMENTHERE"
              commentstartidentifierlength 16
              commentidentifierindex 0
              content ""
              comment ""
            while : not : eof-object? nextchar
                ; check whether we leave the content
                when : and ( not incomment ) : char=? nextchar #\;
                    set! commentstart #t
                    set! comment : string-append comment : string nextchar
                    set! nextchar : read-char inport
                    continue
                ; check whether we stay in the commentcheck
                when : and commentstart : char=? nextchar : string-ref commentstartidentifier commentidentifierindex
                    set! commentidentifierindex : + commentidentifierindex 1
                    set! comment : string-append comment : string nextchar
                    when : = commentidentifierindex commentstartidentifierlength
                        set! commentstart #f
                        set! incomment #t
                        ; reset used variables
                        set! commentidentifierindex 0
                        set! comment ""
                    set! nextchar : read-char inport
                    continue
                ; if we cannot complete the commentcheck, we did not start a real comment. Append it to the content
                when : and commentstart : not : char=? nextchar : string-ref commentstartidentifier commentidentifierindex
                    set! commentstart #f
                    set! content : string-append content comment
                    set! comment ""
                    set! commentidentifierindex 0
                    set! nextchar : read-char inport
                    continue
                ; if we are in the comment, just append to the comment
                when incomment
                    set! comment : string-append comment : string nextchar
                    set! nextchar : read-char inport
                    continue
                ; if nothing else is true, we are in the content
                set! content : string-append content : string nextchar
                set! nextchar : read-char inport
            ; return the indentation, the content and the comment
            list indent content comment


; Now use the function to split a list of lines
define : linestoindented lines
    let splitter
        : unprocessed lines
          processed '()
        if : equal? unprocessed '()
            . processed
            ; else: let-recursion
            splitter
                list-tail unprocessed 1
                append processed 
                    list 
                        call-with-input-string 
                            list-ref unprocessed 0
                            . splitindent


define : read-whole-file filename
    let : : origfile : open-file filename "r"
        let reader 
            : text ""
              nextchar : read-char origfile
            if : eof-object? nextchar
                . text
                reader 
                    string-append text : string nextchar
                    read-char origfile

define : split-wisp-lines text
    call-with-input-string 
        call-with-input-string text nostringandbracketbreaks
        . splitlines 


; first step: Be able to mirror a file to stdout
let* 
    : filename : list-ref ( command-line ) 1
      text : read-whole-file filename
      lines : split-wisp-lines text
    ; display : list-ref lines 100 ; seems good
    set! lines : linestoindented lines
    let : : line : list-ref lines 158
        display : list-ref line 0
        display ","
        display : list-ref line 1
        display ","
        display : list-ref line 2
        ; looks good
    ; TODO: add brackets to the content

    ; TODO: undo linebreak-replacing. Needs in-string and in-comment
    ; checking, but only for each line, not spanning multiple lines.

newline
