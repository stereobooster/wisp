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

define : wisp-scheme-reader port
         let loop
           : indent-and-symbols : list ; '((5 "(foobar)" "\"yobble\"")(3 "#t"))
             inindent #t
             incomment #f
             currentindent 0
             currentsymbols '()
           cond
             : eof-object? : peek-char port
               append indent-and-symbols : list : append (list currentindent) currentsymbols
             : and inindent : equal? #\space : peek-char port
               read-char port ; remove char
               loop 
                 . indent-and-symbols
                 . #t ; inindent
                 . #f ; incomment
                 1+ currentindent
                 . currentsymbols
             : equal? #\newline : peek-char port
               read-char port ; remove the newline
               loop
                 append indent-and-symbols : list : append (list currentindent) currentsymbols
                 . #t ; inindent
                 . #f ; incomment
                 . 0
                 . '()
             : equal? #t incomment
               read-char port ; remove one comment character
               loop 
                 . indent-and-symbols
                 . #f ; inindent 
                 . #t ; incomment
                 . currentindent
                 . currentsymbols
             : equal? #\space : peek-char port ; remove whitespace when not in indent
               read-char port ; remove char
               loop 
                 . indent-and-symbols
                 . #f ; inindent
                 . #f ; incomment
                 . currentindent
                 . currentsymbols
             : equal? (string-ref ";" 0) : peek-char port
               loop 
                 . indent-and-symbols
                 . #f ; inindent 
                 . #t ; incomment
                 . currentindent
                 . currentsymbols
             else ; use the reader
               loop 
                 . indent-and-symbols
                 . #f ; inindent
                 . #f ; incomment
                 . currentindent
                 append currentsymbols : list : read port
               

display : call-with-input-string  "  (foo) ; bar\n  foo\n\n" wisp-scheme-reader
