#!/home/arne/wisp/wisp-multiline.sh 
; !#

; we need to be able to replace end-of-line characters in brackets and strings

;; nostringandbracketbreaks INPORT
;; 
;; Replace linebreaks within brackets and strings in the INPORT by the
;; placeholders \LINE_BREAK_N and \LINE_BREAK_R. Also identify
;; real comments as ;\REALCOMMENTHERE
;; 
;; bootstrap via python3 wisp.py wisp-guile.w > 1 && guile 1 wisp-guile.w > 2 && guile 2 wisp-guile.w > 3 && diff 2 3
;; 
;; -Author: Arne Babenhauserheide

define-module : wisp
   . #:export : wisp2lisp nostringandbracketbreaksreader

define : endsinunevenbackslashes text
       if : = 0 : string-length text
           . #f
           let counter
               : last : string-take-right text 1
                 rest : string-append " " : string-drop-right text 1
                 count 0
               cond
                   : = 0 : string-length rest ; end clause: read all
                     odd? count
                   ; end clause: no \ 
                   : not : equal? last : string #\\
                     odd? count
                   else 
                     counter (string-take-right rest 1) (string-drop-right rest 1) (+ 1 count)


define : nostringandbracketbreaks inport
    . "Replace all linebreaks inside strings and brackets with placeholders."
    let : : expressions : list : nostringandbracketbreaksreader inport
        while : not : eof-object? : peek-char inport
            set! expressions : append expressions : list : nostringandbracketbreaksreader inport
        string-join expressions "\n"


define : nostringandbracketbreaksreader inport
    . "Read one wisp-expression from the inport. 
Ends with three consecutive linebreaks or eof."
    ; Replace end of line characters in brackets and strings
    ; FIXME: Breaks if the string is shorter than 2 chars
    ; FIXME: Breaks if the text begins with a comment.
    let* 
__      : lastchar : read-char inport
____      nextchar : read-char inport
____      text : string lastchar
          incomment #f
          incommentfirstchar #f ; first char of a comment
          instring #f
          inbrackets 0
          incharform 0 ; #\<something>
        while 
            not 
                or : eof-object? nextchar
                     and 
                         or (char=? nextchar #\linefeed ) (char=? nextchar #\newline ) 
                         or (char=? lastchar #\linefeed ) (char=? lastchar #\newline ) 
                         ; string-suffix? text "\n\n" ; text includes lastchar
            ; incommentfirstchar is only valid for exactly one char
            when incommentfirstchar : set! incommentfirstchar #f 
            ; but add incommentfirstchar if we just started the text
            when : equal? text ";" ; initial comment
                 set! incommentfirstchar #f
                 set! incomment #t
                 set! text : string-append text "\\REALCOMMENTHERE"
            ; already started char forms win over everything, so process them first.
            ; already started means: after the #\
            ; FIXME: Fails to capture #t and #f which can kill line splitting if it happens inside brackets
            when : = incharform 1
                when : not : and (char=? lastchar #\# ) : or (char=? #\f nextchar) (char=? #\t nextchar)
                    ; format #t "1: set incharform 0: lastchar ~a nextchar ~a instring ~a incomment ~a incharform ~a" lastchar nextchar instring incomment incharform
                    ; newline
                    set! incharform 0
                    
            when : >= incharform 2
                if : or (char=? nextchar #\space) (char=? 
                                nextchar #\linefeed ) (char=? nextchar #\newline ) 
                   begin
                       ; format #t "2: set incharform 0: lastchar ~a nextchar ~a instring ~a incomment ~a incharform ~a" lastchar nextchar instring incomment incharform
                       ; newline
                       set! incharform 0
                   ; else
                   set! incharform : + incharform 1
            ; check if we switch to a string: last char is space, linebreak or in a string, not in a charform, not in a comment
            when 
                and 
                     char=? nextchar #\"
                     not incomment
                     < incharform 1
                     or 
                        and 
                            . instring  ; when I’m in a string, I can get out
                            or 
                                not : char=? lastchar #\\ ; if the last char is not a backslash (escaped quote)
                                ; or the last char is a backslash preceded by an uneven number of backslashes (so the backslash is actually an escaped backslash)
                                and : char=? lastchar #\\
                                      ; not : equal? #f : string-match "\\([^\\]\\)+\\(\\\\\\\\\\)*[\\]$" text ; matches [^\](\\)*\$ - non-backslash + arbitrary number of pairs of backslashes + final backslash which undoes the escaping from the lastchar (by actually escaping the lastchar)
                                      endsinunevenbackslashes text
                        char=? lastchar #\space ; when the last char was a space, I can get into a string
                        char=? lastchar #\linefeed ; same for newline chars
                        char=? lastchar #\newline 
                        and : not instring ; outside of strings, brackets are pseudo-whitespace, too
                              or
                                char=? lastchar #\( 
                                char=? lastchar #\)
                set! instring : not instring
            ; check if we switch to a comment
            when 
                and 
                     ; FIXME: this should be
                     ; char=? nextchar #\;
                     equal? ";" : string nextchar
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
            ; FIXME: This only fixes a single linebreak inside parens, but if a second occurs on the same line it breaks. I do not know why. Maybe something with having lastchar as linebreak.
            when : not : or instring incomment
                when
                    and 
                        not : string-suffix? text "#"
                        not : char=? #\\ lastchar
                        not : endsinunevenbackslashes : string-drop-right text : min 1 : string-length text
                    when : equal? "(" : string nextchar
                        set! inbrackets : + inbrackets 1
                    when : equal? ")" : string nextchar
                        set! inbrackets : - inbrackets 1
            if : or instring : > inbrackets 0
                if : char=? nextchar #\linefeed
                    ; we have to actually construct the escape
                    ; sequence here to be able to parse ourselves.
                    set! text : string-append text : string-append "\\LINE_" "BREAK_N"
                    if : char=? nextchar #\newline
                        set! text : string-append text : string-append "\\LINE_" "BREAK_R"
                        ; else
                        set! text : string-append text : string nextchar
                ; mark the start of a comment, so we do not have to
                ; repeat the string matching in later code. We include
                ; the comment character!
                ; not (instring or inbrackets) = neither instring nor inbrackets
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
        append lines : list nextline

define : line-indent line
    list-ref line 0

define : line-content line
    list-ref line 1

define : line-comment line
    list-ref line 2

define : line-continues? line
    . "Check whether the line is a continuation of a previous line (should not start with a bracket)."
    if : equal? #f : line-content line
        . #f ; this is the EOF line. It does not continue (to ensure that the last brackets get closed)
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
            list indent : string-append content ";" comment
                . ""


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
                ; FIXME: (wisp.py) the reader cuts the ; here, when I write it as this:
                ; when : and ( not incomment ) : char=? nextchar #\; 
                ; FIXME: THIS mistreats #\; as comment! (shown 4 lines after this comment…)
                when 
                    and 
                        not incomment
                        ; FIXME: this should be but would break
                        ; char=? nextchar #\;
                        equal?  ";" : string nextchar
                        not : string-suffix? ( string #\# #\\ ) content
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
                    set! content : string-append content comment : string nextchar
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



define : wisp2lisp-add-inline-colon-brackets line
    . "Add inline colon brackets to a wisp-line (indent,content,comment)"
    let : : content : line-content line
        ; replace final " :" by a function call. There we are by definition of the line-splitting not in a string.
        when : string-suffix? " :" content
            set! content : string-append (string-drop-right content 1) "()"
        ; process the content in reverse direction, so we can detect ' : and turn it into '(
        ; let linebracketizer ( ( instring #f ) ( inbrackets 0 ) ( bracketstoadd 0 ) ( unprocessed content ) ( processed "" ) ) 
        let linebracketizer : ( instring #f ) ( inbrackets 0 ) ( bracketstoadd 0 ) ( unprocessed content ) ( processed "" ) 
              if : < (string-length unprocessed) 2
                  ; if unprocessed is < 2 chars, it cannot contain ": ". We are done.
                  list 
                      line-indent line
                      string-append unprocessed processed : xsubstring ")" 0 bracketstoadd
                      line-comment line
                  ; else
                  let 
                      : lastletter : string-take-right unprocessed 1
                        lastupto3 : string-take-right unprocessed : min 3 : string-length unprocessed
                      ; check if we’re in a string
                      when
                          or
                              and
                                  not instring
                                  equal? "\"" lastletter
                                  not : equal? "#\\\"" lastupto3
                              and
                                  . instring
                                  equal? "\"" lastletter
                                  not : endsinunevenbackslashes : string-drop-right unprocessed 1
                          set! instring : not instring
                      when : not instring
                          when : and (equal? ")" lastletter) : not : equal? "#\\)" lastupto3
                              set! inbrackets : + 1 inbrackets ; remember that we're going backwards!
                          when : and (equal? "(" lastletter) : not : equal? "#\\(" lastupto3
                              set! inbrackets : - inbrackets 1
                      ; error handling: inbrackets must never be smaller than 0 - due to the line splitting.
                      when : < inbrackets 0
                          throw 'more-inline-brackets-closed-than-opened inbrackets line
                      ; when we’re in a string or in brackets , just skip to the next char
                      if : or instring : > inbrackets 0
                          linebracketizer instring inbrackets bracketstoadd 
                              . : string-drop-right unprocessed 1
                              . : string-append lastletter processed
                          ; else check for " : ": That adds a new inline bracket
                          ; support : at the beginning of a line, too.
                          if : or (equal? " : "  lastupto3) (equal? ": " lastupto3)
                              ; replace the last 2 chars with "(" and note
                              ; that we need an additional closing bracket
                              ; at the end.
                              linebracketizer instring inbrackets : + 1 bracketstoadd 
                                  string-append (string-drop-right unprocessed 2) 
                                  string-append "(" processed
                              ; turn " ' (" into " '(", do not modify unprocessed, except to shorten it!
                              if : and (string-prefix? "(" processed) : equal? " ' " lastupto3
                                  ; leave out the second space
                                  linebracketizer instring inbrackets bracketstoadd 
                                      . (string-append (string-drop-right unprocessed 2) "'")
                                      . processed
                                  ; else, just go on
                                  linebracketizer instring inbrackets bracketstoadd 
                                      . (string-drop-right unprocessed 1)
                                      . (string-append lastletter processed)
                        

define : last-indent levels
    . "Retrieve the indentation of the last line: Simply the highest level."
    list-ref levels 0

define : line-add-starting-bracket line
    . "Add a starting bracket to the line, if it is no continuation line (it is more indented than the previous)."
    list 
        line-indent line
        string-append 
            . "("
            line-content line
        line-comment line

define : line-add-closing-brackets line number
    . "Add a closing bracket to the line."
    list 
        line-indent line
        string-append 
            line-content line
            xsubstring ")" 0 number
        line-comment line

define : line-indent-brackets-to-close line-indent levels line-continues prev-continues
    . "Find the number of brackets to close to reduce the levels to the line-indent."
    ; adjust the levels until the highest indentation level is equal
    ; to the indentation of the next line. Then check for
    ; continuation.
    let closer : (bracketstoclose 0) (rest levels)
        let : : highest-level : list-ref rest 0
            ; finish-condition
            if : = line-indent highest-level
                if prev-continues
                    . bracketstoclose
                    + 1 bracketstoclose
                if : > line-indent highest-level
                    closer (- bracketstoclose 1) : append (list line-indent) rest 
                    closer (+ bracketstoclose 1) : list-tail rest 1


define : line-indent-brackets-to-open line-indent levels line-continues prev-continues
    . "Find the number of brackets to open to fit the line-indent and continuation marker."
    if line-continues 
        . 0
        . 1

define : line-indent-levels-adjust levels next-indent
       . "Add or remove levels so the highest remaining level matches next-indent."
       let adjuster : (lev levels)
           let : : highest-level : list-ref lev 0
               if : = next-indent highest-level
                   . lev
                   if : > next-indent highest-level
                       append (list next-indent) lev
                       adjuster : list-tail lev 1

define : line-drop-continuation-dot line
       let : : content : line-content line
           list
               line-indent line
               if : line-continues? line
                   string-drop content 2
                   . content
               line-comment line 

define : wisp2lisp-parse lisp prev lines
    . "Parse the body of the wisp-code."
    set! prev : wisp2lisp-add-inline-colon-brackets prev ; prev already is a code-line.
    if : not : line-continues? prev
        set! prev : line-add-starting-bracket prev
    set! lines : map-in-order wisp2lisp-add-inline-colon-brackets lines
    let bracketizer : (levels '(0)) (pre prev) (unprocessed lines) (processed lisp) (whitespace '())
        ; levels is the list of levels, with the lowest to the right. i.e: '(12 8 4 0)
        ; once we processed everything, we pass the bracketizer pre as f one last time
        if : equal? #f : line-content pre
            . processed
            let : : next : if (equal? unprocessed '()) (list 0 #f #f) : list-ref unprocessed 0 ; this is the break condition for the next loop!
                if : line-empty-code? next ; empty lines get silently added, but otherwise ignored
                    bracketizer levels pre 
                         list-tail unprocessed 1
                         . processed 
                         append whitespace : list next
                    ; firstoff add the next indent to the levels, so we only work on the levels, prev-continues, next-continues and next-indent
                    ; if pre was a continuation, the real levels are 1 lower than the counted levels
                    let*
                        : next-indent : line-indent next
                          pre-indent : line-indent pre
                          pre-continues : line-continues? pre
                          next-continues : line-continues? next
                          final-line : equal? #f : line-content next
                          bracketstocloseprev : line-indent-brackets-to-close next-indent levels next-continues pre-continues
                          bracketstoopennext : line-indent-brackets-to-open next-indent levels next-continues pre-continues
                          newnext : if final-line next : if (> bracketstoopennext 0) (line-add-starting-bracket next) next
                          newpre : line-drop-continuation-dot : line-add-closing-brackets pre bracketstocloseprev
                          newlevels : line-indent-levels-adjust levels next-indent
                        bracketizer newlevels newnext 
                            if final-line unprocessed : list-tail unprocessed 1
                            append processed (list newpre) whitespace
                            list


define : wisp2lisp-initial-comments lisp prev lines
     . "Keep all starting comments: do not start them with a bracket."
     let skip-initial-comments : (lisp lisp) (prev prev) (lines lines)
         if : = 0 : length lines ; file only contained comments, maybe including the hashbang
             . lisp
             if : line-empty-code? prev
                 skip-initial-comments : append lisp : list prev
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

define : wisp2lisp-lines lines
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
                 . parsed


define : string-replace-substring s substring replacement
       . "Replace every instance of substring in s by replacement."
       let : : sublen : string-length substring
           let replacer
               : newstring s
                 index : string-contains s substring
               if : not : equal? index #f
                  let : : replaced : string-replace s replacement index : + index sublen
                    replacer replaced : string-contains replaced substring   
                  . newstring                      
               

define : unescape-linebreaks text
       . "unescape linebreaks"
       string-replace-substring
           ; we have to construct the placeholders here to avoid unescaping them when we parse ourselves…
           string-replace-substring text (string-append "\\LINE_" "BREAK_N") : string #\linefeed
           . (string-append "\\LINE_" "BREAK_R") : string #\newline

define : join-lisp-lines lisp-lines
    let join : (joined "") (unprocessed lisp-lines)
         if : not : equal? unprocessed '()
             let* 
                 : next : list-ref unprocessed 0
                   nextstring 
                       string-append
                           xsubstring " " 0 : line-indent next
                           ; here we re-add all necessary linebreakswe get rid 
                           unescape-linebreaks : line-content next
                           if : equal? "" : line-comment next 
                               . ""
                               string-append ";" : line-comment next
                           . "\n"
                 join  (string-append joined nextstring) (list-tail unprocessed 1)
             . joined

define : wisp2lisp text
       let* 
           : nobreaks : call-with-input-string text nostringandbracketbreaks
             textlines : call-with-input-string nobreaks splitlines
             lines : linestoindented textlines
             lisp-lines : wisp2lisp-lines lines
           join-lisp-lines lisp-lines

 ; first step: Be able to mirror a file to stdout
if : < 1 : length : command-line
    let*
         : filename : list-ref ( command-line ) 1
           text : read-whole-file filename
           ; Lines consist of lines with indent, content and comment. See
           ; line-indent, line-content, line-comment and the other
           ; line-functions for details.
           ; textlines : split-wisp-lines text
           ; lines : linestoindented textlines
           lisp : wisp2lisp text
         display lisp
         newline
    . #f
