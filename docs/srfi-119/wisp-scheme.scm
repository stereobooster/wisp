#!/bin/bash
(# -*- wisp -*-)
(exec guile -L . --language=wisp -s "$0" "$@")
; !#

;; Scheme-only implementation of a wisp-preprocessor which output a
;; scheme code tree to feed to a scheme interpreter instead of a
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

;; Copyright (C) Arne Babenhauserheide (2014--2015). All Rights Reserved.

;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;; 
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.


(define-module (wisp-scheme)
   #:export (wisp-scheme-read-chunk wisp-scheme-read-all 
               wisp-scheme-read-file-chunk wisp-scheme-read-file
               wisp-scheme-read-string))

; use curly-infix by default
(read-enable 'curly-infix)

(use-modules 
  (srfi srfi-1)
  (srfi srfi-11 ); for let-values
  (ice-9 rw ); for write-string/partial
  (ice-9 match))

;; Helper functions for the indent-and-symbols data structure: '((indent token token ...) ...)
(define (line-indent line)
         (car line))

(define (line-real-indent line)
         "Get the indentation without the comment-marker for unindented lines (-1 is treated as 0)."
         (let (( indent (line-indent line)))
             (if (= -1 indent)
               0
               indent)))

(define (line-code line)
         (let ((code (cdr line)))
             ; propagate source properties
             (when (not (null? code))
                    (set-source-properties! code (source-properties line)))
             code))

; literal values I need
(define readcolon 
       (string->symbol ":"))

(define wisp-uuid "e749c73d-c826-47e2-a798-c16c13cb89dd")
; define an intermediate dot replacement with UUID to avoid clashes.
(define repr-dot ; .
       (string->symbol (string-append "REPR-DOT-" wisp-uuid)))

; allow using reader additions as the first element on a line to prefix the list
(define repr-quote ; '
       (string->symbol (string-append "REPR-QUOTE-" wisp-uuid)))
(define repr-unquote ; ,
       (string->symbol (string-append "REPR-UNQUOTE-" wisp-uuid)))
(define repr-quasiquote ; `
       (string->symbol (string-append "REPR-QUASIQUOTE-" wisp-uuid)))
(define repr-unquote-splicing ; ,@
       (string->symbol (string-append "REPR-UNQUOTESPLICING-" wisp-uuid)))

(define repr-syntax ; #'
       (string->symbol (string-append "REPR-SYNTAX-" wisp-uuid)))
(define repr-unsyntax ; #,
       (string->symbol (string-append "REPR-UNSYNTAX-" wisp-uuid)))
(define repr-quasisyntax ; #`
       (string->symbol (string-append "REPR-QUASISYNTAX-" wisp-uuid)))
(define repr-unsyntax-splicing ; #,@
       (string->symbol (string-append "REPR-UNSYNTAXSPLICING-" wisp-uuid)))

; TODO: wrap the reader to return the repr of the syntax reader
; additions 

(define (match-charlist-to-repr charlist)
         (let 
           ((chlist (reverse charlist)))
           (cond
             ((equal? chlist (list #\.))
               repr-dot)
             ((equal? chlist (list #\'))
               repr-quote)
             ((equal? chlist (list #\,))
               repr-unquote)
             ((equal? chlist (list #\`))
               repr-quasiquote)
             ((equal? chlist (list #\, #\@ ))
               repr-unquote-splicing)
             ((equal? chlist (list #\# #\' ))
               repr-syntax)
             ((equal? chlist (list #\# #\, ))
               repr-unsyntax)
             ((equal? chlist (list #\# #\` ))
               repr-quasisyntax)
             ((equal? chlist (list #\# #\, #\@ ))
               repr-unsyntax-splicing)
             (else
               #f))))

(define (wisp-read port)
       "wrap read to catch list prefixes."
       (let ((prefix-maxlen 4))
         (let longpeek 
           ((peeked '())
             (repr-symbol #f))
           (cond
             ((or (< prefix-maxlen (length peeked)) (eof-object? (peek-char port)) (equal? #\space (peek-char port)) (equal? #\newline (peek-char port)) )
               (if repr-symbol ; found a special symbol, return it.
                  ; TODO: Somehow store source-properties. The commented-out code below does not work.
                  ; catch #t
                  ;     lambda ()
                  ;         write : source-properties symbol-or-symbols
                  ;         set-source-property! symbol-or-symbols 'filename : port-filename port
                  ;         set-source-property! symbol-or-symbols 'line : 1+ : port-line port
                  ;         set-source-property! symbol-or-symbols 'column : port-column port
                  ;         write : source-properties symbol-or-symbols
                  ;     lambda : key . arguments
                  ;         . #f
                  repr-symbol
                  (let unpeek
                    ((remaining peeked))
                    (cond
                      ((equal? '() remaining )
                        (read port )); let read to the work
                      (else
                        (unread-char (car remaining) port)
                        (unpeek (cdr remaining)))))))
             (else
               (let* 
                 ((next-char (read-char port))
                   (peeked (cons next-char peeked)))
                 (longpeek
                   peeked
                   (match-charlist-to-repr peeked))))))))
                 


(define (line-continues? line)
         (equal? repr-dot (car (line-code line))))

(define (line-only-colon? line)
         (and
           (equal? ":" (car (line-code line)))
           (null? (cdr (line-code line)))))

(define (line-empty-code? line)
         (null? (line-code line)))

(define (line-empty? line)
         (and
           ; if indent is -1, we stripped a comment, so the line was not really empty.
           (= 0 (line-indent line))
           (line-empty-code? line)))

(define (line-strip-continuation line   )
         (if (line-continues? line)
              (append 
                (list 
                  (line-indent line))
                (cdr (line-code line)))
              line))

(define (line-strip-indentation-marker line)
         "Strip the indentation markers from the beginning of the line"
         (cdr line))

(define (indent-level-reduction indentation-levels level select-fun)
         "Reduce the INDENTATION-LEVELS to the given LEVEL and return the value selected by SELECT-FUN"
         (let loop 
           ((newlevels indentation-levels)
             (diff 0))
           (cond
             ((= level (car newlevels))
               (select-fun (list diff indentation-levels)))
             ((< level (car newlevels))
               (loop
                 (cdr newlevels)
                 (1+ diff)))
             (else
               (throw 'wisp-syntax-error "Level ~A not found in the indentation-levels ~A.")))))

(define (indent-level-difference indentation-levels level)
         "Find how many indentation levels need to be popped off to find the given level."
         (indent-level-reduction indentation-levels level
           (lambda (x ); get the count
                    (car x))))

(define (indent-reduce-to-level indentation-levels level)
         "Find how many indentation levels need to be popped off to find the given level."
         (indent-level-reduction indentation-levels level
           (lambda (x ); get the levels
                    (car (cdr x)))))


(define (wisp-scheme-read-chunk-lines port)
         (let loop
           ((indent-and-symbols (list )); '((5 "(foobar)" "\"yobble\"")(3 "#t"))
             (inindent #t)
             (inunderscoreindent (equal? #\_ (peek-char port)))
             (incomment #f)
             (currentindent 0)
             (currentsymbols '())
             (emptylines 0))
           (cond
            ((>= emptylines 2 ); the chunk end has to be checked
                              ; before we look for new chars in the
                              ; port to make execution in the REPL
                              ; after two empty lines work
                              ; (otherwise it shows one more line).
             indent-and-symbols)
            (else
             (let ((next-char (peek-char port)))
               (cond
                 ((eof-object? next-char)
                   (append indent-and-symbols (list (append (list currentindent) currentsymbols))))
                 ((and inindent (zero? currentindent) (not incomment) (not (null? indent-and-symbols)) (not inunderscoreindent) (not (or (equal? #\space next-char) (equal? #\newline next-char) (equal? (string-ref ";" 0) next-char))))
                  (append indent-and-symbols )); top-level form ends chunk
                 ((and inindent (equal? #\space next-char))
                   (read-char port ); remove char
                   (loop
                     indent-and-symbols
                     #t ; inindent
                     #f ; inunderscoreindent
                     #f ; incomment
                     (1+ currentindent)
                     currentsymbols
                     emptylines))
                 ((and inunderscoreindent (equal? #\_ next-char))
                   (read-char port ); remove char
                   (loop 
                     indent-and-symbols
                     #t ; inindent
                     #t ; inunderscoreindent
                     #f ; incomment
                     (1+ currentindent)
                     currentsymbols
                     emptylines))
                 ; any char but whitespace *after* underscoreindent is
                 ; an error. This is stricter than the current wisp
                 ; syntax definition. TODO: Fix the definition. Better
                 ; start too strict. FIXME: breaks on lines with only
                 ; underscores which should empty lines.
                 ((and inunderscoreindent (and (not (equal? #\space next-char)) (not (equal? #\newline next-char))))
                   (throw 'wisp-syntax-error "initial underscores without following whitespace at beginning of the line after" (last indent-and-symbols)))
                 ((equal? #\newline next-char)
                   (read-char port ); remove the newline
                   ; The following two lines would break the REPL by requiring one char too many.
                   ; if : and (equal? #\newline next-char) : equal? #\return : peek-char port
                   ;      read-char port ; remove a full \n\r. Damn special cases...
                   (let* ; distinguish pure whitespace lines and lines
                        ; with comment by giving the former zero
                        ; indent. Lines with a comment at zero indent
                        ; get indent -1 for the same reason - meaning
                        ; not actually empty.
                     (
                       (indent 
                         (cond 
                           (incomment 
                             (if (= 0 currentindent ); specialcase
                               -1
                               currentindent ))
                           ((not (null? currentsymbols )); pure whitespace
                             currentindent)
                           (else
                             0)))
                       (parsedline (append (list indent) currentsymbols))
                       (emptylines 
                         (if (not (line-empty? parsedline))
                            0 
                            (1+ emptylines))))
                     (when (not (= 0 (length parsedline)))
                         ; set the source properties to parsedline so we can try to add them later.
                         (set-source-property! parsedline 'filename (port-filename port))
                         (set-source-property! parsedline 'line (port-line port)))
                     ; TODO: If the line is empty. Either do it here and do not add it, just
                     ; increment the empty line counter, or strip it later. Replace indent
                     ; -1 by indent 0 afterwards.
                     (loop
                       (append indent-and-symbols (list parsedline))
                       #t ; inindent
                       (if (<= 2 emptylines)
                         #f ; chunk ends here
                         (equal? #\_ (peek-char port ))); are we in underscore indent?
                       #f ; incomment
                       0
                       '()
                       emptylines)))
                 ((equal? #t incomment)
                   (read-char port ); remove one comment character
                   (loop 
                     indent-and-symbols
                     #f ; inindent 
                     #f ; inunderscoreindent 
                     #t ; incomment
                     currentindent
                     currentsymbols
                     emptylines))
                 ((or (equal? #\space next-char) (equal? #\tab next-char) (equal? #\return next-char) ); remove whitespace when not in indent
                   (read-char port ); remove char
                   (loop 
                     indent-and-symbols
                     #f ; inindent
                     #f ; inunderscoreindent
                     #f ; incomment
                     currentindent
                     currentsymbols
                     emptylines))
                          ; | cludge to appease the former wisp parser
                          ; | which had a problem with the literal comment
                          ; v char.
                 ((equal? (string-ref ";" 0) next-char)
                   (loop 
                     indent-and-symbols
                     #f ; inindent 
                     #f ; inunderscoreindent 
                     #t ; incomment
                     currentindent
                     currentsymbols
                     emptylines))
                 (else ; use the reader
                   (loop 
                     indent-and-symbols
                     #f ; inindent
                     #f ; inunderscoreindent
                     #f ; incomment
                     currentindent
                     ; this also takes care of the hashbang and leading comments.
                     ; TODO: If used from Guile, activate curly infix via read-options.
                     (append currentsymbols (list (wisp-read port)))
                     emptylines))))))))


(define (line-code-replace-inline-colons line)
         "Replace inline colons by opening parens which close at the end of the line"
         ; format #t "replace inline colons for line ~A\n" line
         (let loop
           ((processed '())
              (unprocessed line))
           (cond
             ((null? unprocessed)
               ; format #t "inline-colons processed line: ~A\n" processed
               processed)
             ((equal? readcolon (car unprocessed))
               (loop
                 ; FIXME: This should turn unprocessed into a list. 
                 (append processed
                   (list (loop '() (cdr unprocessed))))
                 '()))
             (else
               (loop 
                 (append processed
                   (list (car unprocessed)))
                 (cdr unprocessed))))))

(define (line-replace-inline-colons line)
         (cons 
           (line-indent line)
           (line-code-replace-inline-colons (line-code line))))

(define (line-strip-lone-colon line)
         "A line consisting only of a colon is just a marked indentation level. We need to kill the colon before replacing inline colons."
         (if 
           (equal? 
             (line-code line)
             (list readcolon))
           (list (line-indent line))
           line))

(define (line-finalize line)
       "Process all wisp-specific information in a line and strip it"
       (let
         (
           (l
             (line-code-replace-inline-colons 
               (line-strip-indentation-marker
                 (line-strip-lone-colon
                   (line-strip-continuation line))))))
         (when (not (null? (source-properties line)))
                (catch #t
                  (lambda ()
                    (set-source-properties! l (source-properties line)))
                  (lambda (key . arguments)
                    #f)))
         l))

(define (wisp-add-source-properties-from source target)
       "Copy the source properties from source into the target and return the target."
       (catch #t
           (lambda ()
               (set-source-properties! target (source-properties source)))
           (lambda (key . arguments)
               #f))
       target)

(define (wisp-propagate-source-properties code)
       "Propagate the source properties from the sourrounding list into every part of the code."
       (let loop
         ((processed '())
           (unprocessed code))
         (cond
           ((and (null? processed) (not (pair? unprocessed)) (not (list? unprocessed)))
             unprocessed)
           ((and (pair? unprocessed) (not (list? unprocessed)))
             (cons
               (wisp-propagate-source-properties (car unprocessed))
               (wisp-propagate-source-properties (cdr unprocessed))))
           ((null? unprocessed)
             processed)
           (else
             (let ((line (car unprocessed)))
               (if (null? (source-properties unprocessed))
                   (wisp-add-source-properties-from line unprocessed)
                   (wisp-add-source-properties-from unprocessed line))
               (loop
                 (append processed (list (wisp-propagate-source-properties line)))
                 (cdr unprocessed)))))))

(define (wisp-scheme-indentation-to-parens lines)
         "Add parentheses to lines and remove the indentation markers"
         ; FIXME: Find new algorithm which mostly uses current-line
         ; and the indentation-levels for tracking. The try I have in
         ; here right now is wrong.
         (when 
           (and 
             (not (null? lines))
             (not (line-empty-code? (car lines)))
             (not (= 0 (line-real-indent (car lines ))))); -1 is a line with a comment
           (throw 'wisp-syntax-error 
             (format #f "The first symbol in a chunk must start at zero indentation. Indentation and line: ~A"
               (car lines))))
         (let loop
           ((processed '())
             (unprocessed lines)
             (indentation-levels '(0)))
           (let*
             ( 
               (current-line 
                 (if (<= 1 (length unprocessed))
                      (car unprocessed)
                      (list 0 ))); empty code
               (next-line
                 (if (<= 2 (length unprocessed))
                      (car (cdr unprocessed))
                      (list 0 ))); empty code
               (current-indentation
                      (car indentation-levels))
               (current-line-indentation (line-real-indent current-line)))
             ; format #t "processed: ~A\ncurrent-line: ~A\nnext-line: ~A\nunprocessed: ~A\nindentation-levels: ~A\ncurrent-indentation: ~A\n\n"
             ;     . processed current-line next-line unprocessed indentation-levels current-indentation
             (cond
                 ; the real end: this is reported to the outside world.
               ((and (null? unprocessed) (not (null? indentation-levels)) (null? (cdr indentation-levels)))
                 ; display "done\n"
                 ; reverse the processed lines, because I use cons.
                 processed)
               ; the recursion end-condition
               ((and (null? unprocessed))
                 ; display "last step\n"
                 ; this is the last step. Nothing more to do except
                 ; for rolling up the indentation levels.  return the
                 ; new processed and unprocessed lists: this is a
                 ; side-recursion
                 (values processed unprocessed))
               ((null? indentation-levels)
                 ; display "indentation-levels null\n"
                 (throw 'wisp-programming-error "The indentation-levels are null but the current-line is null: Something killed the indentation-levels."))
               (else ; now we come to the line-comparisons and indentation-counting.
                   (cond
                     ((line-empty-code? current-line)
                       ; display "current-line empty\n"
                       ; We cannot process indentation without
                       ; code. Just switch to the next line. This should
                       ; only happen at the start of the recursion.
                       ; TODO: Somehow preserve the line-numbers.
                       (loop
                         processed
                         (cdr unprocessed)
                         indentation-levels))
                     ((and (line-empty-code? next-line) (<= 2 (length unprocessed )))
                       ; display "next-line empty\n"
                       ; TODO: Somehow preserve the line-numbers.
                       ; take out the next-line from unprocessed.
                       (loop
                         processed
                         (cons current-line
                           (cdr (cdr unprocessed)))
                         indentation-levels))
                     ((> current-indentation current-line-indentation)
                       ; display "current-indent > next-line\n"
                       ; this just steps back one level via the side-recursion.
                       (values processed unprocessed))
                     ((= current-indentation current-line-indentation)
                       ; display "current-indent = next-line\n"
                       (let 
                         ((line (line-finalize current-line))
                           (next-line-indentation (line-real-indent next-line)))
                         (cond
                           ((>= current-line-indentation next-line-indentation)
                             ; simple recursiive step to the next line
                             ; display "current-line-indent >= next-line-indent\n"
                             (loop
                               (append processed 
                                 (if (line-continues? current-line)
                                      line
                                      (wisp-add-source-properties-from line (list line))))
                               (cdr unprocessed ); recursion here
                               indentation-levels))
                           ((< current-line-indentation next-line-indentation)
                             ; display "current-line-indent < next-line-indent\n"
                             ; format #t "line: ~A\n" line
                             ; side-recursion via a sublist
                             (let-values 
                               (
                                 ((sub-processed sub-unprocessed)
                                   (loop
                                     line
                                     (cdr unprocessed ); recursion here
                                     indentation-levels)))
                               ; format #t "side-recursion:\n  sub-processed: ~A\n  processed: ~A\n\n" sub-processed processed
                               (loop
                                 (append processed (list sub-processed))
                                 sub-unprocessed ; simply use the recursion from the sub-recursion
                                 indentation-levels))))))
                     ((< current-indentation current-line-indentation)
                       ; display "current-indent < next-line\n"
                       (loop
                         processed
                         unprocessed
                         (cons ; recursion via the indentation-levels
                           current-line-indentation 
                           indentation-levels)))
                     (else
                       (throw 'wisp-not-implemented 
                             (format #f "Need to implement further line comparison: current: ~A, next: ~A, processed: ~A."
                               current-line next-line processed)))))))))


(define (wisp-scheme-replace-inline-colons lines)
         "Replace inline colons by opening parens which close at the end of the line"
         (let loop
           ((processed '())
             (unprocessed lines))
           (if (null? unprocessed)
                processed
                (loop
                  (append processed (list (line-replace-inline-colons (car unprocessed))))
                  (cdr unprocessed)))))
                  

(define (wisp-scheme-strip-indentation-markers lines)
         "Strip the indentation markers from the beginning of the lines"
         (let loop
           ((processed '())
             (unprocessed lines))
           (if (null? unprocessed)
                processed
                (loop
                  (append processed (cdr (car unprocessed)))
                  (cdr unprocessed)))))

(define (wisp-unescape-underscore-and-colon code)
         "replace \\_ and \\: by _ and :"
         (match code
             ((a ...)
               (map wisp-unescape-underscore-and-colon a))
             ('\_
               '_)
             ('\:
               ':)
             (a
               a)))


(define (wisp-replace-empty-eof code)
         "replace ((#<eof>)) by ()"
         ; FIXME: Actually this is a hack which fixes a bug when the
         ; parser hits files with only hashbang and comments.
         (if (and (not (null? code)) (pair? (car code)) (eof-object? (car (car code))) (null? (cdr code)) (null? (cdr (car code))))
              (list)
              code))


(define (wisp-replace-paren-quotation-repr code)
         "Replace lists starting with a quotation symbol by
         quoted lists."
         (match code
             (('REPR-QUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'quote (map wisp-replace-paren-quotation-repr a)))
             ((a ... 'REPR-QUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd b ); this is the quoted empty list 
                (append
                        (map wisp-replace-paren-quotation-repr a)
                        (list (list 'quote (map wisp-replace-paren-quotation-repr b)))))
             (('REPR-UNQUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'unquote (map wisp-replace-paren-quotation-repr a)))
             ((a ... 'REPR-UNQUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd b )
                (append
                        (map wisp-replace-paren-quotation-repr a)
                        (list (list 'unquote (map wisp-replace-paren-quotation-repr b)))))
             (('REPR-QUASIQUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'quasiquote (map wisp-replace-paren-quotation-repr a)))
             ((a ... 'REPR-QUASIQUOTE-e749c73d-c826-47e2-a798-c16c13cb89dd b ); this is the quoted empty list 
                (append
                        (map wisp-replace-paren-quotation-repr a)
                        (list (list 'quasiquote (map wisp-replace-paren-quotation-repr b)))))
             (('REPR-UNQUOTESPLICING-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'unquote-splicing (map wisp-replace-paren-quotation-repr a)))
             (('REPR-SYNTAX-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'syntax (map wisp-replace-paren-quotation-repr a)))
             (('REPR-UNSYNTAX-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'unsyntax (map wisp-replace-paren-quotation-repr a)))
             (('REPR-QUASISYNTAX-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'quasisyntax (map wisp-replace-paren-quotation-repr a)))
             (('REPR-UNSYNTAXSPLICING-e749c73d-c826-47e2-a798-c16c13cb89dd a ...)
                (list 'unsyntax-splicing (map wisp-replace-paren-quotation-repr a)))
             ((a ...)
               (map wisp-replace-paren-quotation-repr a))
             (a
               a)))

(define (wisp-make-improper code)
         "Turn (a #{.}# b) into the correct (a . b).

read called on a single dot creates a variable named #{.}# (|.|
in r7rs). Due to parsing the indentation before the list
structure is known, the reader cannot create improper lists
when it reads a dot. So we have to take another pass over the
code to recreate the improper lists.

Match is awesome!"
         (let 
           ( 
             (improper
               (match code
                  ((a ... b 'REPR-DOT-e749c73d-c826-47e2-a798-c16c13cb89dd c)
                    (append (map wisp-make-improper a) 
                      (cons (wisp-make-improper b) (wisp-make-improper c))))
                  ((a ...)
                    (map wisp-make-improper a))
                  (a
                    a))))
           (define (syntax-error li msg)
                   (throw 'wisp-syntax-error (format #f "incorrect dot-syntax #{.}# in code: ~A: ~A" msg li)))
           (if #t
            improper
            (let check
             ((tocheck improper))
             (match tocheck
               ; lists with only one member
               (('REPR-DOT-e749c73d-c826-47e2-a798-c16c13cb89dd)
                 (syntax-error tocheck "list with the period as only member"))
               ; list with remaining dot.
               ((a ...)
                 (if (and (member repr-dot a))
                      (syntax-error tocheck "leftover period in list")
                      (map check a)))
               ; simple pair - this and the next do not work when parsed from wisp-scheme itself. Why?
               (('REPR-DOT-e749c73d-c826-47e2-a798-c16c13cb89dd . c)
                 (syntax-error tocheck "dot as first element in already improper pair"))
               ; simple pair, other way round
               ((a . 'REPR-DOT-e749c73d-c826-47e2-a798-c16c13cb89dd)
                 (syntax-error tocheck "dot as last element in already improper pair"))
               ; more complex pairs
               ((? pair? a)
                 (let 
                   ((head (drop-right a 1))
                     (tail (last-pair a)))
                   (cond
                    ((equal? repr-dot (car tail))
                      (syntax-error tocheck "equal? repr-dot : car tail"))
                    ((equal? repr-dot (cdr tail))
                      (syntax-error tocheck "equal? repr-dot : cdr tail"))
                    ((member repr-dot head)
                      (syntax-error tocheck "member repr-dot head"))
                    (else
                      a))))
               (a
                 a))))))

(define (wisp-scheme-read-chunk port)
         "Read and parse one chunk of wisp-code"
         (let (( lines (wisp-scheme-read-chunk-lines port)))
              (wisp-make-improper
                (wisp-replace-empty-eof
                  (wisp-unescape-underscore-and-colon
                    (wisp-replace-paren-quotation-repr
                      (wisp-propagate-source-properties
                        (wisp-scheme-indentation-to-parens lines))))))))

(define (wisp-scheme-read-all port)
         "Read all chunks from the given port"
         (let loop 
           ((tokens '()))
           (cond
             ((eof-object? (peek-char port))
               tokens)
             (else
               (loop
                 (append tokens (wisp-scheme-read-chunk port)))))))

(define (wisp-scheme-read-file path)
         (call-with-input-file path wisp-scheme-read-all))

(define (wisp-scheme-read-file-chunk path)
         (call-with-input-file path wisp-scheme-read-chunk))

(define (wisp-scheme-read-string str)
         (call-with-input-string str wisp-scheme-read-all))

(define (wisp-scheme-read-string-chunk str)
         (call-with-input-string str wisp-scheme-read-chunk))


;;;; Test special syntax
; ;; quote the list
; write
;   wisp-scheme-read-string  "moo
;   foo
;     ' bar
; baz waz"
; newline 
; ;; quote the symbol - in wisp, whitespace after quote is not allowed!
; write
;   wisp-scheme-read-string  "moo
;   foo
;     'bar
; baz waz"
; newline 
; ; ;; quote the list with colon
; write
;   wisp-scheme-read-string  "moo : ' foo
;   foo
;     ' bar bah
; baz waz"
; newline 
; ; ;; syntax the list
; write
;   wisp-scheme-read-string  "moo : #' foo
;   foo
;     #' bar bah
; baz waz"
; newline 
; 
;;;; Test improper lists
;;;; Good cases
; write
;   wisp-scheme-read-string  "foo . bar"
; newline 
; write
;   wisp-scheme-read-string  "foo .
;   . bar"
; newline 
; write
;   wisp-scheme-read-string  "foo
;   . . bar"
; newline 
; write
;   wisp-scheme-read-string  "moo
;   foo
;     . . bar
; baz waz"
; newline 
;;;; Syntax Error cases
; write
;   wisp-scheme-read-string  "foo
;   . . ."
; newline 
; write
;   wisp-scheme-read-string  "moo : . . bar"
; write
;   wisp-scheme-read-string  "foo .
;   . . bar"
; newline 
; write
;   wisp-scheme-read-string  "moo
;   foo
;     . . bar baz
; baz waz"
; newline 
;;;; stranger stuff
; write
;   wisp-scheme-read-string  "foo ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\nfoo : moo \"\n\" \n___ . goo . hoo"
; newline 
; display
;   wisp-scheme-read-string  "  foo ; bar\n  ; nop \n\n; nup\n; nup \n  \n\n\nfoo : moo"
; newline 
; write : wisp-scheme-read-file-chunk "wisp-scheme.w"
; newline 
; call-with-output-file "wisp-guile.scm"
;   lambda : port
;     map 
;        lambda : chunk
;                 write chunk port
;        wisp-scheme-read-file "wisp-guile.w"
; run all chunks in wisp-guile.w as parsed by wisp-scheme.w. Give wisp-guile.w to parse as argument.
; map primitive-eval : wisp-scheme-read-file "wisp-guile.w" ; actually runs wisp-guile.w with the arguments supplied to this script.
; uncomment the previous line, then run the next line in the shell. If 1 and 2 are equal, this parser works!
; guile wisp.scm wisp-scheme.w > wisp-scheme.scm; guile wisp-scheme.scm wisp-guile.w > 1; guile wisp.scm wisp-guile.w > 2; diff 1 2



