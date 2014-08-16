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

use-modules : srfi srfi-1

;; Helper functions for the indent-and-symbols data structure: '((indent token token ...) ...)
define : line-indent line
         car line

define : line-code line
         cdr line

define : line-continues? line
         equal? : "." : car : line-code line

define : line-only-colon? line
         and
           equal? : ":" : car : line-code line
           null? : cdr : line-code line

define : line-empty-code? line
         null? : line-code line

define : line-empty? line
         and
           = 0 : line-indent line
           line-empty-code? line


define : wisp-scheme-read-chunk port
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
                 when : and (equal? #\newline next-char) : equal? #\return : peek-char port
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
               : equal? #\space next-char ; remove whitespace when not in indent
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
                   append currentsymbols : list : read port
                   . emptylines
               

define : wisp-scheme-read-all port
         . "Read all chunks from the given port"
         let loop 
           : lines '()
           cond
             : eof-object? : peek-char port
               . lines
             else
               append lines : wisp-scheme-read-chunk port

define : wisp-scheme-read-file path

display  
  call-with-input-string  "  (foo) ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\n  foo : moo \"\n\" \n___ . [goo . hoo]" wisp-scheme-read-chunk
newline
display : call-with-input-string  "  (foo) \n___. [goo . hoo]" wisp-scheme-read-chunk
newline


