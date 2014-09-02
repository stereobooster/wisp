#!/home/arne/wisp/wisp-multiline.sh
; !#

;; Scheme-only implementation of a wisp-preprocessor which output a
;; scheme Tree IL to feed to a scheme interpreter instead of a
;; preprocessed file.

;; Plan:
;; read reads the first expression from a string. It ignores comments,
;; so we have to treat these specially. Our wisp-reader only needs to
;; worry about whitespace.
;; 
;; So we can skip all the string and bracket linebreak escaping and
;; directly create a list of codelines with indentation. For this we
;; then simply reuse the appropriate function from the generic wisp
;; preprocessor.


define-module : wisp-scheme
   . #:export (wisp-scheme-read-chunk wisp-scheme-read-all 
               wisp-scheme-read-file-chunk wisp-scheme-read-file
               wisp-scheme-read-string)

use-modules 
  srfi srfi-1
  srfi srfi-11 ; for let-values
  ice-9 rw ; for write-string/partial

;; Helper functions for the indent-and-symbols data structure: '((indent token token ...) ...)
define : line-indent line
         car line

define : line-real-indent line
         . "Get the indentation without the comment-marker for unindented lines (-1 is treated as 0)."
         let : :  indent : line-indent line
             if : = -1 indent
               . 0
               . indent

define : line-code line
         cdr line

; literal values I need
define readcolon 
       call-with-input-string ":" read
define readdot
       call-with-input-string "." read

define : line-continues? line
         equal? readdot : car : line-code line

define : line-only-colon? line
         and
           equal? ":" : car : line-code line
           null? : cdr : line-code line

define : line-empty-code? line
         null? : line-code line

define : line-empty? line
         and
           ; if indent is -1, we stripped a comment, so the line was not really empty.
           = 0 : line-indent line
           line-empty-code? line

define : line-strip-continuation line   
         if : line-continues? line
              append 
                list 
                  line-indent line
                cdr : line-code line
              . line

define : line-strip-indentation-marker line
         ' "Strip the indentation markers from the beginning of the line"
         cdr line

define : indent-level-reduction indentation-levels level select-fun
         . "Reduce the INDENTATION-LEVELS to the given LEVEL and return the value selected by SELECT-FUN"
         let loop 
           : newlevels indentation-levels
             diff 0
           cond
             : = level : car newlevels
               select-fun : list diff indentation-levels
             : < level : car newlevels
               loop
                 cdr newlevels
                 1+ diff
             else
               throw 'wisp-syntax-error "Level ~A not found in the indentation-levels ~A."

define : indent-level-difference indentation-levels level
         . "Find how many indentation levels need to be popped off to find the given level."
         indent-level-reduction indentation-levels level
           lambda : x ; get the count
                    car x

define : indent-reduce-to-level indentation-levels level
         . "Find how many indentation levels need to be popped off to find the given level."
         indent-level-reduction indentation-levels level
           lambda : x ; get the levels
                    car : cdr x


define : wisp-scheme-read-chunk-lines port
         let loop
           : indent-and-symbols : list ; '((5 "(foobar)" "\"yobble\"")(3 "#t"))
             inindent #t
             inunderscoreindent : equal? #\_ : peek-char port
             incomment #f
             currentindent 0
             currentsymbols '()
             emptylines 0
           let : : next-char : peek-char port
             cond
               : eof-object? next-char
                 append indent-and-symbols : list : append (list currentindent) currentsymbols
               : <= 2 emptylines
                 . indent-and-symbols
               : and inindent : equal? #\space next-char
                 read-char port ; remove char
                 loop
                   . indent-and-symbols
                   . #t ; inindent
                   . #f ; inunderscoreindent
                   . #f ; incomment
                   1+ currentindent
                   . currentsymbols
                   . emptylines
               : and inunderscoreindent : equal? #\_ next-char
                 read-char port ; remove char
                 loop 
                   . indent-and-symbols
                   . #t ; inindent
                   . #t ; inunderscoreindent
                   . #f ; incomment
                   1+ currentindent
                   . currentsymbols
                   . emptylines
               ; any char but whitespace *after* underscoreindent is
               ; an error. This is stricter than the current wisp
               ; syntax definition. TODO: Fix the definition. Better
               ; start too strict.
               : and inunderscoreindent : not : equal? #\space next-char
                 throw 'wisp-syntax-error "initial underscores without following whitespace at beginning of the line after" : last indent-and-symbols
               : or (equal? #\newline next-char) (equal? #\return next-char)
                 read-char port ; remove the newline
                 ; TODO: Check whether when or if should be preferred here. guile 1.8 only has if.
                 if : and (equal? #\newline next-char) : equal? #\return : peek-char port
                      read-char port ; remove a full \n\r. Damn special cases...
                 let* ; distinguish pure whitespace lines and lines
                      ; with comment by giving the former zero
                      ; indent. Lines with a comment at zero indent
                      ; get indent -1 for the same reason - meaning
                      ; not actually empty.
                   :
                     indent 
                       cond 
                         incomment 
                           if : = 0 currentindent ; specialcase
                             . -1
                             . currentindent 
                         : not : null? currentsymbols ; pure whitespace
                           . currentindent
                         else
                           . 0
                     parsedline : append (list indent) currentsymbols
                   ; TODO: If the line is empty. Either do it here and do not add it, just
                   ; increment the empty line counter, or strip it later. Replace indent
                   ; -1 by indent 0 afterwards.
                   loop
                     append indent-and-symbols : list parsedline
                     . #t ; inindent
                     equal? #\_ : peek-char port
                     . #f ; incomment
                     . 0
                     . '()
                     if : line-empty? parsedline
                       1+ emptylines
                       . 0
               : equal? #t incomment
                 read-char port ; remove one comment character
                 loop 
                   . indent-and-symbols
                   . #f ; inindent 
                   . #f ; inunderscoreindent 
                   . #t ; incomment
                   . currentindent
                   . currentsymbols
                   . emptylines
               : or (equal? #\space next-char) (equal? #\tab next-char) ; remove whitespace when not in indent
                 read-char port ; remove char
                 loop 
                   . indent-and-symbols
                   . #f ; inindent
                   . #f ; inunderscoreindent
                   . #f ; incomment
                   . currentindent
                   . currentsymbols
                   . emptylines
                        ; | cludge to appease the former wisp parser
                        ; | which had a prblem with the literal comment
                        ; v char.
               : equal? (string-ref ";" 0) next-char
                 loop 
                   . indent-and-symbols
                   . #f ; inindent 
                   . #f ; inunderscoreindent 
                   . #t ; incomment
                   . currentindent
                   . currentsymbols
                   . emptylines
               else ; use the reader
                 loop 
                   . indent-and-symbols
                   . #f ; inindent
                   . #f ; inunderscoreindent
                   . #f ; incomment
                   . currentindent
                   ; this also takes care of the hashbang and leading comments.
                   ; TODO: If used from Guile, activate curly infix via read-options.
                   append currentsymbols : list : read port
                   . emptylines


define : line-code-replace-inline-colons line
         ' "Replace inline colons by opening parens which close at the end of the line"
         ; format #t "replace inline colons for line ~A\n" line
         let loop
           : processed '()
              unprocessed line
           cond
             : null? unprocessed
               ; format #t "inline-colons processed line: ~A\n" processed
               . processed
             : equal? readcolon : car unprocessed
               loop
                 ; FIXME: This should turn unprocessed into a list. 
                 append processed
                   list : loop '() (cdr unprocessed)
                 . '()
             else
               loop 
                 append processed
                   list : car unprocessed
                 cdr unprocessed

define : line-replace-inline-colons line
         cons 
           line-indent line
           line-code-replace-inline-colons : line-code line

define : line-strip-lone-colon line
         . "A line consisting only of a colon is just a marked indentation level. We need to kill the colon before replacing inline colons."
         if 
           equal? 
             line-code line
             list readcolon
           list : line-indent line
           . line

define : line-finalize line
         . "Process all wisp-specific information in a line and strip it"
         line-code-replace-inline-colons 
           line-strip-indentation-marker
             line-strip-lone-colon
               line-strip-continuation line


define : wisp-scheme-indentation-to-parens lines
         . "Add parentheses to lines and remove the indentation markers"
         ; FIXME: Find new algorithm which mostly uses current-line
         ; and the indentation-levels for tracking. The try I have in
         ; here right now is wrong.
         when 
           and 
             not : null? lines
             not : line-empty-code? : car lines
             not : = 0 : line-real-indent : car lines ; -1 is a line with a comment
           throw 'wisp-syntax-error 
             format #f "The first symbol in a chunk must start at zero indentation. Indentation and line: ~A"
               car lines
         let loop
           : processed '()
             unprocessed lines
             indentation-levels '(0)
           let*
             : 
               current-line 
                 if : <= 1 : length unprocessed
                      car unprocessed
                      list 0 ; empty code
               next-line
                 if : <= 2 : length unprocessed
                      car : cdr unprocessed
                      list 0 ; empty code
               current-indentation
                      car indentation-levels
               current-line-indentation : line-real-indent current-line
             ; format #t "processed: ~A\ncurrent-line: ~A\nnext-line: ~A\nunprocessed: ~A\nindentation-levels: ~A\ncurrent-indentation: ~A\n\n"
             ;     . processed current-line next-line unprocessed indentation-levels current-indentation
             cond
                 ; the real end: this is reported to the outside world.
               : and (null? unprocessed) (not (null? indentation-levels)) (null? (cdr indentation-levels))
                 ; display "done\n"
                 ; reverse the processed lines, because I use cons.
                 . processed
               ; the recursion end-condition
               : and (null? unprocessed)
                 ; display "last step\n"
                 ; this is the last step. Nothing more to do except
                 ; for rolling up the indentation levels.  return the
                 ; new processed and unprocessed lists: this is a
                 ; side-recursion
                 values processed unprocessed
               : null? indentation-levels
                 ; display "indentation-levels null\n"
                 throw 'wisp-programming-error "The indentation-levels are null but the current-line is null: Something killed the indentation-levels."
               else ; now we come to the line-comparisons and indentation-counting.
                   cond
                     : line-empty-code? current-line
                       ; display "current-line empty\n"
                       ; We cannot process indentation without
                       ; code. Just switch to the next line. This should
                       ; only happen at the start of the recursion.
                       ; TODO: Somehow preserve the line-numbers.
                       loop
                         . processed
                         cdr unprocessed
                         . indentation-levels
                     : and (line-empty-code? next-line) : <= 2 : length unprocessed 
                       ; display "next-line empty\n"
                       ; TODO: Somehow preserve the line-numbers.
                       ; take out the next-line from unprocessed.
                       loop
                         . processed
                         cons current-line
                           cdr : cdr unprocessed
                         . indentation-levels
                     : > current-indentation current-line-indentation
                       ; display "current-indent > next-line\n"
                       ; this just steps back one level via the side-recursion.
                       values processed unprocessed
                     : = current-indentation current-line-indentation
                       ; display "current-indent = next-line\n"
                       let 
                         : line : line-finalize current-line
                           next-line-indentation : line-real-indent next-line
                         cond
                           : >= current-line-indentation next-line-indentation
                             ; simple recursiive step to the next line
                             ; display "current-line-indent >= next-line-indent\n"
                             loop
                               append processed 
                                 if : line-continues? current-line
                                      . line
                                      list line
                               cdr unprocessed ; recursion here
                               . indentation-levels
                           : < current-line-indentation next-line-indentation
                             ; display "current-line-indent < next-line-indent\n"
                             ; format #t "line: ~A\n" line
                             ; side-recursion via a sublist
                             let-values 
                               :
                                 : sub-processed sub-unprocessed
                                   loop
                                     . line
                                     cdr unprocessed ; recursion here
                                     . indentation-levels
                               ; format #t "side-recursion:\n  sub-processed: ~A\n  processed: ~A\n\n" sub-processed processed
                               loop
                                 append processed : list sub-processed
                                 . sub-unprocessed ; simply use the recursion from the sub-recursion
                                 . indentation-levels
                     : < current-indentation current-line-indentation
                       ; display "current-indent < next-line\n"
                       loop
                         . processed
                         . unprocessed
                         cons ; recursion via the indentation-levels
                           . current-line-indentation 
                           . indentation-levels
                     else
                       throw 'wisp-not-implemented 
                             format #f "Need to implement further line comparison: current: ~A, next: ~A, processed: ~A."
                               . current-line next-line processed


define : wisp-scheme-replace-inline-colons lines
         ' "Replace inline colons by opening parens which close at the end of the line"
         let loop
           : processed '()
             unprocessed lines
           if : null? unprocessed
                . processed
                loop
                  append processed : list : line-replace-inline-colons : car unprocessed
                  cdr unprocessed
                  

define : wisp-scheme-strip-indentation-markers lines
         ' "Strip the indentation markers from the beginning of the lines"
         let loop
           : processed '()
             unprocessed lines
           if : null? unprocessed
                . processed
                loop
                  append processed : cdr : car unprocessed
                  cdr unprocessed

define : wisp-scheme-recreate-improper-lists expressions
         . "Turn (a #{.}# b) into the correct (a . b).

read called on a single dot creates a variable named #{.}# (|.|
in r7rs). Due to parsing the indentation before the list
structure is known, the reader cannot create improper lists
when it reads a dot. So we have to take another pass over the
code to recreate the improper lists.

Traverse each list and sublist backwards, and if it contains a
readdot, cons every element in the list on the last element.

TODO: Find out how I can do that, when the second element is a
function call (a list). Problem: (cons 1 '(2)) -> '(1 2).

TODO: Find out whether this would actually be legal scheme code.
      (write (1 . (+ 1 2))) -> error
      (write . (+ 1 2)) -> strange
      (write (list 1 . (+ 1 2))) -> (1 #<procedure + (#:optional _ _ . _)> 1 2) ???
      (list 1 . (list 2 3)) -> (1 #<procedure list _> 2 3)
      (list . (list 2 3)) -> (#<procedure list _> 2 3) == (list list 2 3)"
         ; FIXME: Implement recreating improper lists!
         let loop
           : processed '()
             unprocessed-reversed expressions
           cond
             : null? unprocessed-reversed
               . processed
             : not : list? unprocessed-reversed
               ; FIXME: This requires unlimited amounts of memory.
               cons unprocessed-reversed processed
             : not : member readdot unprocessed-reversed
               cond
                 : list? : car unprocessed-reversed
                   loop
                     cons 
                       loop '() : car unprocessed-reversed
                       . processed
                     . unprocessed-reversed
                 else
                   loop
                     cons (car unprocessed-reversed) processed
                     cdr unprocessed-reversed
             else ; cons unprocessed on its tail
               let conser
                 : proc-reversed : car unprocessed-reversed
                   unproc : cdr unprocessed-reversed
                 cond
                   : null? unproc
                     ; back to the main loop
                     loop
                       . processed
                       . proc-reversed
                   : equal? readdot : car unproc ; just skip the dot. It is why we cons.
                     conser
                       . proc-reversed
                       cdr unproc
                   else
                     conser
                       cons (car unproc) proc-reversed
                       cdr unproc

define : wisp-scheme-read-chunk port
         . "Read and parse one chunk of wisp-code"
         let : :  lines : wisp-scheme-read-chunk-lines port
              ; display lines
              ; newline
              ; FIXME: incmoplete list recreation does not work yet
              ; wisp-scheme-recreate-improper-lists 
              wisp-scheme-indentation-to-parens lines

define : wisp-scheme-read-all port
         . "Read all chunks from the given port"
         let loop 
           : tokens '()
           cond
             : eof-object? : peek-char port
               ; TODO: Join as string.
               . tokens
             else
               loop
                 append tokens : wisp-scheme-read-chunk port

define : wisp-scheme-read-file path
         call-with-input-file path wisp-scheme-read-all

define : wisp-scheme-read-file-chunk path
         call-with-input-file path wisp-scheme-read-chunk

define : wisp-scheme-read-string str
         call-with-input-string str wisp-scheme-read-all


; TODO: Recreate improper lists.
write
  wisp-scheme-read-string  "foo . bar"
newline 
write
  wisp-scheme-read-string  "foo .
  . bar"
newline 
write
  wisp-scheme-read-string  "foo
  . . bar"
newline 
write
  wisp-scheme-read-string  "moo
  foo
    . . bar
baz waz"
newline 
; systax error
write
  wisp-scheme-read-string  "foo .
  . . bar"
newline 
; write
;   wisp-scheme-read-string  "foo ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\nfoo : moo \"\n\" \n___ . goo . hoo"
; newline 
; display
;   wisp-scheme-read-string  "  foo ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\nfoo : moo"
; newline 
; write : wisp-scheme-read-file-chunk "wisp-scheme.w"
; newline 
; run all chunks in wisp-guile.w as parsed by wisp-scheme.w. Give wisp-guile.w to parse as argument.
; map primitive-eval : wisp-scheme-read-file "wisp-guile.w"
; call-with-output-file "wisp-guile.scm"
;   lambda : port
;     map 
;        lambda : chunk
;                 write chunk port
;        wisp-scheme-read-file "wisp-guile.w"
; pipe the output into 1, then compare it with the output of wisp.scm. If it is equal, this parser works!
; guile wisp.scm wisp-scheme.w > wisp-scheme.scm; guile wisp-scheme.scm wisp-guile.w > 1; guile wisp.scm wisp-guile.w > 2; diff 1 2
