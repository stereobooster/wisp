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
__      : lastchar : read-char inport
____      nextchar : read-char inport
____      text : string lastchar
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

define : line-indent line
    list-ref line 0

define : line-content line
    list-ref line 1

define : line-comment line
    list-ref line 2

define : line-continues? line
    . "Check whether the line is a continuation of a previous line (should not start with a bracket)."
    string-prefix? ". " : line-content line

define : line-empty-code? line
    . "Check whether the code-part of the line is empty: contains only whitespace and/or comment."
    equal? "" : line-content line

define : line-merge-comment line
    . "Merge comment and content into the content. Return the new line."
    let 
        : indent : line-indent line
          content : line-content line
          comment : line-comment line
        if : equal? "" comment
            . line ; no change needed
            list indent (string-append content ";" comment) ""

; skip the leading indentation
define : skipindent inport
    let skipper
        : inunderbars #t
          indent 0
          nextchar : read-char inport
        ; when the file ends, do not do anything else
        if : not : eof-object? nextchar 
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
            when commentstart 
                set! content : string-append content comment
                set! comment ""
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

define : wisp2lisp-add-inline-colon-brackets line
    . "Add inline colon brackets to a wisp-line (indent,content,comment)"
    let : : content : line-content line
        ; replace final " :" by a function call. There we are by definition of the line-splitting not in a string.
        when : string-suffix? " :" content
            set! content : string-append (string-drop-right content 1) "()"
        ; process the content in reverse direction, so we can detect ' : and turn it into '(
        let bracketizer : (instring #f) (inbrackets 0) (bracketstoadd 0) (unprocessed content) (processed "")
              if : < (string-length unprocessed) 3
                  ; if unprocessed is < 3 chars, it cannot contain " : ". We are done.
                  list 
                      line-indent line
                      string-append unprocessed processed : xsubstring ")" 0 bracketstoadd
                      line-comment line
                  ; else
                  let : : lastletter : string-take-right unprocessed 1
                      ; check if we’re in a string
                      when : and (equal? "\"" lastletter) : not : equal? "#\\\"" : string-take-right unprocessed 3
                          set! instring : not instring
                      when : and (equal? ")" lastletter) : not : equal? "#\\)" : string-take-right unprocessed 3
                          set! inbrackets : + 1 inbrackets
                      when : and (equal? "(" lastletter) : not : equal? "#\\(" : string-take-right unprocessed 3
                          set! inbrackets : - 1 inbrackets
                      ; error handling: inbrackets must never be smaller than 0 - due to the line splitting.
                      when : < inbrackets 0
                          throw 'more-inline-brackets-closed-than-opened inbrackets line
                      ; when we’re in a string or in brackets , just skip to the next char
                      if : or instring : > inbrackets 0
                          bracketizer instring inbrackets bracketstoadd 
                              . : string-drop-right unprocessed 1
                              . : string-append lastletter processed
                          ; check for " : ": That adds a new inline bracket
                          if : equal? " : " : string-take-right unprocessed 3
                              ; replace the last 2 chars with "(" and note
                              ; that we need an additional closing bracket
                              ; at the end.
                              bracketizer instring inbrackets : + 1 bracketstoadd 
                                  . : string-append (string-drop-right unprocessed 2) "("
                                  . processed
                              if : and (> (string-length unprocessed) 3) : equal? " ' (" : string-take-right unprocessed 4 
                                  ; leave out the second space
                                  bracketizer instring inbrackets bracketstoadd 
                                      . (string-append (string-drop-right unprocessed 3) "'(")
                                      . processed
                                  ; else, just go on
                                  bracketizer instring inbrackets bracketstoadd 
                                      . (string-drop-right unprocessed 1)
                                      . (string-append lastletter processed)
                        

define : wisp2lisp-parse lisp prev lines
    . "Parse the body of the wisp-code."
    ; let bracketizer : (levels '(0)) (
    set! lines : map-in-order wisp2lisp-add-inline-colon-brackets lines
    append lisp lines

define : wisp2lisp-initial-comments lisp prev lines
    . "Keep all starting comments: do not start them with a bracket."
    ; TODO: currently this adds the first comment twice
    let initial-comments : (lisp lisp) (prev prev) (lines lines)
        if : equal? lines '() ; file only contained comments, maybe including the hashbang
            . lisp
            if : line-empty-code? prev
                initial-comments : append lisp : list prev
                    . (list-ref lines 0) (list-tail lines 1)
                list lisp prev lines

define : wisp2lisp-hashbang lisp prev unprocessed
    . "Parse a potential initial hashbang line."
    if 
        and
            equal? lisp '() ; really the first line
            equal? 0 : line-indent prev
            string-prefix? "#!" : line-content prev
        wisp2lisp-hashbang : append lisp : list : line-merge-comment prev
            . (list-ref unprocessed 0) (list-tail unprocessed 1)
        list lisp prev unprocessed

define : wisp2lisp lines
    . "Parse indentation in the lines to add the correct brackets."
    if : equal? lines '()
        . '()
        let 
            : lisp '() ; the processed lines
              prev : list-ref lines 0 ; the last line
              unprocessed : list-tail lines 1 ; obvious :)
            let* 
                : hashbanged : wisp2lisp-hashbang lisp prev unprocessed
                  deinitialized : apply wisp2lisp-initial-comments hashbanged
                  parsed : apply wisp2lisp-parse deinitialized
                display parsed
                newline
                . parsed

; first step: Be able to mirror a file to stdout
let*
    : filename : list-ref ( command-line ) 1
      text : read-whole-file filename
      ; Lines consist of lines with indent, content and comment. See
      ; line-indent, line-content, line-comment and the other
      ; line-functions for details.
      textlines : split-wisp-lines text
      lines : linestoindented textlines
      lisp : wisp2lisp lines
    ; display : list-ref lines 100 ; seems good
    let show : (processed '()) (unprocessed lisp)
        when : not : equal? unprocessed '()
            display : length processed
            display : line-content : list-ref unprocessed 0
            display ";"
            display : line-comment : list-ref unprocessed 0
            newline
            show  (append processed (list (list-ref unprocessed 0))) (list-tail unprocessed 1)
    
    let : : line : list-ref lisp 158
        display : line-indent line
        display ","
        display : line-content  line
        display ","
        display : line-comment  line
        ; looks good
    ; TODO: add brackets to the content

    ; TODO: undo linebreak-replacing. Needs in-string and in-comment
    ; checking, but only for each line, not spanning multiple lines.

newline
